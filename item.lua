local ITEM_QUALITY_NAMES = {
    [0] = "Poor", [1] = "Common", [2] = "Uncommon", [3] = "Rare",
    [4] = "Epic", [5] = "Legendary", [6] = "Artifact",
}


-- Create hidden tooltip
local Scanner = CreateFrame("GameTooltip", "LootTrackerTooltipScanner", nil, "GameTooltipTemplate")
Scanner:SetOwner(UIParent, "ANCHOR_NONE")

-- Prepare left/right fontstrings (up to 30 lines)
for i = 1, 30 do
    local left = _G["LootTrackerTooltipScannerTextLeft"..i]
    local right = _G["LootTrackerTooltipScannerTextRight"..i]
    if not left then
        left = Scanner:CreateFontString("LootTrackerTooltipScannerTextLeft"..i, nil, "GameTooltipText")
    end
    if not right then
        right = Scanner:CreateFontString("LootTrackerTooltipScannerTextRight"..i, nil, "GameTooltipText")
    end
    Scanner:AddFontStrings(left, right)
end

-- Find existing items to avoid duplicate entries
local function isItemDuplicate(name, id, sourceID)
  for _, item in ipairs(ItemTrackerDB) do
    if item["itemName"] == name and item["itemID"] == id and item["itemSourceID"] == sourceID then
      return true
    end
  end
  return false
end

-- Extract item ID from link
function LootTracker_GetItemID(itemLink)
    local itemString = string.match(itemLink, "item:(%d+)")
    return tonumber(itemString)
end

function LootTracker_GetTextureFilename(texturePath)
    if not texturePath then return nil end
    return texturePath:match("([^\\]+)$")
end

-- Read tooltip lines
function LootTracker_GetTooltipLines(itemLink)
    Scanner:ClearLines()
    Scanner:SetHyperlink(itemLink)

    local lines = {}

    for i = 1, Scanner:NumLines() do
        local left = _G["LootTrackerTooltipScannerTextLeft"..i]
        local right = _G["LootTrackerTooltipScannerTextRight"..i]

        if left and left:GetText() and left:GetText() ~= "" then
            table.insert(lines, left:GetText())
        end
        if right and right:GetText() and right:GetText() ~= "" then
            table.insert(lines, right:GetText())
        end
    end
    return lines
end

function LootTracker_HandleChatLoot(msg)
 local player, itemLink, quantity

    -- Group loot with quantity
    player, itemLink, quantity = msg:match("^(.+) receives loot: (.+) x(%d+)$")
    -- Group loot no quantity
    if not player then
        player, itemLink = msg:match("^(.+) receives loot: (.+)$")
    end
    -- Self loot with quantity
    if not player then
        itemLink, quantity = msg:match("^You receive item: (.+) x(%d+)$")
        if itemLink then player = UnitName("player") end
    end
    -- Self loot no quantity
    if not player then
        itemLink = msg:match("^You receive item: (.+)$")
        if itemLink then player = UnitName("player") end
    end
    -- Other won loot roll
    if not player then
        player, itemLink = msg:match("^(.+) won: (.+)$")
        if itemLink then player = UnitName("player") end
    end

    if player and itemLink then
        quantity = tonumber(quantity) or 1
        LootTracker_SaveLoot(itemLink, "Chat", 0)
    elseif not player and not itemLink then
      -- too noisy
      -- DebugLog("Self Loot not logged:", msg)
    end
end

-- Handle LOOT_OPENED
function LootTracker_HandleLootOpened()
  if UnitExists('mouseover') then
    print('npc')
    local id, guidType = AddCreatureOrLocation("mouseover")
    for i = 1, GetNumLootItems() do
      local texture = select(1, GetLootSlotInfo(i))
      local itemLink = GetLootSlotLink(i)
        if itemLink and texture then
          LootTracker_SaveLoot(itemLink, guidType, id)
        end
    end
  else
    print('container')
    local targetType = "Container"
    local targetID = 0
    for i = 1, GetNumLootItems() do
    local texture = select(1, GetLootSlotInfo(i))
    local itemLink = GetLootSlotLink(i)
    if itemLink and texture then
      LootTracker_SaveLoot(itemLink, targetType, targetID)
    end
  end

  end
end


-- Save loot to DB
function LootTracker_SaveLoot(itemLink, sourceType, sourceID)
    if not itemLink then return end
    local itemID = LootTracker_GetItemID(itemLink)
    local tooltip = LootTracker_GetTooltipLines(itemLink)
    local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(itemID)
    texture = LootTracker_GetTextureFilename(texture)
    if isItemDuplicate(name, itemID, sourceID) then DebugLog("Skipping Duplicate Item", name, itemID, sourceID) return end

    table.insert(ItemTrackerDB, {
        itemID = itemID,
        itemName = name,
        itemLink = link,
        itemQuality = quality,
        itemLevel = iLevel,
        itemReqLevel = reqLevel,
        itemClass = class,
        itemSubClass = subclass,
        itemMaxStack = maxStack,
        itemEquipSlot = equipSlot,
        itemTexture = texture,
        itemVendorPrice = vendorPrice,
        itemSource = sourceType,
        itemSourceID = sourceID or 0,
        itemTooltip = tooltip
    })
    -- LootTracker_PrintDB()
    DebugLog(string.format("Looted: %s (ID: %d, iLvl: %d, Quality: %s) from %s [%s]",
        itemLink, itemID or 0, iLevel or 0,
        quality, sourceType or "Unknown", sourceID or "N/A"))
end
