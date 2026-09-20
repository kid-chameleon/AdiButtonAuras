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

if not addon.hasSecrets then return end

local _G = _G
local CreateColor = _G.CreateColor
local CreateFrame = _G.CreateFrame
local Enum = _G.Enum
local ipairs = _G.ipairs
local next = _G.next
local pairs = _G.pairs
local pcall = _G.pcall
local tconcat = _G.table.concat
local tinsert = _G.tinsert
local tostring = _G.tostring
local unpack = _G.unpack
local wipe = _G.wipe

local LSM = addon.GetLib('LibSharedMedia-3.0')

local overlayPrototype = addon.overlayPrototype
local auraHandlerInfo = addon.auraHandlerInfo
local timerlessHandlers = addon.timerlessHandlers
local stackingAuras = addon.stackingAuras or {}

local Debug = function(...) addon.Debug('SecretAuras', ...) end

local FONT_FLAG = "OUTLINE"

-- Highlights the engine can render for us.
-- "hint" (missing aura) needs the inverse of presence and stays with the legacy handlers.
-- It's not supported with secret values.
local SUPPORTED_HIGHLIGHTS = {
	good = true,
	bad = true,
	dispel = true,
	flash = true,
	darken = true,
	lighten = true,
	stacks = true,
}

-- Highlights the "Show flash instead" option turns into a flash, as UpdateState does for the regular display.
local FLASHABLE_HIGHLIGHTS = {
	good = true,
	bad = true,
	dispel = true,
}

local DISPEL_TYPES = { "Curse", "Disease", "Magic", "Poison" }

local function BaseFilter(filter)
	return filter:match('HARMFUL') and 'HARMFUL' or 'HELPFUL'
end

local function IsPlayerFilter(filter)
	return filter:match('PLAYER') and true or nil
end

local function CopySet(set)
	local copy = {}
	for k in pairs(set) do
		copy[k] = true
	end
	return copy
end

-- Slot frames cannot be changed once created, so every layout is a slot of its own.
local function SlotKey(info, kind, split, compact)
	return info.token .. '/' .. kind .. '/' .. info.filter
		.. (split and '/split' or '') .. (compact and '/compact' or '')
end

-- A timer next to a stack count uses the compact format, like the regular display.
-- The count itself is secret, so we use a pre-generated list.
local function HasStackingAura(info)
	if info.buffs then
		for id in pairs(info.buffs) do
			if stackingAuras[id] then
				return true
			end
		end
	end
	return false
end

-- The aura info of a handler the engine can render.
local function GetSlotInfo(handler)
	local info = auraHandlerInfo[handler]
	if info and SUPPORTED_HIGHLIGHTS[info.highlight] and info.token ~= 'group' then
		return info
	end
end

-- Everything a slot frame bakes in when it is created.
local STYLE_PREFS = { "fontName", "fontSize", "highlightTexture", "textPosition", "textXOffset", "textYOffset" }
local STYLE_COLORS = { "good", "bad", "Enrage", "countdownHigh", unpack(DISPEL_TYPES) }

local function SlotStyle(overlay)
	local prefs = addon.db.profile
	local _, _, durationVersion = addon.GetDurationStyle()
	local parts = { durationVersion, overlay:GetSize() }
	for _, name in ipairs(STYLE_PREFS) do
		tinsert(parts, tostring(prefs[name]))
	end
	for _, name in ipairs(STYLE_COLORS) do
		tinsert(parts, tconcat(prefs.colors[name], ','))
	end
	return tconcat(parts, '/')
end

------------------------------------------------------------------------------
-- Slot frame initializer.
-- Runs once per slot frame, before the engine locks it down.
------------------------------------------------------------------------------

