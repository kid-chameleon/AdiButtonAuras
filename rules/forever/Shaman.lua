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
if not addon.isFlavor('forever') then return end

AdiButtonAuras:RegisterRules(function()
	Debug('Rules', 'Adding forever shaman rules')

	local imbues = { -- { rank spell, enchant id }
		{  8024,    5 }, -- Begin Flametongue Weapon
		{  8027,    4 },
		{  8030,    3 },
		{ 16339,  523 },
		{ 16341, 1665 },
		{ 16342, 1666 }, -- End Flametongue Weapon
		{  8033,    2 }, -- Begin Frostbrand Weapon
		{  8038,   12 },
		{ 10456,  524 },
		{ 16355, 1667 },
		{ 16356, 1668 }, -- End Frostbrand Weapon
		{  8017,   29 }, -- Begin Rockbiter Weapon
		{  8018,    6 },
		{  8019,    1 },
		{ 10399,  503 },
		{ 16314, 1663 },
		{ 16315,  683 },
		{ 16316, 1664 }, -- End Rockbiter Weapon
		{  8232,  283 }, -- Begin Windfury Weapon
		{  8235,  284 },
		{ 10486,  525 },
		{ 16362, 1669 }, -- End Windfury Weapon
	}

	local rules = {
		ImportPlayerSpells { 'SHAMAN' },

		ShowTotem { 8170, 136019, 'water' }, -- Disease Cleansing Totem
		ShowTotem { 2484, 136102, 'earth' }, -- Earthbind Totem
		ShowTotem { { 8184, 10537, 10538 }, 135832, 'water' }, -- Fire Resistance Totem
		ShowTotem { { 8227, 8249, 10526, 16387 }, 136040, 'fire' }, -- Flametongue Totem
		ShowTotem { { 8181, 10478, 10479 }, 135866, 'fire' }, -- Frost Resistance Totem
		ShowTotem { { 8835, 10627, 25359 }, 136046, 'air' }, -- Grace of Air Totem
		ShowTotem { 8177, 136039, 'air' }, -- Grounding Totem
		ShowTotem { { 5394, 6375, 6377, 10462, 10463 }, 135127, 'water' }, -- Healing Stream Totem
		ShowTotem { { 8190, 10585, 10586, 10587 }, 135826, 'fire' }, -- Magma Totem
		ShowTotem { { 5675, 10495, 10496, 10497 }, 136053, 'water' }, -- Mana Spring Totem
		ShowTotem { { 16190, 17354, 17359 }, 135861, 'water' }, -- Mana Tide Totem (Restoration)
		ShowTotem { { 10595, 10600, 10601 }, 136061, 'air' }, -- Nature Resistance Totem
		ShowTotem { 8166, 136070, 'water' }, -- Poison Cleansing Totem
		ShowTotem { { 3599, 6363, 6364, 6365, 10437, 10438 }, 135825, 'fire' }, -- Searing Totem
		ShowTotem { 6495, 136082, 'air' }, -- Sentry Totem
		ShowTotem { { 5730, 6390, 6391, 6392, 10427, 10428 }, 136097, 'earth' }, -- Stoneclaw Totem
		ShowTotem { { 8071, 8154, 8155, 10406, 10407, 10408 }, 136098, 'earth' }, -- Stoneskin Totem
		ShowTotem { { 8075, 8160, 8161, 10442, 25361 }, 136023, 'earth' }, -- Strength of Earth Totem
		ShowTotem { 8143, 136108, 'earth' }, -- Tremor Totem
		ShowTotem { { 8512, 10613, 10614 }, 136114, 'air' }, -- Windfury Totem
		ShowTotem { { 15107, 15111, 15112 }, 136022, 'air' }, -- Windwall Totem
	}

	for _, imbue in ipairs(imbues) do
		tinsert(rules, ShowTempWeaponEnchant { imbue[1], imbue[2] })
	end

	return rules
end)
