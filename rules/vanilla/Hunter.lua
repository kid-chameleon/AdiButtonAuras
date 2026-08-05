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

if not addon.isClass('HUNTER') then return end
if not addon.isFlavor('vanilla') then return end

AdiButtonAuras:RegisterRules(function()
	Debug('Rules', 'Adding vanilla hunter rules')

	local rules = {
		ImportPlayerSpells { 'HUNTER' },

		ShowReactive {
			{
				1495, -- Begin Mongoose Bite
				14269,
				14270,
				14271, -- End Mongoose Bite
			},
			L['Flash when @NAME is usable after you dodge.'],
		},

		ShowReactive {
			{
				19306, -- Begin Counterattack
				20909,
				20910, -- End Counterattack
			},
			L['Flash when @NAME is usable after you parry.'],
		},
	}

	if isSoD then
		tinsert(rules, ShowStacks {
			{
				19434, -- Begin Aimed Shot
				20900,
				20901,
				20902,
				20903,
				20904, -- End Aimed Shot
			},
			415401, -- Sniper Training
			5,
			"player",
			1,
			"highlight",
		})
	end

	return rules
end)