local function MakeSlotInitializer(overlay, kind, split, compact)
	local prefs = addon.db.profile
	local width, height = overlay:GetSize()
	local fontFile, fontSize = LSM:Fetch(LSM.MediaType.FONT, prefs.fontName), prefs.fontSize
	local highlightTexture = LSM:Fetch(addon.HIGHLIGHT_MEDIATYPE, prefs.highlightTexture)
	local textPosition, xOffset, yOffset = prefs.textPosition, prefs.textXOffset, prefs.textYOffset
	local colors = prefs.colors

	local function CreateText(frame)
		local text = frame:CreateFontString(nil, "OVERLAY")
		text:SetFont(fontFile, fontSize, FONT_FLAG)
		text:SetJustifyV("BOTTOM")
		text:SetTextColor(unpack(colors.countdownHigh))
		return text
	end

	-- Same countdown format and colors as the regular timer, rendered engine-side.
	local formatter, colorCurve = addon.GetDurationStyle(split or compact)
	local durationOptions = {
		textFormatter = formatter,
		textColor = { curve = colorCurve, property = Enum.DurationTextBindingProperty.RemainingDuration },
	}

	return function(frame)
		frame:SetSize(width, height)
		frame:SetPoint("CENTER", frame:GetParent(), "CENTER", 0, 0)

		if kind == "good" or kind == "bad" or kind == "flash" then
			local highlight = frame:CreateTexture(nil, "BACKGROUND")
			highlight:SetAllPoints(frame)
			highlight:SetTexture(highlightTexture)
			highlight:SetVertexColor(unpack(colors[kind == "flash" and "good" or kind], 1, 4))
			if kind == "flash" then
				local pulse = highlight:CreateAnimationGroup()
				pulse:SetLooping("BOUNCE")
				local alpha = pulse:CreateAnimation("Alpha")
				alpha:SetFromAlpha(1)
				alpha:SetToAlpha(0.2)
				alpha:SetDuration(0.4)
				frame:AddAuraShownAnimation(pulse)
			end
		elseif kind == "dispel" then
			local highlight = frame:CreateTexture(nil, "BACKGROUND")
			highlight:SetAllPoints(frame)
			highlight:SetTexture(highlightTexture)
			local colorMap = {}
			for _, dispelType in ipairs(DISPEL_TYPES) do
				local color = colors[dispelType]
				colorMap[dispelType] = CreateColor(color[1], color[2], color[3])
			end
			local enrage = colors.Enrage
			colorMap.None = CreateColor(enrage[1], enrage[2], enrage[3])
			frame:AddDispelTypeTexture(highlight, {
				style = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,
				showWhenHarmful = true,
				showWhenHelpful = true,
				showWithoutDispelType = true,
				customDispelColorMap = colorMap,
			})
		elseif kind == "darken" or kind == "lighten" then
			local shade = frame:CreateTexture(nil, "BACKGROUND")
			shade:SetAllPoints(frame)
			shade:SetColorTexture(0.4, 0.4, 0.4, 1)
			shade:SetBlendMode(kind == "darken" and "MOD" or "ADD")
		end

		local count = CreateText(frame)
		if kind == "stacks" then
			-- a count on its own sits in the middle, like the regular display
			count:SetPoint(textPosition .. "LEFT", xOffset, yOffset)
			count:SetPoint(textPosition .. "RIGHT", -xOffset, yOffset)
			count:SetJustifyH("CENTER")
			frame:SetApplicationCount(count)
			return
		end

		count:SetPoint(textPosition .. "LEFT", xOffset, yOffset)
		count:SetPoint(textPosition .. "RIGHT", -xOffset, yOffset)
		count:SetJustifyH("RIGHT")

		local timer = CreateText(frame)
		timer:SetPoint(textPosition .. "LEFT", xOffset, yOffset)
		timer:SetPoint(textPosition .. "RIGHT", -xOffset, yOffset)
		if split then
			-- overlay timer on the left, then ours, then the count if any
			timer:SetJustifyH(compact and "CENTER" or "RIGHT")
		else
			timer:SetJustifyH(compact and "LEFT" or "CENTER")
		end

		frame:SetApplicationCount(count)
		frame:SetDurationText(timer, durationOptions)
	end
end

------------------------------------------------------------------------------
-- Per-overlay containers and slots
------------------------------------------------------------------------------

