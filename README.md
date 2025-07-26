# WOTLKDataCollector
A 3.3.5 addon that tracks items, npcs, and quests where the server database is not available so this information has to be gathered by the player.

Originally created to gather data from the private server [ProjectEpoch](https://www.project-epoch.net/), this addon can work on other 3.3.5 servers.

Data is saved as lua tables in the addons saved variables: ItemTrackerDB CreatureTrackerDB QuestTrackerDB

# Installation

   1. Download Latest Version
   2. Unpack the Zip file
   3. Rename the folder to "WOTLKDataCollector"
   4. Copy "WOTLKDataCollector" into Wow-Directory\Interface\AddOns
   5. Reload/relaunch wow
# Project-Epoch Users
If you are using this addon for Project-Epoch please send your WOTLKDataCollector.lua file to @twigie via discord
Example Path: \Documents\WorldOfWarcraft\Epoch\WTF\Account\TWIGIE\Kezan\Xela\SavedVariables\WOTLKDataCollector.lua

Disable any quest automation as it needs time to cache the rewards for them to be scanned.

# Current Capabilities
Saves creature data on the following events:
GOSSIP_SHOW, MERCHANT_SHOW, TAXIMAP_OPENED, BANKFRAME_OPENED, TRAINER_SHOW, QUEST_DETAIL

Saves item data on the following events:
LOOT_OPENED, CHAT_MSG_LOOT, QUEST_COMPLETE

Saves quest data on the following events:
QUEST_COMPLETE,  QUEST_ACCEPTED, QUEST_DETAIL, QUEST_ITEM_UPDATE

# Usage
 ```
  /wdc help - Show this help message.
  /wdc clear - Clear the log.
  /wdc debug - Toggle debug logging. Default is off
  /wdc mem - Print addon memory usage in Kilobytes
  ```
# Disclaimer

Some info is not exposed to the client by the server or is resticted by the addon API and not available for collection.

This addon is a work in progress bugs will occur

Use [BugGrabber](https://www.curseforge.com/wow/addons/bug-grabber/files/all?page=1&pageSize=20&version=3.3.5) and [BugSack](https://www.curseforge.com/wow/addons/bugsack/files/all?page=1&pageSize=20&version=3.3.5) to report any issues
