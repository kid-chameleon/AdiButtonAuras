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
if not addon.isFlavor('vanilla') then return end

AdiButtonAuras:RegisterRules(function()
	Debug('Rules', 'Adding vanilla rogue rules')

	-- ShowTempWeaponEnchant listens for WEAPON_ENCHANT_CHANGED, which does
	-- not exist on the vanilla client; use UNIT_INVENTORY_CHANGED instead.
	local function ShowWeaponPoison(spellId, enchantId)
		return Configure {
			BuildKey('WeaponEnchant', enchantId, 'good'),
			L['Show the duration of @NAME'],
			spellId,
			'player',
			'UNIT_INVENTORY_CHANGED',
			function(_, model)
				local hasMainHandEnchant, mainHandExpiration, mainHandCharges, mainHandEnchantId,
					hasOffHandEnchant, offHandExpiration, offHandCharges, offHandEnchantId = GetWeaponEnchantInfo()

				if hasMainHandEnchant and mainHandEnchantId == enchantId then
					model.expiration = GetTime() + mainHandExpiration / 1000
					model.count = mainHandCharges or 0
					model.highlight = 'good'

					return true
				end

				if hasOffHandEnchant and offHandEnchantId == enchantId then
					model.expiration = GetTime() + offHandExpiration / 1000
					model.count = offHandCharges or 0
					model.highlight = 'good'

					return true
				end
			end,
		}
	end

	local poisons = { -- { apply spell, enchant id }
		{ 2823, 7 }, -- Deadly Poison
		{ 8679, 323 }, -- Instant Poison
		{ 13219, 703 }, -- Wound Poison
		{ 3408, 22 }, -- Crippling Poison
		{ 5761, 35 }, -- Mind-numbing Poison
	}

	local rules = {
		ImportPlayerSpells { 'ROGUE' },

		ShowReactive {
			14251, -- Riposte
			L['Flash when @NAME is usable after you parry.'],
		},

		ShowPower {
			{
				408, -- Begin Kidney Shot
				8643, -- End Kidney Shot
				1943, -- Begin Rupture
				8639,
				8640,
				11273,
				11274,
				11275, -- End Rupture
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
				31016, -- End Eviscerate
				8647, -- Begin Expose Armor
				8649,
				8650,
				11197,
				11198, -- End Expose Armor
				400012, -- Blade Dance (SoD rune)
				399963, -- Envenom (SoD rune)
			},
			'ComboPoints',
		},
	}

	for _, poison in ipairs(poisons) do
		tinsert(rules, ShowWeaponPoison(poison[1], poison[2]))
	end

	return rules
end)
