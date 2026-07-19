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

local _, addon = ...

if not addon.isClass('SHAMAN') then return end
if not addon.isFlavor('tbc') then return end

AdiButtonAuras:RegisterRules(function()
	Debug('Rules', 'Adding tbc shaman rules')

	-- Every imbue rank has its own enchant id, hence one rule per rank.
	-- Rockbiter Weapon is no temporary enchant in tbc and cannot be tracked
	-- with GetWeaponEnchantInfo.
	local imbues = { -- { rank spell, enchant id }
		{  8024,    5 }, -- Begin Flametongue Weapon
		{  8027,    4 },
		{  8030,    3 },
		{ 16339,  523 },
		{ 16341, 1665 },
		{ 16342, 1666 },
		{ 25489, 2634 }, -- End Flametongue Weapon
		{  8033,    2 }, -- Begin Frostbrand Weapon
		{  8038,   12 },
		{ 10456,  524 },
		{ 16355, 1667 },
		{ 16356, 1668 },
		{ 25500, 2635 }, -- End Frostbrand Weapon
		{  8232,  283 }, -- Begin Windfury Weapon
		{  8235,  284 },
		{ 10486,  525 },
		{ 16362, 1669 },
		{ 25505, 2636 }, -- End Windfury Weapon
	}

	local rules = {
		ImportPlayerSpells { 'SHAMAN' },

		ShowTotem { 8170, 136019 }, -- Disease Cleansing Totem
		ShowTotem { 2062, 136024 }, -- Earth Elemental Totem
		ShowTotem { 2484, 136102 }, -- Earthbind Totem
		ShowTotem { 2894, 135790 }, -- Fire Elemental Totem
		ShowTotem { { 1535, 8498, 8499, 11314, 11315, 25546, 25547 }, 135824 }, -- Fire Nova Totem
		ShowTotem { { 8184, 10537, 10538, 25563 }, 135832 }, -- Fire Resistance Totem
		ShowTotem { { 8227, 8249, 10526, 16387, 25557 }, 136040 }, -- Flametongue Totem
		ShowTotem { { 8181, 10478, 10479, 25560 }, 135866 }, -- Frost Resistance Totem
		ShowTotem { { 8835, 10627, 25359 }, 136046 }, -- Grace of Air Totem
		ShowTotem { 8177, 136039 }, -- Grounding Totem
		ShowTotem { { 5394, 6375, 6377, 10462, 10463, 25567 }, 135127 }, -- Healing Stream Totem
		ShowTotem { { 8190, 10585, 10586, 10587, 25552 }, 135826 }, -- Magma Totem
		ShowTotem { { 5675, 10495, 10496, 10497, 25570 }, 136053 }, -- Mana Spring Totem
		ShowTotem { 16190, 135861 }, -- Mana Tide Totem (Restoration)
		ShowTotem { { 10595, 10600, 10601, 25574 }, 136061 }, -- Nature Resistance Totem
		ShowTotem { 8166, 136070 }, -- Poison Cleansing Totem
		ShowTotem { { 3599, 6363, 6364, 6365, 10437, 10438, 25533 }, 135825 }, -- Searing Totem
		ShowTotem { 6495, 136082 }, -- Sentry Totem
		ShowTotem { { 5730, 6390, 6391, 6392, 10427, 10428, 25525 }, 136097 }, -- Stoneclaw Totem
		ShowTotem { { 8071, 8154, 8155, 10406, 10407, 10408, 25508, 25509 }, 136098 }, -- Stoneskin Totem
		ShowTotem { { 8075, 8160, 8161, 10442, 25361, 25528 }, 136023 }, -- Strength of Earth Totem
		ShowTotem { 30706, 135829 }, -- Totem of Wrath (Elemental)
		ShowTotem { 25908, 136013 }, -- Tranquil Air Totem
		ShowTotem { 8143, 136108 }, -- Tremor Totem
		ShowTotem { { 8512, 10613, 10614, 25585, 25587 }, 136114 }, -- Windfury Totem
		ShowTotem { { 15107, 15111, 15112, 25577 }, 136022 }, -- Windwall Totem
		ShowTotem { 3738, 136092 }, -- Wrath of Air Totem
	}

	for _, imbue in ipairs(imbues) do
		tinsert(rules, ShowTempWeaponEnchant { imbue[1], imbue[2] })
	end

	return rules
end)
