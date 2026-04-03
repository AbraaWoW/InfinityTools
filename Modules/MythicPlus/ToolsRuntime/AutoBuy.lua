-- [[ ???? ]]
-- { Key = "RRTTools.AutoBuy", Name = "????", Desc = "?????????????????(??????????)?", Category = 4 },

local RRTToolsCore = _G.RRTToolsCore
local InfinityExtrasDB = _G.InfinityExtrasDB
if not RRTToolsCore then return end
local RRTState = RRTToolsCore.State
local L = (RRTToolsCore and RRTToolsCore.L) or setmetatable({}, { __index = function(_, key) return key end })

-- 1. ?? Key
local RRT_MODULE_KEY = "RRTTools.AutoBuy"

-- 2. ????
if not RRTToolsCore:IsModuleEnabled(RRT_MODULE_KEY) then return end

-- 3. ?????? DB ???
local RRT_DEFAULTS = {
    enabled = false,
    Items = {},       -- ?? ID -> {enabled, quantity}
    CustomItems = {}, -- ?? ID -> {enabled, quantity}
}
local RRT_DB = RRTToolsCore:GetModuleDB(RRT_MODULE_KEY, RRT_DEFAULTS)

-- ??????
local PRESET_ITEMS = {
    { id = 151060, buy = 1, cat = "map", name = "" },
    { id = 201344, buy = 5, cat = "map" }, { id = 159691, buy = 5, cat = "map" },
    { id = 201333, buy = 5, cat = "map" }, { id = 253009, buy = 5, cat = "map" },
    { id = 253012, buy = 5, cat = "map" }, { id = 252951, buy = 5, cat = "map" },
    { id = 252658, buy = 5, cat = "map" }, { id = 253010, buy = 5, cat = "map" },
    { id = 166381, buy = 5, cat = "key" }, { id = 166380, buy = 5, cat = "key" },
    { id = 166379, buy = 5, cat = "key" }, { id = 166378, buy = 5, cat = "key" },
    { id = 166377, buy = 5, cat = "key" }, { id = 159694, buy = 5, cat = "key" },
    { id = 159695, buy = 5, cat = "key" }, { id = 159696, buy = 5, cat = "key" },
    { id = 159697, buy = 5, cat = "key" }, { id = 159698, buy = 5, cat = "key" },
    { id = 243734, buy = 100, cat = "food" }, { id = 243738, buy = 100, cat = "food" },
    { id = 241326, buy = 200, cat = "food" }, { id = 241324, buy = 200, cat = "food" },
}

-- =========================================================
-- [v4.2] ?????
-- =========================================================



-- 2. Grid ?? (??)
local function RRT_RegisterLayout()
    local layout = {
        { key = "header", type = "header", x = 1, y = 1, w = 47, h = 3, label = L["???? (Auto Buy)"], labelSize = 25 },
        { key = "desc", type = "description", x = 1, y = 4, w = 47, h = 2, label = L["????????,???????????? (?????????)"] },
        { key = "sub_add", type = "subheader", x = 1, y = 6, w = 47, h = 1, label = L["???? (????ID)"], labelSize = 20 },
        { key = "addID", type = "input", x = 1, y = 9, w = 18, h = 2, label = L["?? ID"] },
        { key = "addItem", type = "button", x = 20, y = 9, w = 8, h = 2, label = L["??"] },
        { key = "sub_c", type = "subheader", x = 1, y = 12, w = 47, h = 2, label = L["??????? (??????)"], labelSize = 20 },
    }


    -- ???(???)????????????
    table.insert(layout, {
        key = "new_item_drop",
        type = "itemconfig",
        itemID = 0,
        x = 1,
        y = 14,
        w = 35,
        h = 3
    })

    local y = 17.5

    -- ???????
    local customList = {}
    for id, _ in pairs(RRT_DB.CustomItems) do table.insert(customList, tonumber(id)) end
    table.sort(customList)

    for _, id in ipairs(customList) do
        table.insert(layout, {
            key = id,
            parentKey = "CustomItems",
            subKey = id,
            type = "itemconfig",
            itemID = id,
            x = 1,
            y = y,
            w = 35,
            h = 3,
            canDelete = true, -- ????????(??????)
            labelSize = 18
        })
        y = y + 3.5
    end

    y = y + 1
    table.insert(layout, { key = "sub_p", type = "subheader", x = 1, y = y, w = 47, h = 1, label = L["???? (?????/??)"] })
    y = y + 2

    local cats = { { k = "food", n = L["???"] }, { k = "key", n = L["????"] }, { k = "map", n = L["????"] } }
    for _, cat in ipairs(cats) do
        -- [Core] ??? Key ? Map ??????? Beta ??,???
        local isBetaOnly = (cat.k == "key" or cat.k == "map")
        local shouldShow = (not isBetaOnly) or RRTToolsCore.IsBeta

        if shouldShow then
            table.insert(layout,
                {
                    key = "t_" .. cat.k,
                    type = "description",
                    x = 1,
                    y = y,
                    w = 47,
                    h = 1,
                    label = "|cffffd100" .. cat.n ..
                        "|r"
                })
            y = y + 1.5
            for _, it in ipairs(PRESET_ITEMS) do
                if it.cat == cat.k then
                    if not RRT_DB.Items[it.id] then RRT_DB.Items[it.id] = { enabled = true, quantity = it.buy } end
                    table.insert(layout, {
                        key = it.id,
                        parentKey = "Items",
                        subKey = it.id,
                        type = "itemconfig",
                        itemID = it.id,
                        x = 1,
                        y = y,
                        w = 35,
                        h = 3,
                        canDelete = false, -- ????????
                        labelSize = 18
                    })
                    y = y + 3.5
                end
            end
            y = y + 1
        end
    end

    RRTToolsCore:RegisterModuleLayout(RRT_MODULE_KEY, layout)
