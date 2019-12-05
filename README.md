# PlayervotesSFR
An updated version of the playervotes redux plugin by intox. The plugin allows players to cast votes for kick, ban, mute, gag, and silence options against other players. Unlike customvotes, this is meant to be a simple plugin with relatively fewer options, all of which are centered around administration. Original thread here: https://forums.alliedmods.net/showthread.php?t=217619

A few things to note:

- If you are looking for more robust/complex features (ie: adding your own vote items), please see the custom votes plugin here: https://forums.alliedmods.net/showthread.php?t=235115
- An alltalk vote will not be added to this plugin, but you can add it yourself by simply overridding the alltalk vote from funvotes.smx plugin (this requires no coding at all!). This will allow users the ability to use the !alltalk chat trigger to initiate a vote (much better than having to remove the funvotes plugin). More about overrides here: https://wiki.alliedmods.net/Overriding_Command_Access_(SourceMod)
- The plugin will automatically move the basevotes.smx plugin to the disabled folder and unload it, assuming it exists. If the plugin does not do this automatically, it is highly, HIGHLY recommended that you remove basevotes for this plugin for chat triggers to work!!!! If you use this plugin, you should not be using basevotes! 
- When checking if the plugin is loaded, look up the plugin version using sm_playersvotes_sfr_version or use sm plugins list to find the plugin. As an admin, sm_votemenu or using sm_admin menu will also bring up the voting menus.


# Changelog
2.5.0 Update (12-04-2019)
------------------------------------
- Updated all code for adminvotes.smx and playervotes.smx using the new syntax, updated version numbers, and made code more consistent in terms of style.
    * Caveat: Current code relies on the use of function calls from menus.inc (such as CreateMenu) instead of using the Menu classes/objects to create/build menus. 
- Added an admin menu for player votes so that sm_admin top menus can access the same menus that sm_votemenu command accesses. The menu is named Playervotes Admin.
- Added feature to automatically move the basevotes.smx to the plugin to the disabled folder. A log will be left in the sourcemod logs when this occurs. 
- Added a chat message that will appear when initiating a vote and no valid targets are available. This is sent only to the user attempting to initiate a vote.
- Updated the translation file for the addition of the Playervotes Admin menu.
- Compiled plugins for SM 1.10


2.1 Update (06-11-2018)
------------------------------------
- Compiled/Updated code for SM 1.8
- Minor updates to code for compatibility (no major changes still has all functions).


2.0 Initial Commit (09-01-2016)
------------------------------------
- Based on playervotes redux version by intox: https://forums.alliedmods.net/showthread.php?t=217619
- Plugin features all the original items (kick, ban, and mute).
- Additional features added (gag and silence).
- Removes votemap feature (map chooser plugins should take care of this).
- Accompanied is an optional plugin named adminvotes. This plugin will allow you to do the text/chat votes that the basevotes plugin allowed. This was created separately just in case admins wanted this.