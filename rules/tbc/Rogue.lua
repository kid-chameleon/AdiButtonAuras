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

if not addon.isClass('ROGUE') then return end
if not addon.isFlavor('tbc') then return end

AdiButtonAuras:RegisterRules(function()
	Debug('Rules', 'Adding tbc rogue rules')

	local poisons = { -- { apply spell, enchant id }
		{ 2823, 7 }, -- Deadly Poison
		{ 8679, 323 }, -- Instant Poison
		{ 13219, 703 }, -- Wound Poison
		{ 3408, 22 }, -- Crippling Poison
		{ 5761, 35 }, -- Mind-numbing Poison
	}

	local rules = {
		ImportPlayerSpells { 'ROGUE' },

		ShowPower {
			{
				408, -- Begin Kidney Shot
				8643, -- End Kidney Shot
				1943, -- Begin Rupture
				8639,
				8640,
				11273,
				11274,
				11275,
				26867, -- End Rupture
				5171, -- Begin Slice and Dice
				6774, -- End Slice and Dice
				2098, -- Begin Eviscerate
				6760,
				6761,
				6762,
				8623,
				8624,
				11299,
				11300,
				31016,
				26865, -- End Eviscerate
				8647, -- Begin Expose Armor
				8649,
				8650,
				11197,
				11198,
				26866, -- End Expose Armor
				32645, -- Envenom
			},
			'ComboPoints',
		},
	}

	for _, poison in ipairs(poisons) do
		tinsert(rules, ShowTempWeaponEnchant { poison[1], poison[2] })
	end

	return rules
end)