function overlayPrototype:GetSecretContainer(token)
	local containers = self.secretContainers
	if not containers then
		containers = {}
		self.secretContainers = containers
	end
	local container = containers[token]
	if not container then
		local ok, result = pcall(CreateFrame, "AuraContainer", nil, self, "CustomAuraContainerTemplate")
		if not ok then
			self:Debug('SecretAuras: container creation failed', token, tostring(result))
			return nil
		end
		container = result
		container:SetPoint("CENTER", self, "CENTER", 0, 0)
		container:SetSize(self:GetSize())
		container:SetFrameLevel(self:GetFrameLevel() + 1)
		container:Hide()
		containers[token] = container
		self:Debug('SecretAuras: container created for', token)
	end
	return container
end

-- Rebuild the aura slots from the current rule configuration.
function overlayPrototype:ConfigureSecretAuras(force)
	local conf = self.conf
	local handlers = conf and conf.handlers
	local promote = conf and addon.db.profile.flashPromotion[self.spellId] or false
	if
		not force and self.secretConf == conf and self.secretSource == handlers
		and self.secretHandlers == self.handlers and self.secretPromote == promote
	then
		return
	end
	self.secretConf, self.secretSource, self.secretPromote, self.secretRetry = conf, handlers, promote, false
	self.secretStyle = self.secretStyle or SlotStyle(self)

	local desired = self.secretDesired
	if not desired then
		desired = {}
		self.secretDesired = desired
	end
	for _, entry in pairs(desired) do
		entry.active = false
		wipe(entry.spells)
		wipe(entry.dispel)
	end

	-- A handler that stays with the overlay may show a timer of its own.
	local split = false
	if conf and handlers then
		for _, handler in ipairs(handlers) do
			if not GetSlotInfo(handler) and not timerlessHandlers[handler] then
				split = true
				break
			end
		end
	end

	local slotKeys = {}
	if conf and handlers then
		for _, handler in ipairs(handlers) do
			local info = GetSlotInfo(handler)
			if info then
				local kind = promote and FLASHABLE_HIGHLIGHTS[info.highlight] and 'flash' or info.highlight
				local compact = HasStackingAura(info)
				local key = SlotKey(info, kind, split, compact)
				local entry = desired[key]
				slotKeys[handler] = key
				if not entry then
					entry = {
						token = info.token, kind = kind, filter = info.filter,
						split = split, compact = compact,
						spells = {}, dispel = {},
					}
					desired[key] = entry
				end
				entry.active = true
				if info.buffs then
					for id in pairs(info.buffs) do
						entry.spells[id] = true
					end
				end
				if info.dispel then
					for dispelType in pairs(info.dispel) do
						-- the engine names the "no dispel type" case with an empty string
						entry.dispel[dispelType == 'Enrage' and '' or dispelType] = true
					end
				end
			end
		end
	end

	for key, entry in pairs(desired) do
		if not self:ApplySecretSlot(key, entry) then
			-- tried again once restrictions lift
			self.secretRetry = true
		end
	end

	-- A handler stays with the overlay until the engine has a slot for it.
	local slots = self.secretSlots
	local legacy, engine, hasTimerSlot
	if conf and handlers then
		for _, handler in ipairs(handlers) do
			local key = slotKeys[handler]
			if key and slots and slots[key] then
				engine = engine or {}
				tinsert(engine, handler)
				hasTimerSlot = hasTimerSlot or desired[key].kind ~= 'stacks'
			else
				legacy = legacy or {}
				tinsert(legacy, handler)
			end
		end
	end
	self.handlers, self.engineHandlers = legacy, engine
	self.secretHandlers = legacy
	self.splitTimers = split and hasTimerSlot or false
	self:LayoutTexts()

	self:SyncSecretUnits()
end

