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

if not addon.isClass('WARRIOR') then return end
if not addon.isFlavor('vanilla') then return end

AdiButtonAuras:RegisterRules(function()
	Debug('Rules', 'Adding vanilla warrior rules')

	-- the shouts are flagged RAIDBUFF and thus not imported; show the
	-- duration of any rank found on the player, whoever cast it
	local battleShout = {
		6673, -- Begin Battle Shout
		5242,
		6192,
		11549,
		11550,
		11551,
		25289, -- End Battle Shout
	}

	local rules = {
		ImportPlayerSpells { 'WARRIOR' },

		Configure {
			'BattleShout',
			BuildDesc('HELPFUL', 'good', 'player', 6673),
			battleShout,
			'player',
			'UNIT_AURA',
			BuildAuraHandler_FirstOf('HELPFUL', 'good', 'player', battleShout),
		},

		ShowReactive {
			{
				7384, -- Begin Overpower
				7887,
				11584,
				11585, -- End Overpower
			},
			L['Flash when @NAME is usable after your target dodges.'],
		},

		ShowReactive {
			{
				6572, -- Begin Revenge
				6574,
				7379,
				11600,
				11601,
				25288, -- End Revenge
			},
			L['Flash when @NAME is usable after you block, dodge or parry.'],
		},

		ShowReactive {
			{
				5308, -- Begin Execute
				20658,
				20660,
				20661,
				20662, -- End Execute
			},
			L['Flash when @NAME is usable on enemies below 20% health.'],
		},
	}

	if isSoD then
		tinsert(rules, Configure {
			'CommandingShout',
			BuildDesc('HELPFUL', 'good', 'player', 403215),
			403215, -- Commanding Shout
			'player',
			'UNIT_AURA',
			BuildAuraHandler_Single('HELPFUL', 'good', 'player', 403215),
		})

		tinsert(rules, ShowReactive {
			402927, -- Victory Rush (rune)
			L['Flash when @NAME is usable after you kill an enemy.'],
		})

		tinsert(rules, ShowReactive {
			402911, -- Raging Blow (rune)
			L['Flash when @NAME is usable while you are Enraged.'],
		})
	end

	return rules
end)
