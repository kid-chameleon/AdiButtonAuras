package.path = package.path .. ';./wowmock/?.lua'

local wowmock = require('wowmock')

describe('Items', function ()
    local G, addon, LibItemBuffs

    before_each(function ()
        G = mock({Enum = {ItemClass = {Consumable = 0}}})
        LibItemBuffs = mock({GetDatabaseVersion = function () return 8 end})
        addon = mock({GetAuraGetter = function () return function () end end})
        addon.GetLib = function (lib)
            if lib == 'LibItemBuffs-1.0' then
                return LibItemBuffs, 1
            end
        end
        addon.Memoize = function (f)
            return setmetatable({}, { __index = function (_, k) return f(k) end })
        end
        addon.rules = {}
        addon.descriptions = {}
    end)

    local function load()
        wowmock('../core/Items.lua', G, 'AdiButtonAuras', addon)
    end

    it('spell', function ()
        load()
        local rule = addon.rules['spell:456']

        assert.is_false(rule)
    end)

    it('unknown item', function ()
        G.GetItemSpell = function (_itemId) return nil end
        spy.on(G, 'GetItemSpell')
        LibItemBuffs.GetItemBuffs = function (_self, _itemId) return nil end
        spy.on(LibItemBuffs, 'GetItemBuffs')

        load()

        local rule = addon.rules['item:456']
        assert.is_false(rule)
        assert.spy(G.GetItemSpell).was.called_with(456)
        assert.spy(LibItemBuffs.GetItemBuffs).was.called_with(LibItemBuffs, 456)
    end)

    for i, data in next, {
        { false, true, 'ally', 'HELPFUL PLAYER', 'good' },
        { false, false, 'player', 'HELPFUL PLAYER', 'good' },
        { true, false, 'enemy', 'HARMFUL PLAYER', 'bad' },
    } do
        local harmful, helpful, token, filter, highlight = unpack(data)

        it('GetItemSpell' .. i, function ()
            LibItemBuffs.GetItemBuffs = function (_self, _itemId) return nil end
            G.GetItemSpell = function (_item) return 'LeBuff' end
            G.GetItemInfo = function (_item) return 'LeItem', nil, nil, nil, nil, 'Miscellaneous', nil, nil, nil, nil, nil, 15 end
            G.IsHarmfulItem = function (_item) return harmful end
            G.IsHelpfulItem = function (_item) return helpful end
            G = mock(G)
            addon.BuildKey = function () return 'LeKey' end
            addon.BuildDesc = function () return 'LeDesc' end
            addon = mock(addon)

            load()

            local rule = addon.rules['item:456']

            assert.spy(G.GetItemSpell).was.called_with(456)
            assert.spy(G.GetItemInfo).was.called_with(456)
            assert.spy(G.IsHarmfulItem).was.called_with(456)
            assert.spy(addon.BuildKey).was.called_with('item', 456, token, filter, highlight, 'LeBuff')
            assert.spy(addon.BuildDesc).was.called_with(filter, highlight, token, 'LeBuff')

            assert.equals(token, next(rule.units))
            assert.equals('LeItem', rule.name)
            assert.equals('LeKey', rule.keys[1])
            assert.equals('LeDesc', addon.descriptions['LeKey'])
        end)
    end

    for i, data in next, {
        { false, true, 'ally', 'HELPFUL PLAYER', 'good' },
        { false, false, 'player', 'HELPFUL PLAYER', 'good' },
        { true, false, 'enemy', 'HARMFUL PLAYER', 'bad' },
    } do
        local harmful, helpful, token, filter, highlight = unpack(data)

        it('GetItemBuffs' .. i, function ()
            LibItemBuffs.GetItemBuffs = function (self, _itemId) return 500 end
            spy.on(LibItemBuffs, 'GetItemBuffs')
            G.GetItemSpell = function (_item) return nil end
            G.GetItemInfo = function (_item) return 'LeItem', nil, nil, nil, nil, 'Miscellaneous', nil, nil, nil, nil, nil, 15 end
            G.IsHarmfulItem = function (_item) return harmful end
            G.IsHelpfulItem = function (_item) return helpful end
            G = mock(G)
            addon.BuildKey = function () return 'LeKey' end
            addon.BuildDesc = function () return 'LeDesc' end
            addon = mock(addon)

            load()

            local rule = addon.rules['item:456']

            assert.spy(LibItemBuffs.GetItemBuffs).was.called_with(LibItemBuffs, 456)
            assert.spy(G.GetItemSpell).was.called_with(456)
            assert.spy(G.GetItemInfo).was.called_with(456)
            assert.spy(G.IsHarmfulItem).was.called_with(456)
            assert.spy(addon.BuildKey).was.called_with('item', 456, token, filter, highlight, 500)
            assert.spy(addon.BuildDesc).was.called_with(filter, highlight, token, 500)

            assert.equals(token, next(rule.units))
            assert.equals('LeItem', rule.name)
            assert.equals('LeKey', rule.keys[1])
            assert.equals('LeDesc [LIB-1-8]', addon.descriptions['LeKey'])
        end)
    end

    it('GetItemWeaponEnchants', function ()
        LibItemBuffs.GetItemBuffs = function (_self, _itemId) return nil end
        LibItemBuffs.GetItemWeaponEnchants = function (_self, _itemId) return 19 end
        G.GetItemSpell = function (_item) return 'Enhance Blunt Weapon' end
        G.GetItemInfo = function (_item) return 'Rough Weightstone', nil, nil, nil, nil, 'Trade Goods', nil, nil, nil, nil, nil, 7 end
        G.IsHarmfulItem = function (_item) return false end
        G.IsHelpfulItem = function (_item) return false end
        G.GetTime = function () return 100 end
        addon.BuildKey = function (...) return table.concat({ ... }, ':') end
        addon.L = setmetatable({}, { __index = function (_, k) return k end })
        addon.FindWeaponEnchant = function (enchantId)
            if enchantId == 19 then return 1800000, 0 end
        end
        addon.db = { profile = { rules = setmetatable({}, { __index = function () return true end }) } }

        load()

        local rule = addon.rules['item:3239']
        local key = 'item:3239:WeaponEnchant:19'

        assert.same({ player = true }, rule.units)
        assert.same({ WEAPON_ENCHANT_CHANGED = true, WEAPON_SLOT_CHANGED = true }, rule.events)
        assert.same({ key }, rule.keys)
        assert.equals('Show the duration of Rough Weightstone [LIB-1-8]', addon.descriptions[key])

        local model = {}
        assert.is_true(rule.handlers[1]({}, model))
        assert.same({ highlight = 'good', count = 0, expiration = 1900 }, model)

        addon.FindWeaponEnchant = function () end
        addon.rules = {}
        load()
        assert.is_nil(addon.rules['item:3239'].handlers[1]({}, {}))
    end)
end)
