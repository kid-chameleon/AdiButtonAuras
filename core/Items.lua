--[[
AdiButtonAuras - Display auras on action buttons.
Copyright 2013-2023 Adirelle (adirelle@gmail.com)
All rights reserved.

This file is part of AdiButtonAuras.

AdiButtonAuras is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

AdiButtonAuras is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with AdiButtonAuras. If not, see <http://www.gnu.org/licenses/>.
--]]

local addonName, addon = ...

local _G = _G
local format = _G.format
local GetTime = _G.GetTime
local gsub = _G.gsub
local ipairs = _G.ipairs
local C_Item = _G.C_Item or {}
local GetItemInfo = _G.GetItemInfo or C_Item.GetItemInfo
local GetItemSpell = _G.GetItemSpell or C_Item.GetItemSpell
local IsHarmfulItem = _G.IsHarmfulItem or C_Item.IsHarmfulItem
local IsHelpfulItem = _G.IsHelpfulItem or C_Item.IsHelpfulItem
local select = _G.select
local setmetatable = _G.setmetatable
local tonumber = _G.tonumber
local tinsert = _G.tinsert
local pairs = _G.pairs
local type = _G.type

local LibItemBuffs, LIBVer = addon.GetLib('LibItemBuffs-1.0')

local BuildKey = addon.BuildKey
local BuildDesc = addon.BuildDesc
local FindWeaponEnchant = addon.FindWeaponEnchant
local L = addon.L

local CONSUMABLE = _G.Enum.ItemClass.Consumable or 0

local descriptions = {}

local function GetItemTargetFilterAndHighlight(itemId, itemClassId)
	if IsHarmfulItem(itemId) then
		return "enemy", "HARMFUL PLAYER", "bad"
	else
		return IsHelpfulItem(itemId) and itemClassId ~= CONSUMABLE and "ally" or "player", "HELPFUL PLAYER", "good"
	end
end

local function BuildBuffIdHandler(key, token, filter, highlight, buffId)
	local GetAura = addon.GetAuraGetter(filter)
	return function(units, model)
		if not addon.db.profile.rules[key] then return end
		local found, count, expiration = GetAura(units[token], buffId)
		if found then
			model.highlight, model.count, model.expiration = highlight, count, expiration
			return true
		end
	end
end

-- Sharpening stones, weightstones, oils, poisons and lures: the item puts a temporary
-- enchant on a weapon instead of an aura on a unit.
local function BuildWeaponEnchantHandler(key, enchantId)
	return function(_, model)
		if not addon.db.profile.rules[key] then return end
		local timeLeft, charges = FindWeaponEnchant(enchantId)
		if timeLeft then
			model.highlight, model.count, model.expiration = "good", charges or 0, GetTime() + timeLeft / 1000
			return true
		end
	end
end

local function GetItemWeaponEnchants(itemId)
	if LibItemBuffs.GetItemWeaponEnchants then
		local first = LibItemBuffs:GetItemWeaponEnchants(itemId)
		if first then
			return { LibItemBuffs:GetItemWeaponEnchants(itemId) }
		end
	end
end

local function BuildItemRule(itemId, buffName, enchants, ...)
	if not buffName and not enchants and not ... then return false end

	local name, _, _, _, _, _, _, _, _, _, _, itemClassId = GetItemInfo(itemId)

	local token, filter, highlight = GetItemTargetFilterAndHighlight(itemId, itemClassId)

	local rule = {
		units = { [token] = true },
		events = { UNIT_AURA = true },
		handlers = {},
		keys = {},
		name = name,
	}

	if enchants then
		rule.units = { player = true }
		rule.events = { WEAPON_ENCHANT_CHANGED = true, WEAPON_SLOT_CHANGED = true }
		for _, enchantId in ipairs(enchants) do
			local key = BuildKey('item', itemId, 'WeaponEnchant', enchantId)
			descriptions[key] = gsub(L['Show the duration of @NAME'], "@NAME", name or ("item:" .. itemId))
				.. format(" [LIB-%d-%s]", LIBVer, LibItemBuffs:GetDatabaseVersion())
			tinsert(rule.keys, key)
			tinsert(rule.handlers, BuildWeaponEnchantHandler(key, enchantId))
		end
	elseif ... then
		for i = 1, select('#', ...) do
			local buffId = select(i, ...)
			local key = BuildKey('item', itemId, token, filter, highlight, buffId)
			local desc = BuildDesc(filter, highlight, token, buffId) .. format(" [LIB-%d-%s]", LIBVer, LibItemBuffs:GetDatabaseVersion())
			descriptions[key] = desc
			tinsert(rule.keys, key)
			tinsert(rule.handlers, BuildBuffIdHandler(key, token, filter, highlight, buffId))
		end
	elseif buffName then
		local key = BuildKey('item', itemId, token, filter, highlight, buffName)
		local desc = BuildDesc(filter, highlight, token, buffName)
		descriptions[key] = desc
		tinsert(rule.keys, key)
		tinsert(rule.handlers, BuildBuffIdHandler(key, token, filter, highlight, buffName))
	end

	return rule
end

local items = addon.Memoize(function(key)
	local id = tonumber(key:match('^item:(%d+)$'))
	return id and BuildItemRule(id, GetItemSpell(id), GetItemWeaponEnchants(id), LibItemBuffs:GetItemBuffs(id)) or false
end)

local function DeepCopy(t)
	if type(t) ~= "table" then return t end
	local n = {}
	for k,v in pairs(t) do
		if type(v) == "table" then
			n[k] = DeepCopy(v)
		else
			n[k] = v
		end
	end
	return n
end

setmetatable(addon.rules, { __index = function(self, key)
	if key == nil then return end
	local rule = items[key] and DeepCopy(items[key]) or false
	self[key] = rule
	return rule
end })
setmetatable(addon.descriptions, {  __index = descriptions })
