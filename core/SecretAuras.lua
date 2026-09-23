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
local C_CurveUtil = _G.C_CurveUtil
local C_Timer_After = _G.C_Timer.After
local GetSpellAuraSecrecy = _G.C_Secrets.GetSpellAuraSecrecy
local floor = _G.floor
local format = _G.format
local Enum = _G.Enum
local ipairs = _G.ipairs
local next = _G.next
local pairs = _G.pairs
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
local AurasAreSecret = addon.AuraTools.AurasAreSecret

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

-- With "Show missing" set to the border, the border means the aura is missing: UpdateState clears
-- model.highlight while the aura is there. These slots do the same and keep only the timer and count.
local BORDERLESS_KIND = 'plain'
local HIDEABLE_HIGHLIGHTS = {
	good = true,
	bad = true,
	dispel = true,
	darken = true,
	lighten = true,
}

-- "Show missing" with a threshold: the engine cannot tell us the aura runs out, but it can fade a timer
-- text in below a remaining duration, and that text can be a texture. These slots draw the alert that way.
local EXPIRING_KIND = 'expiring'
-- the steady state of LibButtonGlow's flash
local GLOW_TEXTURE = [[Interface\SpellActivationOverlay\IconAlert]]
local GLOW_FORMAT = "|T%s:%d:%d:0:0:256:512:2:130:142:270:%d:%d:%d|t"
local BORDER_FORMAT = "|T%s:%d:%d:0:0:64:64:0:64:0:64:%d:%d:%d|t"

local DISPEL_TYPES = { "Curse", "Disease", "Magic", "Poison" }

local function BaseFilter(filter)
	return filter:match('HARMFUL') and 'HARMFUL' or 'HELPFUL'
end

local function SlotFilter(filter)
	return BaseFilter(filter) .. (filter:match('PLAYER') and '|PLAYER' or '')
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
		.. (info.combatOnly and '/combat' or '')
end

-- Slots that stand in for a handler that goes blind in combat.
local COMBAT_SUFFIX = '/combat'

local function ContainerKey(info)
	return info.token .. (info.combatOnly and COMBAT_SUFFIX or '')
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

-- The engine only matches spell ids for buffs on units we can assist and debuffs on the others, and rejects
-- every aura of a slot that asks otherwise. Auras that are never secret are exempt.
local FRIENDLY_TOKENS = { player = true, pet = true, ally = true }

local function CanMatchSpells(info)
	local harmful = BaseFilter(info.filter) == 'HARMFUL'
	local refused = (harmful and FRIENDLY_TOKENS[info.token]) or (not harmful and info.token == 'enemy')
	if not refused then
		-- other tokens are plain units, whose side is not known in advance
		return true
	end
	for id in pairs(info.buffs) do
		if GetSpellAuraSecrecy(id) ~= Enum.SecrecyLevel.NeverSecret then
			return false
		end
	end
	return true
end

-- The aura info of a handler the engine can render, and whether its spell ids can be used.
local function GetSlotInfo(handler)
	local info = auraHandlerInfo[handler]
	if not info or not SUPPORTED_HIGHLIGHTS[info.highlight] or info.token == 'group' then
		return
	end
	if not info.buffs or CanMatchSpells(info) then
		return info, true
	end
	if info.combatOnly and IsPlayerFilter(info.filter) then
		return info, false
	end
end

-- Everything a slot frame bakes in when it is created.
local STYLE_PREFS = { "fontName", "fontSize", "highlightTexture", "textPosition", "textXOffset", "textYOffset" }
local STYLE_COLORS = { "good", "bad", "expiring", "Enrage", "countdownHigh", unpack(DISPEL_TYPES) }

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

