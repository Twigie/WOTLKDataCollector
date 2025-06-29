local AceTimer = LibStub("AceTimer-3.0")
-- local ITEM_QUALITY_NAMES = {
--     [0] = "Poor", [1] = "Common", [2] = "Uncommon", [3] = "Rare",
--     [4] = "Epic", [5] = "Legendary", [6] = "Artifact",
-- }

local WOW_CLASSES = {
  "Warrior", "Paladin", "Hunter", "Rogue",
  "Priest", "Shaman", "Mage",
  "Warlock", "Druid"
}

-- Create hidden tooltip
local Scanner = CreateFrame("GameTooltip", "LootTrackerTooltipScanner", nil, "GameTooltipTemplate")
Scanner:SetOwner(UIParent, "ANCHOR_NONE")
Scanner:ClearLines()
-- Prepare left/right fontstrings (up to 30 lines)
-- for i = 1, 100 do
--   local left = _G["LootTrackerTooltipScannerTextLeft" .. i]
--   local right = _G["LootTrackerTooltipScannerTextRight" .. i]
--   if not left then
--     left = Scanner:CreateFontString("LootTrackerTooltipScannerTextLeft" .. i, nil, "GameTooltipText")
--   end
--   if not right then
--     right = Scanner:CreateFontString("LootTrackerTooltipScannerTextRight" .. i, nil, "GameTooltipText")
--   end
--   Scanner:AddFontStrings(left, right)
-- end

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
local function LootTracker_GetTooltipLines(itemLink)
  if not GetItemInfo(itemLink) then
    print("Item not yet cached. Wait for ITEM_INFO_RECEIVED.")
    return {}
  end
  Scanner:ClearLines()
  Scanner:SetOwner(UIParent, "ANCHOR_NONE")
  Scanner:SetHyperlink(itemLink)


  local lines = {}
  for i = 1, select("#", Scanner:GetRegions()) do
    local region = select(i, Scanner:GetRegions())
    if region and region:GetObjectType() == "FontString" and region:GetText() then
      table.insert(lines, region:GetText())
    end
  end
  -- for i = 1, Scanner:NumLines() do
  --   print(Scanner:NumLines())
  --   local left = _G["LootTrackerTooltipScannerTextLeft" .. i]
  --   local right = _G["LootTrackerTooltipScannerTextRight" .. i]

  --   if left and left:GetText() and left:GetText() ~= "" then
  --     table.insert(lines, left:GetText())
  --     print(left:GetText())
  --   end
  --   if right and right:GetText() and right:GetText() ~= "" then
  --     table.insert(lines, right:GetText())
  --     print(right:GetText())
  --   end
  -- end
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

function ParseItemTooltip(tooltip)
  local parsed = {
    useEffect = {},
    equipEffect = {},
    procEffect = {},
    resistances = {},
    stats = {},
    requirement = {},
  }

  if not tooltip or type(tooltip) ~= "table" then return parsed end


  -- Line 1: Item name
  parsed.name = tooltip[1]

  -- Line 2: Binding text ("Binds when picked up", etc.)
  if tooltip[2] and tooltip[2]:find("Binds") then
    parsed.binding = tooltip[2]
  end

  -- Line 3: Requirement (e.g. "Requires ...")
  for i = 2, #tooltip do
    if tooltip[i]:find("^Requires") then
      table.insert(parsed.requirement, tooltip[i])
      break
    end
  end

  -- Look for Use: or Equip: or Chance on hit:
  for i = 2, #tooltip do
    local line = tooltip[i]:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    if line:find("^Use:") then
      table.insert(parsed.useEffect, line)
    elseif line:find("^Equip:") then
      table.insert(parsed.equipEffect, line)
    elseif line:find("^Chance on hit:") then
      table.insert(parsed.procEffect, line)
    elseif line:find("Unique") then
      parsed.unique = 1
      -- Stat bonus
    elseif line:find("^%+%d+%s") then
      local value, stat = line:match("^%+(%d+)%s+(.*)")
      if value and stat then
        -- Check if it's a resistance
        if stat:find("Resistance") then
          parsed.resistances[stat:lower()] = tonumber(value)
        else
          parsed.stats[stat:lower()] = tonumber(value)
        end
      end
      -- Damage line (e.g., "43 - 81 Damage")
    elseif line:find("Damage") and line:find("%-") then
      local min, max = line:match("(%d+)%s*%-%s*(%d+)%s*Damage")
      if min and max then
        parsed.minDamage = tonumber(min)
        parsed.maxDamage = tonumber(max)
      end

      -- Speed line (e.g., "Speed 2.80")
    elseif line:find("Speed") then
      local speed = line:match("Speed%s+(%d+%.?%d*)")
      if speed then
        parsed.speed = tonumber(speed)
      end
    elseif line:match("^Classes:%s*(.+)$") then
      local classList = line:match("^Classes:%s*(.+)$")
      for class in classList:gmatch("([^,]+)") do
        class = class:gsub("^%s+", ""):gsub("%s+$", "")
        table.insert(parsed.requirement, class)
      end
    end
  end
  return parsed
end

-- Save loot to DB
function LootTracker_SaveLoot(itemLink, sourceType, sourceID)
  if not itemLink then return end
  local itemID = LootTracker_GetItemID(itemLink)
  local tooltip = LootTracker_GetTooltipLines(itemLink)
  local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(
    itemID)
  texture = LootTracker_GetTextureFilename(texture)
  if isItemDuplicate(name, itemID, sourceID) then
    DebugLog("Skipping Duplicate Item", name, itemID, sourceID)
    return
  end
  local parsedTooltip = ParseItemTooltip(tooltip)
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
    itemTooltip = tooltip,
    useEffect = parsedTooltip.useEffect or {},
    equipEffect = parsedTooltip.equipEffect or {},
    procEffect = parsedTooltip.procEffect or {},
    speed = parsedTooltip.speed or 0,
    minDamage = parsedTooltip.minDamage or 0,
    maxDamage = parsedTooltip.maxDamage or 0,
    stats = parsedTooltip.stats or {},
    resistances = parsedTooltip.resistances or {},
    unique = parsedTooltip.unique or 0,
    requirement = parsedTooltip.requirement or {},
    binding = parsedTooltip.binding or ""
  })
  -- LootTracker_PrintDB()
  DebugLog(string.format("Looted: %s (ID: %d, iLvl: %d, Quality: %s) from %s [%s]",
    itemLink, itemID or 0, iLevel or 0,
    quality, sourceType or "Unknown", sourceID or "N/A"))
end
