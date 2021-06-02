--[[
AdiButtonAuras - Display auras on action buttons.
Copyright 2013-2018 Adirelle (adirelle@gmail.com)
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

local _G = _G
local strmatch = _G.strmatch

local function BuildTotemHandler(totem)
	return function(_, model)
		for slot = 1, 4 do
			local found, name, start, duration = GetTotemInfo(slot)
			if found and name and strmatch(name, totem) then
				model.expiration = start + duration
				model.highlight = 'good'
				break
			end
		end
	end
end

local function BuildWeaponEnchantHandler(enchantId)
	return function(_, model)
		local hasMainHandEnchant, mainHandExpiration, _, mainBuffId,
			  hasOffHandEnchant, offHandExpiration, _, offBuffId = GetWeaponEnchantInfo()

		if hasMainHandEnchant and mainBuffId == enchantId then
			model.highlight = 'good'
			model.expiration = GetTime() + mainHandExpiration / 1000
		elseif hasOffHandEnchant and offBuffId == enchantId then
			model.highlight = 'good'
			model.expiration = GetTime() + offHandExpiration / 1000
		end
	end
end

AdiButtonAuras:RegisterRules(function()
	Debug('Adding shaman rules')

	-- All totem ranks
	local earthbindTotem        = {2484}
	local earthElementalTotem   = {2062}
	local diseaseCleansingTotem = {8170}
	local fireElementalTotem    = {2894}
	local fireNovaTotem         = {1535, 8498, 8499, 11314, 11315, 25546, 25547}
	local fireResistanceTotem   = {8184, 10537, 10538, 25563}
	local flametongueTotem      = {8227, 8249, 10526, 16387, 25557}
	local frostResistanceTotem  = {8181, 10478, 10479, 25560}
	local graceOfAirTotem       = {8835, 10627, 25359}
	local groundingTotem        = {8177}
	local healingStreamTotem    = {5394, 6375, 6377, 10462, 10463, 25567}
	local magmaTotem            = {8190, 10585, 10586, 10587, 25552}
	local manaSpringTotem       = {5675, 10495, 10496, 10497, 25570}
	local manaTideTotem         = {16190}
	local natureResistanceTotem = {10595, 10600, 10601, 25574}
	local poisonCleansingTotem  = {8166}
	local searingTotem          = {3599, 6363, 6364, 6365, 10437, 10438, 25533}
	local sentryTotem           = {6495}
	local stoneclawTotem        = {5730, 6390, 6391, 6392, 10427, 10428, 25525}
	local stoneskinTotem        = {8071, 8154, 8155, 10406, 10407, 10408, 25508, 25509}
	local strengthOfEarthTotem  = {8075, 8160, 8161, 10442, 25361, 25528}
	local tranquilAirTotem      = {25908}
	local tremorTotem           = {8143}
	local windfuryTotem         = {8512, 10613, 10614, 25585, 25587}
	local windwallTotem         = {15107, 15111, 15112, 25577}
	local wrathOfAirTotem       = {3738}

	local flametongueWeapon = {
		{8024, 5},
		{8027, 4},
		{8030, 3},
		{16339, 523},
		{16341, 1665},
		{16342, 1666},
	}

	local frostbrandWeapon = {
		{8033, 2},
		{8038, 12},
		{10456, 524},
		{16355, 1667},
		{16356, 1668},
	}

	local rockbiterWeapon = {
		{8017, 29},
		{8018, 6},
		{8019, 1},
		{10399, 503},
		{16314, 1663},
		{16315, 683},
		{16316, 1664},
	}

	local windfuryWeapon = {
		{8232, 283},
		{8235, 284},
		{10486, 525},
		{16362, 1669},
	}

	return {
		ImportPlayerSpells {
			'SHAMAN',
		},

		ShowWeaponEnchantRanks {
			'FlametongueWeapon',
			L['Show the duration of @NAME.'],
			flametongueWeapon,
		},

		ShowWeaponEnchantRanks {
			'FrostbrandWeapon',
			L['Show the duration of @NAME.'],
			frostbrandWeapon,
		},

		ShowWeaponEnchantRanks {
			'RockbiterWeapon',
			L['Show the duration of @NAME.'],
			rockbiterWeapon,
		},

		ShowWeaponEnchantRanks {
			'WindfuryWeapon',
			L['Show the duration of @NAME.'],
			windfuryWeapon,
		},

		Configure {
			'EarthbindTotem',
			L['Show the duration of @NAME.'],
			earthbindTotem,
			'player',
			'PLAYER_TOTEM_UPDATE',
			BuildTotemHandler(GetSpellInfo(earthbindTotem[1])),
		},

		Configure {
			'EarthElementalTotem',
			L['Show the duration of @NAME.'],
			earthElementalTotem,
			'player',
			'PLAYER_TOTEM_UPDATE',
			BuildTotemHandler(GetSpellInfo(earthElementalTotem[1])),
		},

		Configure {
			'DiseaseCleansingTotem',
			L['Show the duration of @NAME.'],
			diseaseCleansingTotem,
			'player',
			'PLAYER_TOTEM_UPDATE',
			BuildTotemHandler(GetSpellInfo(diseaseCleansingTotem[1])),
		},

		Configure {
			'FireElementalTotem',
			L['Show the duration of @NAME.'],
			fireElementalTotem,
			'player',
			'PLAYER_TOTEM_UPDATE',
			BuildTotemHandler(GetSpellInfo(fireElementalTotem[1])),
		},

		Configure {
			'FireNovaTotem',
			L['Show the duration of @NAME.'],
			fireNovaTotem,
			'player',
			'PLAYER_TOTEM_UPDATE',
			BuildTotemHandler(GetSpellInfo(fireNovaTotem[1])),
		},

		Configure {
			'FireResistanceTotem',
			L['Show the duration of @NAME.'],
			fireResistanceTotem,
			'player',
			'PLAYER_TOTEM_UPDATE',
			BuildTotemHandler(GetSpellInfo(fireResistanceTotem[1])),
		},

		Configure {
			'FlametongueTotem',
			L['Show the duration of @NAME.'],
			flametongueTotem,
			'player',
			'PLAYER_TOTEM_UPDATE',
			BuildTotemHandler(GetSpellInfo(flametongueTotem[1])),
		},

		Configure {
			'FrostResistanceTotem',
			L['Show the duration of @NAME.'],
			frostResistanceTotem,
			'player',
			'PLAYER_TOTEM_UPDATE',
			BuildTotemHandler(GetSpellInfo(frostResistanceTotem[1])),
		},

		Configure {
			'GraceOfAirTotem',
			L['Show the duration of @NAME.'],
			graceOfAirTotem,
			'player',
			'PLAYER_TOTEM_UPDATE',
			BuildTotemHandler(GetSpellInfo(graceOfAirTotem[1])),
		},

		Configure {
			'GroundingTotem',
			L['Show the duration of @NAME.'],
			groundingTotem,
			'player',
			'PLAYER_TOTEM_UPDATE',
			BuildTotemHandler(GetSpellInfo(groundingTotem[1])),
		},

		Configure {
			'HealingStreamTotem',
			L['Show the duration of @NAME.'],
			healingStreamTotem,
			'player',
			'PLAYER_TOTEM_UPDATE',
			BuildTotemHandler(GetSpellInfo(healingStreamTotem[1])),
		},

		Configure {
			'MagmaTotem',
			L['Show the duration of @NAME.'],
			magmaTotem,
			'player',
			'PLAYER_TOTEM_UPDATE',
			BuildTotemHandler(GetSpellInfo(magmaTotem[1])),
		},

		Configure {
			'ManaSpringTotem',
			L['Show the duration of @NAME.'],
			manaSpringTotem,
			'player',
			'PLAYER_TOTEM_UPDATE',
			BuildTotemHandler(GetSpellInfo(manaSpringTotem[1])),
		},

		Configure {
			'ManaTideTotem',
			L['Show the duration of @NAME.'],
			manaTideTotem,
			'player',
			'PLAYER_TOTEM_UPDATE',
			BuildTotemHandler(GetSpellInfo(manaTideTotem[1])),
		},

		Configure {
			'NatureResistanceTotem',
			L['Show the duration of @NAME.'],
			natureResistanceTotem,
			'player',
			'PLAYER_TOTEM_UPDATE',
			BuildTotemHandler(GetSpellInfo(natureResistanceTotem[1])),
		},

		Configure {
			'PoisonCleansingTotem',
			L['Show the duration of @NAME.'],
			poisonCleansingTotem,
			'player',
			'PLAYER_TOTEM_UPDATE',
			BuildTotemHandler(GetSpellInfo(poisonCleansingTotem[1])),
		},

		Configure {
			'SearingTotem',
			L['Show the duration of @NAME.'],
			searingTotem,
			'player',
			'PLAYER_TOTEM_UPDATE',
			BuildTotemHandler(GetSpellInfo(searingTotem[1])),
		},

		Configure {
			'SentryTotem',
			L['Show the duration of @NAME.'],
			sentryTotem,
			'player',
			'PLAYER_TOTEM_UPDATE',
			BuildTotemHandler(GetSpellInfo(sentryTotem[1])),
		},

		Configure {
			'StoneclawTotem',
			L['Show the duration of @NAME.'],
			stoneclawTotem,
			'player',
			'PLAYER_TOTEM_UPDATE',
			BuildTotemHandler(GetSpellInfo(stoneclawTotem[1])),
		},

		Configure {
			'StoneskinTotem',
			L['Show the duration of @NAME.'],
			stoneskinTotem,
			'player',
			'PLAYER_TOTEM_UPDATE',
			BuildTotemHandler(GetSpellInfo(stoneskinTotem[1])),
		},

		Configure {
			'StrengthOfEarthTotem',
			L['Show the duration of @NAME.'],
			strengthOfEarthTotem,
			'player',
			'PLAYER_TOTEM_UPDATE',
			BuildTotemHandler(GetSpellInfo(strengthOfEarthTotem[1])),
		},

		Configure {
			'tranquilAirTotem',
			L['Show the duration of @NAME.'],
			tranquilAirTotem,
			'player',
			'PLAYER_TOTEM_UPDATE',
			BuildTotemHandler(GetSpellInfo(tranquilAirTotem[1])),
		},

		Configure {
			'TremorTotem',
			L['Show the duration of @NAME.'],
			tremorTotem,
			'player',
			'PLAYER_TOTEM_UPDATE',
			BuildTotemHandler(GetSpellInfo(tremorTotem[1])),
		},

		Configure {
			'WindfuryTotem',
			L['Show the duration of @NAME.'],
			windfuryTotem,
			'player',
			'PLAYER_TOTEM_UPDATE',
			BuildTotemHandler(GetSpellInfo(windfuryTotem[1])),
		},

		Configure {
			'WindwallTotem',
			L['Show the duration of @NAME.'],
			windwallTotem,
			'player',
			'PLAYER_TOTEM_UPDATE',
			BuildTotemHandler(GetSpellInfo(windwallTotem[1])),
		},

		Configure {
			'WrathOfAirTotem',
			L['Show the duration of @NAME.'],
			wrathOfAirTotem,
			'player',
			'PLAYER_TOTEM_UPDATE',
			BuildTotemHandler(GetSpellInfo(wrathOfAirTotem[1])),
		},

	}
end)
