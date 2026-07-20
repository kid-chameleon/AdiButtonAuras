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

if not addon.isClass('PRIEST') then return end
if not addon.isFlavor('vanilla') then return end

AdiButtonAuras:RegisterRules(function()
	Debug('Rules', 'Adding vanilla priest rules')

	local powerWordShield = {
		17, -- Begin Power Word: Shield
		592,
		600,
		3747,
		6065,
		6066,
		10898,
		10899,
		10900,
		10901, -- End Power Word: Shield
	}

	-- any rank of Power Word: Fortitude or Prayer of Fortitude
	local fortitude = {
		1243, -- Begin Power Word: Fortitude
		1244,
		1245,
		2791,
		10937,
		10938, -- End Power Word: Fortitude
		21562, -- Begin Prayer of Fortitude
		21564, -- End Prayer of Fortitude
	}

	local mindControl = {
		605, -- Begin Mind Control
		10911,
		10912, -- End Mind Control
	}

	local hasWeakenedSoul = BuildAuraHandler_Single('HARMFUL', 'bad', 'ally', 6788) -- Weakened Soul
	local isShielded = BuildAuraHandler_FirstOf('HELPFUL', 'good', 'ally', powerWordShield)

	local rules = {
		ImportPlayerSpells {
			-- import all spells for
			'PRIEST',
			-- except for
			6788, -- Weakened Soul
			17, -- Begin Power Word: Shield
			592,
			600,
			3747,
			6065,
			6066,
			10898,
			10899,
			10900,
			10901, -- End Power Word: Shield
			1243, -- Begin Power Word: Fortitude
			1244,
			1245,
			2791,
			10937,
			10938, -- End Power Word: Fortitude
			21562, -- Begin Prayer of Fortitude
			21564, -- End Prayer of Fortitude
		},

		Configure {
			'PowerWordShield',
			format(L['%s %s'],
				BuildDesc('HARMFUL', 'bad', 'ally', 6788), -- Weakened Soul
				BuildDesc('HELPFUL', 'good', 'ally', 17) -- Power Word: Shield
			),
			powerWordShield,
			'ally',
			'UNIT_AURA',
			function(units, model)
				return hasWeakenedSoul(units, model) or isShielded(units, model)
			end,
		},

		Configure {
			'PowerWordFortitude',
			L['Show the number of group members missing @NAME.'],
			fortitude,
			'group',
			{ 'GROUP_ROSTER_UPDATE', 'UNIT_AURA' },
			function(units, model)
				local missing = 0
				local shortest
				for unit in next, units.group do
					if UnitIsPlayer(unit) and not UnitIsDeadOrGhost(unit) then
						local found, _, expiration
						for _, id in ipairs(fortitude) do
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

		-- the crowd control rule from Common.lua tracks the enemy token;
		-- while Mind Control runs the victim is the pet unit instead
		Configure {
			'MindControl',
			L['Show the duration of @NAME.'],
			mindControl,
			'pet',
			{ 'UNIT_AURA', 'UNIT_PET' },
			function(_, model)
				for _, id in ipairs(mindControl) do
					local found, _, expiration = GetPlayerDebuff('pet', id)
					if found then
						model.expiration = expiration
						model.highlight = 'good'
						return true
					end
				end
			end,
		},
	}

	if isSoD then
		-- REVIEW: verify the era client reports the Shadowfiend through GetTotemInfo
		tinsert(rules, ShowTotem { 401977, 136199 }) -- Shadowfiend (SoD rune)
	end

	return rules
end)
