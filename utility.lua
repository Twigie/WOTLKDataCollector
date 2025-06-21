
-- Get the players position
function GetPlayerPosition()
  local zone = GetZoneText()
  local subzone = GetSubZoneText()
  local realZone = GetRealZoneText()
  SetMapToCurrentZone()
  local x, y = GetPlayerMapPosition("player")
  x = math.floor(x * 10000 + 0.5) / 100
  y = math.floor(y * 10000 + 0.5) / 100
  return x, y, zone, subzone, realZone
end

-- Locations Equal to each other using .01 tolerance
function LocationsEqual(loc1, loc2)
  return loc1.zone == loc2.zone
      and loc1.subzone == loc2.subzone
      and math.abs(loc1.x - loc2.x) < 0.50
      and math.abs(loc1.y - loc2.y) < 0.50
end

-- Extract type and ID from GUID
function ExtractGUIDInfo(guid)
  if not guid or type(guid) ~= "string" then return "Unknown", nil end
  local prefix = string.upper(string.sub(guid, 3, 5))
  local idHex = string.sub(guid, 6, 12)
  local id = tonumber(idHex, 16)
  local typeMap = {
    ["F13"] = "Creature",
    ["F15"] = "Creature",
    ["F11"] = "Chest",
    ["F12"] = "Chest",
    ["000"] = "Player",
  }
  return typeMap[prefix] or "Unknown", id
end

-- https://web.archive.org/web/20100726120812/http://wowprogramming.com/docs/api_types#unitID
function GetTargetDetails(unitID)
  if ExtractGUIDInfo(UnitGUID(unitID)) == "Creature" then
    local guidType ,id = ExtractGUIDInfo(UnitGUID(unitID))
    local name = UnitName(unitID)
    local type = UnitCreatureType(unitID)
    local family = UnitCreatureFamily(unitID)
    local health = UnitHealthMax(unitID)
    local level = UnitLevel(unitID)
    local classification = UnitClassification(unitID)
    local faction, _ =  UnitFactionGroup(unitID)
    return id, guidType, name, type, family, health, level, classification, faction
  end
end

function DebugLog(...)
  if DataCollectorDebugMode then
  print("|cffff0000DEBUG|r: ", ...)
  end
end

function PlayerLog(...)
  print("|cffff0000WDC|r: ", ...)
end
