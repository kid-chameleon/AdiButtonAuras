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

if not addon.isClass('DRUID') then return end
if not addon.isFlavor('vanilla') then return end

AdiButtonAuras:RegisterRules(function()
	Debug('Rules', 'Adding vanilla druid rules')

	return {
		ImportPlayerSpells { 'DRUID' },

		ShowPower {
			{
				1079, -- Begin Rip
				9492,
				9493,
				9752,
				9894,
				9896, -- End Rip
				22568, -- Begin Ferocious Bite
				22827,
				22828,
				22829,
				31018, -- End Ferocious Bite
			},
			'ComboPoints',
		},
	}
end)