function overlayPrototype:ApplySecretSlot(key, entry)
	local slots = self.secretSlots
	if not slots then
		slots = {}
		self.secretSlots = slots
	end
	local container = self:GetSecretContainer(entry.token)

	if not entry.active then
		if slots[key] then
			container:SetAuraSlotEnabled(key, false)
		end
		return true
	end
	if not container then
		return false
	end

	local candidateFilters = {
		includeSpellIDs = next(entry.spells) and CopySet(entry.spells) or nil,
		includeDispelTypes = next(entry.dispel) and CopySet(entry.dispel) or nil,
		isFromPlayerOrPlayerPet = IsPlayerFilter(entry.filter),
	}

	if slots[key] then
		container:SetAuraSlotCandidateFilters(key, candidateFilters)
		container:SetAuraSlotEnabled(key, true)
		return true
	end

	local ok, err = pcall(container.AddAuraSlot, container, key, BaseFilter(entry.filter), {
		candidateFilters = candidateFilters,
		initializeFrame = MakeSlotInitializer(self, entry.kind, entry.split, entry.compact),
	})
	if ok then
		slots[key] = true
		self:Debug('SecretAuras: slot added', key)
	else
		self:Debug('SecretAuras: AddAuraSlot failed', key, tostring(err))
	end
	return ok
end

-- Bind each container to the unit its token currently resolves to.
function overlayPrototype:SyncSecretUnits()
	local containers, desired = self.secretContainers, self.secretDesired
	if not containers or not desired then return end

	for token, container in pairs(containers) do
		local unit = self.conf and self.unitMap[token]
		local active = false
		if unit and unit ~= '' then
			for _, entry in pairs(desired) do
				if entry.active and entry.token == token then
					active = true
					break
				end
			end
		end
		if active then
			container:SetUnit(unit)
			-- the same token may now point at another unit (target switch)
			container:UpdateAllAuras()
			container:Show()
		else
			container:Hide()
		end
	end
end

function overlayPrototype:ResetSecretAuras()
	if not self.secretContainers or self.secretStyle == SlotStyle(self) then return end
	for _, container in pairs(self.secretContainers) do
		container:Hide()
	end
	self.secretContainers, self.secretSlots, self.secretDesired = nil, nil, nil
	self.secretConf, self.secretSource, self.secretStyle = false, false, nil
	self:ConfigureSecretAuras()
end

------------------------------------------------------------------------------
-- Hooks into the overlay lifecycle
------------------------------------------------------------------------------

local Orig_SetAction = overlayPrototype.SetAction
function overlayPrototype:SetAction(...)
	local result = Orig_SetAction(self, ...)
	self:ConfigureSecretAuras()
	if self.conf then
		self:RegisterEvent('ADDON_RESTRICTION_STATE_CHANGED')
	end
	return result
end

local Orig_UpdateGUID = overlayPrototype.UpdateGUID
function overlayPrototype:UpdateGUID(...)
	local result = Orig_UpdateGUID(self, ...)
	if self.secretContainers then
		self:SyncSecretUnits()
	end
	return result
end

local Orig_UpdateDynamicUnits = overlayPrototype.UpdateDynamicUnits
function overlayPrototype:UpdateDynamicUnits(...)
	local result = Orig_UpdateDynamicUnits(self, ...)
	if self.secretContainers then
		self:SyncSecretUnits()
	end
	return result
end

local Orig_ApplySkin = overlayPrototype.ApplySkin
function overlayPrototype:ApplySkin(...)
	Orig_ApplySkin(self, ...)
	self:ResetSecretAuras()
end

local Orig_OnConfigChanged = overlayPrototype.OnConfigChanged
function overlayPrototype:OnConfigChanged(...)
	self:ResetSecretAuras()
	return Orig_OnConfigChanged(self, ...)
end

-- Legacy handlers lose aura data when restrictions start and see it again once they lift.
function overlayPrototype:ADDON_RESTRICTION_STATE_CHANGED(event, _, state)
	if state == Enum.AddOnRestrictionState.Inactive and self.secretRetry then
		self:ConfigureSecretAuras(true)
	end
	return self:ScheduleUpdate(event)
end