local function MakeSlotInitializer(overlay, entry)
	local kind, split, compact, standIn, swapped = entry.kind, entry.split, entry.compact, entry.standIn, entry.swapped
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
	local formatter, colorCurve = addon.GetDurationStyle(split or compact or standIn or swapped)
	local durationOptions = {
		textFormatter = formatter,
		textColor = { curve = colorCurve, property = Enum.DurationTextBindingProperty.RemainingDuration },
	}

	if kind == EXPIRING_KIND then
		-- invisible until the aura has less than the threshold left
		local r, g, b, a = unpack(colors.expiring, 1, 4)
		local red, green, blue = floor(r * 255 + 0.5), floor(g * 255 + 0.5), floor(b * 255 + 0.5)
		local alert
		if entry.alert == 'flash' then
			-- the glow keeps its full strength, like the flash it stands for
			a = 1
			alert = format(
				GLOW_FORMAT, GLOW_TEXTURE, floor(height * 1.4 + 0.5), floor(width * 1.4 + 0.5), red, green, blue
			)
		else
			alert = format(BORDER_FORMAT, highlightTexture, floor(height + 0.5), floor(width + 0.5), red, green, blue)
		end
		local curve = C_CurveUtil.CreateColorCurve()
		curve:SetType(Enum.LuaCurveType.Step)
		curve:AddPoint(0, CreateColor(r, g, b, a or 1))
		curve:AddPoint(entry.threshold, CreateColor(r, g, b, 0))

		return function(frame)
			frame:SetSize(width, height)
			frame:SetPoint("CENTER", frame:GetParent(), "CENTER", 0, 0)
			local text = frame:CreateFontString(nil, "BACKGROUND")
			text:SetFont(fontFile, fontSize, FONT_FLAG)
			text:SetPoint("CENTER")
			frame:SetDurationText(text, {
				textFormat = { formatString = alert, components = {} },
				textColor = { curve = curve, property = Enum.DurationTextBindingProperty.RemainingDuration },
			})
		end
	end

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
		if standIn then
			-- where the timer of the overlay would be
			timer:SetJustifyH("RIGHT")
		elseif swapped then
			timer:SetJustifyH("LEFT")
		elseif split then
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
		container = CreateFrame("AuraContainer", nil, self, "CustomAuraContainerTemplate")
		container:SetPoint("CENTER", self, "CENTER", 0, 0)
		container:SetSize(self:GetSize())
		-- a stand-in draws over the regular slots, which takes over in combat.
		container:SetFrameLevel(self:GetFrameLevel() + (token:find(COMBAT_SUFFIX, 1, true) and 2 or 1))
		container:Hide()
		containers[token] = container
		self:Debug('SecretAuras: container created for', token)
	end
	return container
end

