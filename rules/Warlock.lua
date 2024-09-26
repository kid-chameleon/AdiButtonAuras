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

if not addon.isClass('WARLOCK') then return end

AdiButtonAuras:RegisterRules(function()
	Debug('Rules', 'Adding warlock rules')

	return {
		ImportPlayerSpells {
			-- import all spells for
			'WARLOCK',
			-- except
			111400, -- Burning Rush (talent)
			212580, -- Eye of the Observer (Demonology honor talent)
		},

		ShowPower {
			{
				5740, -- Rain of Fire (Destruction)
				17877, -- Shadowburn (Destruction)
				27243, -- Seed of Corruption (Affliction)
				104316, -- Call Dreadstalkers (Demonology)
				105174, -- Hand of Gul'dan (Demonology)
				111898, -- Grimoire: Felguard (Demonology)
				116858, -- Chaos Bolt (Destruction)
				264119, -- Summon Vilefiend (Destruction)
				278350, -- Vile Taint (Affliction)
				324536, -- Malefic Rapture (Affliction)
				342601, -- Ritual of Doom
				385899, -- Soulburn (Destruction)
				417537, -- Oblivion (Affliction)
			},
			'SoulShards',
		},

		Configure {
			'DemonicGateway',
			BuildDesc('HARMFUL', 'bad', 'player', 113942),
			111771, -- Demonic Gateway
			'player',
			'UNIT_AURA',
			function(_, model)
				local found, _, expiration = GetDebuff('player', 113942)
				if found then
					model.expiration = expiration
					model.highlight = 'bad'
				end
			end,
		},

		Configure {
			'SummonInfernal',
			L['Show the duration of @NAME.'],
			1122, -- Summon Infernal (Destruction)
			'player',
			'PLAYER_TOTEM_UPDATE',
			BuildDemonHandler(infernal),
		},

		Configure {
			'CallFelLord',
			L['Show the duration of @NAME.'],
			212459, -- Call Fel Lord (Demonology honor talent)
			'player',
			'PLAYER_TOTEM_UPDATE',
			BuildDemonHandler(felLord),
		},

		Configure {
			'Observer',
			L['Show the duration of @NAME.'],
			201996, -- Call Observer (Demonology honor talent)
			'player',
			'PLAYER_TOTEM_UPDATE',
			BuildDemonHandler(observer),
		},

		Configure {
			'Darkglare',
			L['Show the duration of @NAME.'],
			205180, -- Summon Darkglare (Affliction)
			'player',
			'PLAYER_TOTEM_UPDATE',
			BuildDemonHandler(darkglare),
		},
	}
end)
