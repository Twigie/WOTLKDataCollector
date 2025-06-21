-- Does the location already exist
local function LocationExists(locations, newLoc)
  for _, loc in ipairs(locations) do
    if LocationsEqual(loc, newLoc) then
      return true
    end
  end
  return false
end

-- Check if creature already exists in the DB
local function FindCreature(name, id)
  for _, creature in ipairs(CreatureTrackerDB) do
    if creature.creatureName == name and creature.creatureID == id then
      return creature
    end
  end
  return nil
end

-- Add creature if it doesn't exist
-- unitID is target, npc, mouseover etc..
function AddCreatureOrLocation(unitID)
  local x, y, zone, subzone, realZone = GetPlayerPosition()
  local id, guidType, name, creatureType, family, health, level, classification, faction = GetTargetDetails(unitID)
  local creature = FindCreature(name, id)
  local newLoc = { zone = zone, subzone = subzone, realZone = realZone, x = x, y = y }

  if not creature then
    -- New creature, add with initial location
    table.insert(CreatureTrackerDB, {
      creatureName = name,
      creatureID = id,
      creatureType = creatureType or "",
      creatureFamily = family or "",
      creatureMaxHealth = health or 0,
      creatureLevel = level or 0,
      creatureClassification = classification or "",
      creatureFaction = faction or "",
      locations = { newLoc }
    })
    DebugLog("Added new creature and location:", name, id, zone, subzone, x, y)
  else
    -- Creature exists, add location if new
    creature.locations = creature.locations or {}
    if not LocationExists(creature.locations, newLoc) then
      table.insert(creature.locations, newLoc)
      DebugLog("Added new location for creature:", name, id, zone, subzone, x, y)
    else
      DebugLog("Location already recorded for creature:", name, id)
    end
  end
  return id, guidType
end

