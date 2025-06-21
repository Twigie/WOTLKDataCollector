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

function AddCreatureFromInteraction()
    local x, y, zone, subzone, realZone = GetPlayerPosition()
    local targetID, _, targetName, targetCreatureType, targetFamily, targetHealth, targetLevel, targetClassification, targetFaction = GetTargetDetails("target")
    AddCreatureOrLocation(targetName, targetID, realZone, zone, subzone, x, y, targetCreatureType, targetFamily, targetHealth, targetLevel, targetClassification, targetFaction)
end

-- Add creature if it doesn't exist
function AddCreatureOrLocation(name, id, realZone, zone, subzone, x, y, type, family, health, level, targetClassification, targetFaction)
  local creature = FindCreature(name, id)
  local newLoc = { zone = zone, subzone = subzone, realZone = realZone, x = x, y = y }

  if not creature then
    -- New creature, add with initial location
    table.insert(CreatureTrackerDB, {
      creatureName = name,
      creatureID = id,
      creatureType = type or "",
      creatureFamily = family or "",
      creatureMaxHealth = health or 0,
      creatureLevel = level or 0,
      creatureClassification = targetClassification or "",
      creatureFaction = targetFaction or "",
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
end

