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

if not addon.isClass('PALADIN') then return end

AdiButtonAuras:RegisterRules(function()
	Debug('Rules', 'Adding paladin rules')

	return {
		ImportPlayerSpells {
			-- import all spells for
			'PALADIN',
			-- except for
			642, -- Divine Shield
			1022, -- Blessing of Protection
			25771, -- Forbearance
		},

		Configure {
			'DivineShield',
			format(L['%s %s'],
				BuildDesc('HELPFUL PLAYER', 'good', 'player', 642), -- Divine Shield
				BuildDesc('HARMFUL', 'bad', 'player', 25771) -- Forbearance
			),
			642,                                        -- Divine Shield
			'player',
			'UNIT_AURA',
			(function()
				local hasForbearanceOnSelf = BuildAuraHandler_Single('HARMFUL', 'bad', 'player', 25771)
				local hasDivineShield = BuildAuraHandler_Single('HELPFUL', 'good', 'player', 642)
				return function(units, model)
					return hasDivineShield(units, model) or hasForbearanceOnSelf(units, model)
				end
			end)(),
		},

		Configure {
			'BlessingOfProtection',
			format(L['%s %s'],
				BuildDesc('HELPFUL', 'good', 'ally', 1022),
				forbearanceDesc
			),
			1022,
			'ally',
			'UNIT_AURA',
			(function()
				local hasBlessingOfProtection = BuildAuraHandler_Single('HELPFUL', 'good', 'ally', 1022)
				return function(units, model)
					return hasBlessingOfProtection(units, model) or hasForbearance(units, model)
				end
			end)(),
		},

	}
end)
