local AceTimer = LibStub("AceTimer-3.0")

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

local function ProcessQuestRewards()
  local questTitle = GetTitleText()
    local questID, _, _, _, _ = GetQuestDetailsByTitle(questTitle)

    -- Guaranteed rewards
    local numRewards = GetNumQuestRewards()
    for i = 1, numRewards do
      local itemLink = GetQuestItemLink("reward", i)
      if itemLink then
        LootTracker_SaveLoot(itemLink, "QuestReward", questID)
      else
        PlayerLog("Cannot parse quest rewards please re-open the quest complete dialog.")
      end
    end

    -- Choice rewards (not filtered by what player chooses)
    local numChoices = GetNumQuestChoices()
    for i = 1, numChoices do
      local itemLink = GetQuestItemLink("choice", i)
      if itemLink then
        LootTracker_SaveLoot(itemLink, "QuestReward", questID)
      else
      PlayerLog("Cannot parse quest rewards please re-open the quest complete dialog.")
      end
    end
end



function AddQuest(questStatus, unitID)
  local x, y, zone, subzone, realZone = GetPlayerPosition()
  if questStatus == "Accepted" then
    local questText = GetQuestText()
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
        questDescription = questText or "",
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
    local questText = GetQuestText()
    local questObjective = GetObjectiveText()
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
        questDescription = questText or "",
      })
      DebugLog(string.format("[Quest: %s] QuestID: %s Added to Log: from %s", questName, questID, unitID))
    else
      FindQuest(questName, questID)["questEndNPC"] = unitID
      DebugLog("Quest already logged")
    end
  end
end

LastUnitDialogID = 0
function LootTracker_HandleQuestEvent(event)
  if UnitExists("npc") then
    _, LastUnitDialogID = ExtractGUIDInfo(UnitGUID("npc"))
  end
  if event == "QUEST_DETAIL" then
    if UnitExists("npc") then
      AddCreatureOrLocation("npc")
    end
  end
  if event == "QUEST_COMPLETE" then
    local unitID = AddCreatureOrLocation("npc")
    AddQuest("Completed", unitID)
    -- If the quest has rewards then wait 1 sec and log the loot, this is so that the uncached data can be retrieved
    if not (GetNumQuestChoices() == 0 and GetNumQuestRewards() == 0) then
      AceTimer:ScheduleTimer(ProcessQuestRewards, 0.5)
    end
  -- QuestID not available until the quest is accepted: Below will not work
  -- elseif event == "QUEST_ITEM_UPDATE" then

  elseif event == "QUEST_ACCEPTED" then
    AddQuest("Accepted", LastUnitDialogID)
    -- elseif event == "QUEST_DETAIL" then
    --   AddQuest("Details", unitID)
  end
end
