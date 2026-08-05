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
if not addon.isFlavor('tbc') then return end

AdiButtonAuras:RegisterRules(function()
	Debug('Rules', 'Adding tbc hunter rules')

	return {
		ImportPlayerSpells { 'HUNTER' },

		ShowReactive {
			34026, -- Kill Command
			L['Flash when @NAME is usable after one of your attacks critically hits.'],
		},

		ShowReactive {
			{
				1495, -- Begin Mongoose Bite
				14269,
				14270,
				14271,
				36916, -- End Mongoose Bite
			},
			L['Flash when @NAME is usable after you dodge.'],
		},

		ShowReactive {
			{
				19306, -- Begin Counterattack
				20909,
				20910,
				27067, -- End Counterattack
			},
			L['Flash when @NAME is usable after you parry.'],
		},
	}
end)
