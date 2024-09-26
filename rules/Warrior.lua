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

AdiButtonAuras:RegisterRules(function()
	Debug('Rules', 'Adding warrior rules')

	return {
		ImportPlayerSpells {
			-- add all spells for
			'WARRIOR',
			-- except for
			6673, -- Battle Shout
		},

		Configure {
			'BattleShout',
			L['Show the number of group members missing @NAME.'],
			6673, -- Battle Shout
			'group',
			{ 'GROUP_ROSTER_UPDATE', 'UNIT_AURA' },
			function(units, model)
				local missing = 0
				local shortest
				for unit in next, units.group do
					if UnitIsPlayer(unit) and not UnitIsDeadOrGhost(unit) then
						local found, _, expiration = GetBuff(unit, 6673)
						if found then
							if not shortest or expiration < shortest then
								shortest = expiration
							end
						else
							missing = missing + 1
						end
					end
				end

				if shortest then
					model.expiration = shortest
					model.highlight = 'good'
				end
				if missing > 0 then
					model.count = missing
					model.hint = true
				end
			end,
		},
	}
end)
