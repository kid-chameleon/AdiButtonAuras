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

-- On clients with secret values the engine draws the aura texts and the layout is fixed when the
-- slot frame is created, so whether an aura may show a count next to its timer has to be known
-- ahead of time. See core/SecretAuras.lua.

local _, addon = ...

if not addon.isFlavor('forever') then return end

local ids = {
	400573, -- Arcane Blast
	11129, -- Combustion
	1010, -- Curse of Idiocy
	2818, -- Deadly Poison
	2819, -- Deadly Poison II
	11353, -- Deadly Poison III
	11354, -- Deadly Poison IV
	25349, -- Deadly Poison V
	2651, -- Elune's Grace
	1259812, 1259813, 1259817, 1259821, 1259823, -- Eureka!
	22959, -- Fire Vulnerability
	20925, 20927, 20928, -- Holy Shield
	588, 602, 1006, 7128, 10951, 10952, -- Inner Fire
	414644, 1235826, 1235827, -- Lacerate
	324, 325, 905, 945, 8134, 10431, 10432, -- Lightning Shield
	401877, 1240848, 1240849, -- Prayer of Mending
	20230, -- Retaliation
	24583, 24586, 24587, 24640, -- Scorpid Poison
	18137, 19308, 19309, 19310, 19311, 19312, -- Shadowguard
	2565, -- Shield Block
	7386, 7405, 8380, 11596, 11597, -- Sunder Armor
	12292, -- Sweeping Strikes
	408510, -- Water Shield
	13218, 13222, 13223, 13224, -- Wound Poison
}

local stackingAuras = {}
for _, id in ipairs(ids) do
	stackingAuras[id] = true
end
addon.stackingAuras = stackingAuras