-- Rebuild the aura slots from the current rule configuration.
function overlayPrototype:ConfigureSecretAuras()
	local conf = self.conf
	local handlers = conf and conf.handlers
	local promote = conf and addon.db.profile.flashPromotion[self.spellId] or false
	local missing = conf and addon.db.profile.missing[self.spellId] or 'none'
	local borderless = missing == 'highlight'
	local threshold = missing ~= 'none' and missing ~= 'hint' and addon.db.profile.missingThreshold[self.spellId] or 0
	local alert = missing == 'flash' and 'flash' or 'border'
	if
		self.secretConf == conf and self.secretSource == handlers
		and self.secretHandlers == self.handlers
		and self.secretPromote == promote and self.secretBorderless == borderless
		and self.secretThreshold == threshold and self.secretAlert == alert
	then
		return
	end
	self.secretConf, self.secretSource = conf, handlers
	self.secretPromote, self.secretBorderless = promote, borderless
	self.secretThreshold, self.secretAlert = threshold, alert
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
	local split, hasRegularTimer, hasStandIn = false, false, false
	if conf and handlers then
		for _, handler in ipairs(handlers) do
			local info = GetSlotInfo(handler)
			if not info then
				split = split or not timerlessHandlers[handler]
			elseif info.combatOnly then
				hasStandIn = true
			elseif info.highlight ~= 'stacks' then
				hasRegularTimer = true
			end
		end
	end
	local swap = hasStandIn and hasRegularTimer

	local slotKeys, expiringKeys = {}, {}
	if conf and handlers then
		for _, handler in ipairs(handlers) do
			local info, byId = GetSlotInfo(handler)
			if info then
				local kind = info.highlight
				if borderless and HIDEABLE_HIGHLIGHTS[kind] then
					kind = BORDERLESS_KIND
				elseif promote and FLASHABLE_HIGHLIGHTS[kind] then
					kind = 'flash'
				end
				local compact = HasStackingAura(info)
				-- in combat the handler it stands in for shows nothing
				local slotSplit = split and not info.combatOnly
				local standIn = info.combatOnly and hasRegularTimer or false
				local swapped = swap and not info.combatOnly
				local maxDuration = not byId and info.maxDuration or nil
				local key = SlotKey(info, kind, slotSplit, compact) .. (standIn and '/right' or '') .. (swapped and '/left' or '')
					.. (byId and '' or '/anyspell') .. (maxDuration and ('/' .. maxDuration) or '')
				local entry = desired[key]
				slotKeys[handler] = key
				if not entry then
					entry = {
						token = info.token, container = ContainerKey(info), kind = kind, filter = info.filter,
						combatOnly = info.combatOnly, standIn = standIn, swapped = swapped, maxDuration = maxDuration,
						split = slotSplit, compact = compact,
						spells = {}, dispel = {},
					}
					desired[key] = entry
				end
				entry.active = true
				if info.buffs and byId then
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

				if threshold > 0 and kind ~= 'stacks' and not info.combatOnly then
					-- same candidates, drawn only for the last seconds of the aura
					local expiringKey = tconcat({ info.token, EXPIRING_KIND, alert, threshold, info.filter }, '/')
					local expiring = desired[expiringKey]
					if not expiring then
						expiring = {
							token = info.token, container = ContainerKey(info), kind = EXPIRING_KIND, filter = info.filter,
							alert = alert, threshold = threshold,
							spells = {}, dispel = {},
						}
						desired[expiringKey] = expiring
					end
					expiring.active = true
					for id in pairs(entry.spells) do
						expiring.spells[id] = true
					end
					for dispelType in pairs(entry.dispel) do
						expiring.dispel[dispelType] = true
					end
					expiringKeys[expiringKey] = true
				end
			end
		end
	end

	for key, entry in pairs(desired) do
		self:ApplySecretSlot(key, entry)
	end

	-- A handler stays with the overlay until the engine has a slot for it.
	local slots = self.secretSlots
	local legacy, engine, hasTimerSlot, hasCombatOnly
	if conf and handlers then
		for _, handler in ipairs(handlers) do
			local key = slotKeys[handler]
			if key and desired[key].combatOnly then
				hasCombatOnly = true
			elseif key and slots and slots[key] then
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
	self.secretCombatOnly = hasCombatOnly or false

	-- UpdateState leaves the threshold to these slots, in combat or not.
	local engineExpiring = false
	for key in pairs(expiringKeys) do
		engineExpiring = engineExpiring or (slots and slots[key]) or false
	end
	self.engineExpiring = engineExpiring
	self.secretHandlers = legacy
	self.splitTimers = split and hasTimerSlot and (swap and "right" or true) or false
	self:LayoutTexts()

	self:SyncSecretUnits()
end

function overlayPrototype:ApplySecretSlot(key, entry)
	local slots = self.secretSlots
	if not slots then
		slots = {}
		self.secretSlots = slots
	end
	local container = self:GetSecretContainer(entry.container)

	if not entry.active then
		if slots[key] then
			container:SetAuraSlotEnabled(key, false)
		end
		return
	end

	local candidateFilters = {
		includeSpellIDs = next(entry.spells) and CopySet(entry.spells) or nil,
		includeDispelTypes = next(entry.dispel) and CopySet(entry.dispel) or nil,
		maxDuration = entry.maxDuration,
	}

	if slots[key] then
		container:SetAuraSlotCandidateFilters(key, candidateFilters)
		container:SetAuraSlotEnabled(key, true)
		return
	end

	container:AddAuraSlot(key, SlotFilter(entry.filter), {
		candidateFilters = candidateFilters,
		initializeFrame = MakeSlotInitializer(self, entry),
	})
	slots[key] = true
	self:Debug('SecretAuras: slot added', key)
end

-- Bind each container to the unit its token currently resolves to.
function overlayPrototype:SyncSecretUnits()
	local containers, desired = self.secretContainers, self.secretDesired
	if not containers or not desired then return end

	for key, container in pairs(containers) do
		local token, combatOnly = key:match('^([^/]+)(.*)$')
		local unit = self.conf and self.unitMap[token]
		local active = false
		if unit and unit ~= '' and (combatOnly == '' or AurasAreSecret()) then
			for _, entry in pairs(desired) do
				if entry.active and entry.container == key then
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
function overlayPrototype:ADDON_RESTRICTION_STATE_CHANGED(event)
	if self.secretCombatOnly then
		C_Timer_After(0, function() return self:SyncSecretUnits() end)
	end
	return self:ScheduleUpdate(event)
end
