local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("LOOT_OPENED")
frame:RegisterEvent("QUEST_COMPLETE")
frame:RegisterEvent("QUEST_ITEM_UPDATE")
frame:RegisterEvent("QUEST_ACCEPTED")
frame:RegisterEvent("QUEST_DETAIL")
frame:RegisterEvent("CHAT_MSG_LOOT")
frame:RegisterEvent("GOSSIP_SHOW")
frame:RegisterEvent("MERCHANT_SHOW")
frame:RegisterEvent("TAXIMAP_OPENED")
frame:RegisterEvent("BANKFRAME_OPENED")
frame:RegisterEvent("TRAINER_SHOW")

-- Reposition loot window to avoid blocking mouseover
hooksecurefunc("LootFrame_Show", function()
  LootFrame:ClearAllPoints()
  LootFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 50, -100)
end)

-- Event routing
frame:SetScript("OnEvent", function(self, event, msg)
  if event == "ADDON_LOADED" and msg == "WOTLKDataCollector" then
        ItemTrackerDB = ItemTrackerDB or {}
        CreatureTrackerDB = CreatureTrackerDB or {}
        QuestTrackerDB = QuestTrackerDB or {}
        DataCollectorDebugMode = DataCollectorDebugMode or false
        -- Add any other SavedVariables init here

        print("|cff3399ffWOTLK Data Collector|r |cff00ff00loaded.|r Type |cffffff00/wdc help|r for commands.")
        print("Data is saved to \\WTF\\Account\\USER\\"..GetRealmName().."\\"..GetUnitName("player").."\\SavedVariables\\WOTLKDataCollector.lua")
  end

  if event == "GOSSIP_SHOW" or event == "MERCHANT_SHOW" or event == "TAXIMAP_OPENED" or event == "BANKFRAME_OPENED" or event == "TRAINER_SHOW"then
    print(event)
    AddCreatureOrLocation("npc")
  end
  -- Listen for loot window opening
  if event == "LOOT_OPENED" then
    print(event)
    LootTracker_HandleLootOpened()
  -- Listen for others looting in chat window
  elseif event == "CHAT_MSG_LOOT" then
    LootTracker_HandleChatLoot(msg)
  -- Listen for Quest Start of finish so we can get quest,npc,item details
  elseif event == "QUEST_COMPLETE" or event == "QUEST_ITEM_UPDATE" or event == "QUEST_ACCEPTED" or event == "QUEST_DETAIL" then
    LootTracker_HandleQuestEvent(event)
  end
end)

-- Slash command: /ed
SLASH_WOTLKDATACOLLECTOR1 = "/wdc"
SlashCmdList["WOTLKDATACOLLECTOR"] = function(msg)
  msg = string.lower(msg or "")
  if msg == "clear" then
    ItemTrackerDB = {}
    CreatureTrackerDB = {}
    QuestTrackerDB = {}
    print("WOTLKDataCollector: log cleared.")
    return
  elseif msg == "help" then
    Dump_ShowHelp()
  elseif msg == "debug" then
    DataCollectorDebugMode = not DataCollectorDebugMode
    print("Debug Mode set to:","|cffa335ee"..tostring(DataCollectorDebugMode).."|r")
  elseif msg == "mem" then
    UpdateAddOnMemoryUsage()
    DebugLog("Addon is using: ",GetAddOnMemoryUsage("WOTLKDataCollector")/1024," megabytes")
  else
    Dump_ShowHelp()
  end
end

function Dump_ShowHelp()
  print("|cff00ff00WOTLKDataCollector Commands:|r")
  print("|cffffff00/wdc help|r - Show this help message.")
  print("|cffffff00/wdc clear|r - Clear the log.")
  print("|cffffff00/wdc debug|r - Toggle debug logging. Default is off")
  print("|cffffff00/wdc mem|r - Print addon memory usage in Kilobytes")
  -- Add more commands as needed
end
