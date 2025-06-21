local function GetQuestDetailsByTitle(titleToFind)
  for i = 1, GetNumQuestLogEntries() do
    local title, level, questTag, suggestedGroup, _, _, _, isDaily, questID = GetQuestLogTitle(i)
    if title == titleToFind then
      return questID, level, questTag, suggestedGroup, isDaily
    end
  end
  return nil
end

local function FindQuest(name, id)
  if name and id then
    for _, quest in ipairs(QuestTrackerDB) do
      if quest.questName == name and quest.questID == id then
        return quest
      end
    end
    return nil
  elseif name and not id then
    for _, quest in ipairs(QuestTrackerDB) do
      if quest.questName == name then
        return quest
      end
    end
    return nil
  end
end

function AddQuest(questStatus, unitID)
  local x, y, zone, subzone, realZone = GetPlayerPosition()
  if questStatus == "Accepted" then
    local questObjective = GetObjectiveText()
    local questXP = GetRewardXP()
    local questReward = GetRewardMoney()
    local questName = GetTitleText()
    local questID, level, questTag, suggestedGroup, isDaily = GetQuestDetailsByTitle(questName)
    if not FindQuest(questName, questID) then
      table.insert(QuestTrackerDB, {
        questName = questName,
        questZone = zone,
        questRealZone = realZone,
        questSubZone = subzone,
        questStartNPC = unitID or 0,
        questEndNPC = 0,
        questRewardXP = questXP or 0,
        questRewardMoney = questReward or 0,
        questObjective = questObjective or "",
        questLevel = level or 0,
        questTag = questTag or "standard",
        questGroup = suggestedGroup or 0,
        questDaily = isDaily or 0,
        questID = questID or 0,
      })
      DebugLog(string.format("[Quest: %s] QuestID: %s Added to Log: from: %s", questName, questID, unitID))
    else
      local foundQuest = FindQuest(questName, questID)
      foundQuest["questID"] = questID or 0
      foundQuest["questLevel"] = level or 0
      foundQuest["questTag"] = questTag or ""
      foundQuest["questGroup"] = suggestedGroup or 0
      foundQuest["questDaily"] = isDaily or 0
      DebugLog("Quest already logged")
    end
  elseif questStatus == "Completed" then
    local rewardXP = GetRewardXP()
    local rewardMoney = GetRewardMoney()
    local questName = GetTitleText()
    local questID, level, questTag, suggestedGroup, isDaily = GetQuestDetailsByTitle(questName)
    if not FindQuest(questName, questID) then
      table.insert(QuestTrackerDB, {
        questName = questName,
        questZone = zone,
        questRealZone = realZone,
        questSubZone = subzone,
        questStartNPC = 0,
        questEndNPC = unitID,
        questID = questID,
        questLevel = level,
        questTag = questTag or "standard",
        questGroup = suggestedGroup or "",
        questDaily = isDaily or 0,
        questRewardXP = rewardXP or 0,
        questRewardMoney = rewardMoney or 0,
        questObjective = questObjective or "",
      })
      DebugLog(string.format("[Quest: %s] QuestID: %s Added to Log: from %s", questName, questID, unitID))
    else
      FindQuest(questName, questID)["questEndNPC"] = unitID
      DebugLog("Quest already logged")
    end
  end
end

local lastDialogNPC
function LootTracker_HandleQuestEvent(event)
  print(event)
  local x, y, zone, subzone, realZone = GetPlayerPosition()

  if event == "QUEST_DETAIL" then
    if UnitExists("npc") then
      _, lastDialogNPC = ExtractGUIDInfo(UnitGUID("npc"))
      print(lastDialogNPC)
      local targetID, _, targetName, targetCreatureType, targetFamily, targetHealth, targetLevel, targetClassification, targetFaction =
      GetTargetDetails("target")
      AddCreatureOrLocation(targetName, targetID, realZone, zone, subzone, x, y, targetCreatureType, targetFamily,
        targetHealth, targetLevel, targetClassification, targetFaction)
    else
      lastDialogNPC = 0
    end
  end
  if event == "QUEST_COMPLETE" then
    local _, unitID = ExtractGUIDInfo(UnitGUID("npc"))
    AddQuest("Completed", unitID)
    local questTitle = GetTitleText()
    local questID, _, _, _, _ = GetQuestDetailsByTitle(questTitle)

    -- Guaranteed rewards
    local numRewards = GetNumQuestRewards()
    for i = 1, numRewards do
      local itemLink = GetQuestItemLink("reward", i)
      if itemLink then
        LootTracker_SaveLoot(itemLink, "QuestReward", questID)
      end
    end

    -- Choice rewards (not filtered by what player chooses)
    local numChoices = GetNumQuestChoices()
    for i = 1, numChoices do
      local itemLink = GetQuestItemLink("choice", i)
      if itemLink then
        LootTracker_SaveLoot(itemLink, "QuestChoice", questID)
      end
    end
  elseif event == "QUEST_ITEM_UPDATE" then
    local questTitle = GetTitleText()
    local questID, _, _, _, _ = GetQuestDetailsByTitle(questTitle)
    local numRewards = GetNumQuestRewards()
    for i = 1, numRewards do
      local itemLink = GetQuestItemLink("reward", i)
      if itemLink then
        LootTracker_SaveLoot(itemLink, "QuestReward", questID)
      end
    end

    -- Choice rewards (not filtered by what player chooses)
    local numChoices = GetNumQuestChoices()
    for i = 1, numChoices do
      local itemLink = GetQuestItemLink("choice", i)
      if itemLink then
        LootTracker_SaveLoot(itemLink, "QuestChoice", questID)
      end
    end
  elseif event == "QUEST_ACCEPTED" then
    AddQuest("Accepted", lastDialogNPC)
    -- elseif event == "QUEST_DETAIL" then
    --   AddQuest("Details", unitID)
  end
end
