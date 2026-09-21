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

if not addon.isClass('MAGE') then return end
if not addon.isFlavor('forever') then return end

AdiButtonAuras:RegisterRules(function()
	Debug('Rules', 'Adding forever mage rules')

	-- any rank of Arcane Intellect
	local arcaneIntellect = {
		1459, -- Begin Arcane Intellect
		1460,
		1461,
		10156,
		10157, -- End Arcane Intellect
	}

	return {
		ImportPlayerSpells {
			-- import all spells for
			'MAGE',
			-- except for
			1459,
			1460,
			1461,
			10156,
			10157,
		},

		Configure {
			'ArcaneIntellect',
			format(L['%s %s'],
				L['Show the number of group members missing @NAME.'],
				L['With a friendly target, show @NAME on it instead. In combat, only the target or yourself can be shown.']
			),
			arcaneIntellect,
			{ 'group', 'ally' },
			{ 'GROUP_ROSTER_UPDATE', 'UNIT_AURA' },
			{
				function(units, model)
					if AurasAreSecret() then return end

					local missing = 0
					local shortest
					for unit in next, units.group do
						if UnitIsPlayer(unit) and not UnitIsDeadOrGhost(unit) then
							local found, _, expiration
							for _, id in ipairs(arcaneIntellect) do
								found, _, expiration = GetBuff(unit, id)
								if found then break end
							end
							if found then
								if not shortest or expiration < shortest then
									shortest = expiration
								end
							else
								missing = missing + 1
							end
						end
					end

					local ally = units.ally
					if ally and ally ~= 'player' then
						shortest = nil
						for _, id in ipairs(arcaneIntellect) do
							local found, _, expiration = GetBuff(ally, id)
							if found then
								shortest = expiration
								break
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
				InCombatOnly(BuildAuraHandler_FirstOf('HELPFUL', 'good', 'ally', arcaneIntellect)),
			},
		},
	}
end)