end

-- 3. ????
RRT_RegisterLayout()

-- =========================================================
-- ????:???????????
-- =========================================================

-- 1. ?????? (????)
RRTToolsCore:WatchState(RRT_MODULE_KEY .. ".ButtonClicked", RRT_MODULE_KEY, function(data)
    if data.key == "addItem" then
        local idStr = RRT_DB.addID
        local id = tonumber(idStr)
        if id and id > 0 then
            RRT_DB.CustomItems[id] = { enabled = true, quantity = 5 }
            RRT_DB.addID = "" -- ??
            RRT_RegisterLayout()
            RRTToolsCore.UI:RefreshContent()
        end
    end
end)

-- 2. ?? ItemConfig ?????????
RRTToolsCore:WatchState(RRT_MODULE_KEY .. ".ItemConfigDelete", RRT_MODULE_KEY, function(data)
    local id = tonumber(data.key)
    if id and RRT_DB.CustomItems[id] then
        RRT_DB.CustomItems[id] = nil
        RRT_RegisterLayout()
        RRTToolsCore.UI:RefreshContent()
    end
end)

-- 3. ?? ItemConfig ???????????(???????)
RRTToolsCore:WatchState(RRT_MODULE_KEY .. ".ItemConfigUpdate", RRT_MODULE_KEY, function(data)
    if data.key == "new_item_drop" then
        local newItemID = tonumber(data.itemID)
        if newItemID and newItemID > 0 then
            RRT_DB.CustomItems[newItemID] = { enabled = true, quantity = 5 }
            RRT_RegisterLayout()
            RRTToolsCore.UI:RefreshContent()
        end
    end
end)

local function GetCount(id)
    local c = 0
    local maxBagIndex = 4
    if Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag then
        maxBagIndex = Enum.BagIndex.ReagentBag
    else
        maxBagIndex = 5
    end

    for b = 0, maxBagIndex do
        for s = 1, C_Container.GetContainerNumSlots(b) do
            local inf = C_Container.GetContainerItemInfo(b, s)
            if inf and inf.itemID == id then c = c + inf.stackCount end
        end
    end
    return c
end

local function DoBuy(id, target)
    local have = GetCount(id)
    local need = target - have
    if need <= 0 then return end

    local num = GetMerchantNumItems()
    for i = 1, num do
        if GetMerchantItemID(i) == id then
            local _, _, _, _, _, _, _, stack = C_Item.GetItemInfo(id)
            stack = stack or 1
            while need > 0 do
                local buy = math.min(stack, need)
                BuyMerchantItem(i, buy)
                need = need - buy
            end
            return
        end
    end
end

RRTToolsCore:RegisterEvent("MERCHANT_SHOW", RRT_MODULE_KEY, function()
    -- ??
    for id, data in pairs(RRT_DB.Items) do
        if data.enabled then DoBuy(tonumber(id), tonumber(data.quantity) or 5) end
    end
    -- ???
    for id, data in pairs(RRT_DB.CustomItems) do
        if data.enabled then DoBuy(tonumber(id), tonumber(data.quantity) or 5) end
    end
end)

-- ????????
RRTToolsCore:ReportReady(RRT_MODULE_KEY)


