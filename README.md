# WOTLKDataCollector
A 3.3.5 addon that tracks items, npcs, and quests where the server database is not available so this information has to be gathered by the player.

Originally created to gather data from the private server [ProjectEpoch](https://www.project-epoch.net/), this addon can work on other 3.3.5 servers.

Data is saved as lua tables in the addons saved variables: ItemTrackerDB CreatureTrackerDB QuestTrackerDB
WoWInstallPath\WTF\Account\Username\SavedVariables

# Installation

   1. Download Latest Version
   2. Unpack the Zip file
   3. Rename the folder to "WOTLKDataCollector"
   4. Copy "WOTLKDataCollector" into Wow-Directory\Interface\AddOns
   5. Reload/relaunch wow

# Current Capabilities
Saves creature data on the following events:
GOSSIP_SHOW, MERCHANT_SHOW, TAXIMAP_OPENED, BANKFRAME_OPENED, TRAINER_SHOW, QUEST_DETAIL

Saves item info on the following events:
LOOT_OPENED, CHAT_MSG_LOOT, QUEST_COMPLETE

Saves quest info on the following events:
QUEST_COMPLETE,  QUEST_ACCEPTED, QUEST_DETAIL, QUEST_ITEM_UPDATE


# Disclaimer

Some info is not exposed to the client by the server or is resticted by the addon API and not available for collection.
