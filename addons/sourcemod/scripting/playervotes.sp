/*************************************************************************
*************************************************************************
This plugin is free software: you can redistribute 
it and/or modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of the License, or
later version. 

This plugin is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this plugin.  If not, see <http://www.gnu.org/licenses/>.
*************************************************************************
*************************************************************************/ 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <basecomm>
#include <adminmenu>

#pragma newdecls required

#define PLUGIN_VERSION "2.5.0"
#define STEAM_NAME_LENGTH 33
#define MENU_SBUFFER_LENGTH 56
#define MENU_VOTE_REASON 33

/////////////////////////////////////////
//=====[ HANDLES | CVARS ]=============//
/////////////////////////////////////////

/*********************
**       MUTE       **
**********************/
Handle g_hArrayVoteMuteClientIdentity = INVALID_HANDLE;

/*********************
**       GAG        **
**********************/
Handle g_hArrayVoteGagClientIdentity = INVALID_HANDLE;

/*********************
**     SILENCE      **
**********************/
Handle g_hArrayVoteSilenceClientIdentity = INVALID_HANDLE;

/*********************
**       BAN        **
**********************/
ConVar g_hCvarVoteBanSB = null;
Handle g_hArrayVoteBanClientUserIds = INVALID_HANDLE;
Handle g_hArrayVoteBanClientCurrentUserId = INVALID_HANDLE;
Handle g_hArrayVoteBanClientIdentity = INVALID_HANDLE;
Handle g_hArrayVoteBanClientNames = INVALID_HANDLE;
Handle g_hArrayVoteBanClientTeam = INVALID_HANDLE;
Handle g_hArrayVoteBanReasons = INVALID_HANDLE;
Handle g_hArrayVoteBanFor[MAXPLAYERS + 1] = INVALID_HANDLE;
Handle g_hArrayVoteBanForReason[MAXPLAYERS + 1] = INVALID_HANDLE;

///////////////////////////////////
//=====[ VARIABLES ]=============//
///////////////////////////////////
int g_iStartTime;
bool g_bImmune[MAXPLAYERS + 1];
char g_strConfigFile[PLATFORM_MAX_PATH];
bool g_bChatTriggers;
int g_iVoteImmunity;
Handle g_hAdminMenu = INVALID_HANDLE;

/*********************
**      KICK        **
**********************/
bool g_bVoteKickEnabled;
float g_flVoteKickRatio;
int g_iVoteKickMinimum;
int g_iVoteKickDelay;
int g_iVoteKickLimit;
int g_iVoteKickLast[MAXPLAYERS + 1];
int g_iVoteKickInterval;
bool g_bVoteKickTeam;
int g_iVoteKickCount[MAXPLAYERS + 1];
bool g_bVoteKickFor[MAXPLAYERS + 1][MAXPLAYERS + 1];

/*********************
**       BAN        **
**********************/
bool g_bVoteBanEnabled;
float g_flVoteBanRatio;
int g_iVoteBanMinimum;
int g_iVoteBanDelay;
int g_iVoteBanLimit;
int g_iVoteBanInterval;
int g_iVoteBanLast[MAXPLAYERS + 1];
bool g_bVoteBanTeam;
int g_iVoteBanTime;
char g_strVoteBanReasons[PLATFORM_MAX_PATH];
int g_iVoteBanCount[MAXPLAYERS + 1];
int g_iVoteBanClients[MAXPLAYERS + 1] = {-1, ...};

/*********************
**      MUTE        **
**********************/
bool g_bVoteMuteEnabled;
float g_flVoteMuteRatio;
int g_iVoteMuteMinimum;
int g_iVoteMuteDelay;
int g_iVoteMuteLimit;
int g_iVoteMuteInterval;
int g_iVoteMuteLast[MAXPLAYERS + 1];
bool g_bVoteMuteTeam;
int g_iVoteMuteCount[MAXPLAYERS + 1];
bool g_bVoteMuteFor[MAXPLAYERS + 1][MAXPLAYERS + 1];
bool g_bVoteMuteMuted[MAXPLAYERS + 1];

/*********************
**       GAG        **
**********************/
bool g_bVoteGagEnabled;
float g_flVoteGagRatio;
int g_iVoteGagMinimum;
int g_iVoteGagDelay;
int g_iVoteGagLimit;
int g_iVoteGagInterval;
int g_iVoteGagLast[MAXPLAYERS + 1];
bool g_bVoteGagTeam;
int g_iVoteGagCount[MAXPLAYERS + 1];
bool g_bVoteGagFor[MAXPLAYERS + 1][MAXPLAYERS + 1];
bool g_bVoteGagGagged[MAXPLAYERS + 1];

/*********************
**     SILENCE      **
**********************/
bool g_bVoteSilenceEnabled;
float g_flVoteSilenceRatio;
int g_iVoteSilenceMinimum;
int g_iVoteSilenceDelay;
int g_iVoteSilenceLimit;
int g_iVoteSilenceInterval;
int g_iVoteSilenceLast[MAXPLAYERS + 1];
bool g_bVoteSilenceTeam;
int g_iVoteSilenceCount[MAXPLAYERS + 1];
bool g_bVoteSilenceFor[MAXPLAYERS + 1][MAXPLAYERS + 1];
bool g_bVoteSilenceSilenced[MAXPLAYERS + 1];

///////////////////////////////////
//=====[ PLUGIN INFO ]===========//
///////////////////////////////////
public Plugin myinfo =
{
    name = "Player Votes SFR",
    author = "Mr.Silence",
    description = "Simple player vote options for kick, ban, mute, gag, and silence.",
    version = PLUGIN_VERSION,
    url = "https://github.com/Silenci0/PlayervotesSFR"
}

///////////////////////////////////
//=====[ EVENTS ]================//
///////////////////////////////////
public void OnPluginStart()
{
    // Player votes commands 
    LoadTranslations("playersvotes.phrases");

    CreateConVar("sm_playersvotes_sfr_version", PLUGIN_VERSION, "Players Votes SFR Version", FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);

    BuildPath(Path_SM, g_strConfigFile, sizeof(g_strConfigFile), "configs/playersvotes.cfg");

    RegAdminCmd("sm_votemenu", Command_ChooseVote, 0, "Open voting menu");
    RegAdminCmd("sm_playersvotes_reload", Command_Reload, ADMFLAG_ROOT, "Reload playersvotes config");

    // Create the user arrays for usernames and IDs for each vote type
    if(g_hArrayVoteBanClientUserIds == INVALID_HANDLE)
    {
        g_hArrayVoteBanClientUserIds = CreateArray();
    }

    if(g_hArrayVoteBanClientCurrentUserId == INVALID_HANDLE)
    {
        g_hArrayVoteBanClientCurrentUserId = CreateArray();
    }

    if(g_hArrayVoteBanClientTeam == INVALID_HANDLE)
    {
        g_hArrayVoteBanClientTeam = CreateArray();
    }

    if(g_hArrayVoteBanClientIdentity == INVALID_HANDLE)
    {
        g_hArrayVoteBanClientIdentity = CreateArray(STEAM_NAME_LENGTH);
    }

    if(g_hArrayVoteBanClientNames == INVALID_HANDLE)
    {
        g_hArrayVoteBanClientNames = CreateArray(STEAM_NAME_LENGTH);
    }

    if(g_hArrayVoteBanReasons == INVALID_HANDLE)
    {
        g_hArrayVoteBanReasons = CreateArray(STEAM_NAME_LENGTH);
    }

    if(g_hArrayVoteMuteClientIdentity == INVALID_HANDLE)
    {
        g_hArrayVoteMuteClientIdentity = CreateArray(STEAM_NAME_LENGTH);
    }

    if(g_hArrayVoteGagClientIdentity == INVALID_HANDLE)
    {
        g_hArrayVoteGagClientIdentity = CreateArray(STEAM_NAME_LENGTH);
    }

    if(g_hArrayVoteSilenceClientIdentity == INVALID_HANDLE)
    {
        g_hArrayVoteSilenceClientIdentity = CreateArray(STEAM_NAME_LENGTH);
    }

    // Ban reason and ban votes
    for(int i = 0; i <= MAXPLAYERS; ++i)
    {
        if(g_hArrayVoteBanFor[i] == INVALID_HANDLE)
        {
            g_hArrayVoteBanFor[i] = CreateArray();
        }
        
        if(g_hArrayVoteBanForReason[i] == INVALID_HANDLE)
        {
            g_hArrayVoteBanForReason[i] = CreateArray();
        }
    }
    
    // Manually fire AdminMenu callback.
    TopMenu topmenu;
    if ((topmenu = GetAdminTopMenu()) != null)
    {
        OnAdminMenuReady(topmenu);
    }
}

public void OnConfigsExecuted()
{
    // Loading the file configs/playervotes.cfg
    Config_Load();
    
    // Move basevotes out if it is currently loaded as it conflicts with this plugin
    char filename[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, filename, sizeof(filename), "plugins/basevotes.smx");
    if (FileExists(filename))
    {
        char newfilename[PLATFORM_MAX_PATH];
        BuildPath(Path_SM, newfilename, sizeof(newfilename), "plugins/disabled/basevotes.smx");
        ServerCommand("sm plugins unload basevotes");
        if (FileExists(newfilename))
        {
            DeleteFile(newfilename);
        }
        RenameFile(newfilename, filename);
        LogMessage("File plugins/basevotes.smx was unloaded and moved to plugins/disabled/basevotes.smx");
    }
}

public void OnMapStart()
{
    // Get map start time
    g_iStartTime = GetTime();

    // Find Sourcebans
    g_hCvarVoteBanSB = FindConVar("sb_version");

    // Reset all votes and their counters
    PlayersVotes_ResetKickVotes();
    PlayersVotes_ResetBanVotes();
    PlayersVotes_ResetMuteVotes();
    PlayersVotes_ResetGagVotes();
    PlayersVotes_ResetSilenceVotes();

    for(int i = 0; i <= MAXPLAYERS; ++i)
    {
        g_iVoteKickCount[i] = 0;
        g_iVoteBanCount[i] = 0;
        g_iVoteMuteCount[i] = 0;
        g_iVoteBanClients[i] = -1;
        g_bVoteMuteMuted[i] = false;
        g_bVoteGagGagged[i] = false;
        g_bVoteSilenceSilenced[i] = false;
    }

    // Clears away all player data from the comms (voice/chat) arrays, including users
    // who were muted/gagged upon map change.
    ClearArray(g_hArrayVoteMuteClientIdentity);
    ClearArray(g_hArrayVoteGagClientIdentity);
    ClearArray(g_hArrayVoteSilenceClientIdentity);
}

//Sets up the admin menu when it is ready to be set up.
public void OnAdminMenuReady(Handle topmenu)
{
    //Block this from being called twice
    if (topmenu == g_hAdminMenu)
    {
        return;
    }
    
    //Setup menu...
    g_hAdminMenu = topmenu;
    
    TopMenuObject pvs_menu = AddToTopMenu(
        g_hAdminMenu, "Playervotes Admin", TopMenuObject_Category,
        PVSAdmin_CatHandler, INVALID_TOPMENUOBJECT
    );
    
    AddToTopMenu(
        g_hAdminMenu, "pvs_votemenu", TopMenuObject_Item, Menu_PVSVoteAdmin,
        pvs_menu, "pvs_votemenu", ADMFLAG_GENERIC
    );
}

//Handles the Admin menu category for Playervotes
public void PVSAdmin_CatHandler(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
    if (action == TopMenuAction_DisplayTitle || action == TopMenuAction_DisplayOption)
    {
        strcopy(buffer, maxlength, "Playervotes Admin");
    }
}

//Handles the Change Map option in the menu.
public void Menu_PVSVoteAdmin(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int client, char[] buffer, int maxlength)
{
    if (action == TopMenuAction_DisplayOption)
    {
        FormatEx(buffer, maxlength, "%T", "Menus and Options", client);
    }
    else if (action == TopMenuAction_SelectOption)
    {
        Menu_ChooseVote(client);
    }
}

public void OnClientDisconnect(int iClient)
{
    // For all non-bot players, we need to reset any counters, booleans, or values 
    if(!IsFakeClient(iClient))
    {
        // Immunity and Count/Last counters.
        g_bImmune[iClient] = false;
        g_iVoteKickLast[iClient] = 0;
        g_iVoteBanLast[iClient] = 0;
        g_iVoteMuteLast[iClient] = 0;
        g_iVoteGagLast[iClient] = 0;
        g_iVoteSilenceLast[iClient] = 0;
        g_iVoteKickCount[iClient] = 0;
        g_iVoteBanCount[iClient] = 0;
        g_iVoteMuteCount[iClient] = 0;
        g_iVoteGagCount[iClient] = 0;
        g_iVoteSilenceCount[iClient] = 0;
        g_iVoteBanClients[iClient] = -1;

        // Set everything users to false
        for(int i = 0; i <= MAXPLAYERS; i++)
        {
            g_bVoteKickFor[iClient][i] = false;
            g_bVoteKickFor[i][iClient] = false;
            g_bVoteMuteFor[iClient][i] = false;
            g_bVoteMuteFor[i][iClient] = false;
            g_bVoteGagFor[iClient][i] = false;
            g_bVoteGagFor[i][iClient] = false;
            g_bVoteSilenceFor[iClient][i] = false;
            g_bVoteSilenceFor[i][iClient] = false;
        }

        // If the user that disconnects does not have bans on them, we will remove them from the vote menu. 
        // But if someone was voting to ban them and they leave, we will keep their vote count on there so 
        // that they cannot evade it.
        int iBanVotes = GetArraySize(g_hArrayVoteBanFor[iClient]);
        for(int i = 0; i < iBanVotes; ++i)
        {
            int iTarget = GetArrayCell(g_hArrayVoteBanFor[iClient], i);
            if(PlayersVotes_GetBanVotesForTarget(iTarget) == 1)
            {
                PlayersVotes_RemoveBanVotesFromTarget(iTarget);
                --i;
                --iBanVotes;
            }
        }

        ClearArray(g_hArrayVoteBanFor[iClient]);
        ClearArray(g_hArrayVoteBanForReason[iClient]);

        // If muted by vote, remove the mute on the user.
        if(g_bVoteMuteMuted[iClient] && !BaseComm_IsClientMuted(iClient))
        {
            char strClientAuth[STEAM_NAME_LENGTH];
            PlayersVotes_GetIdentity(iClient, strClientAuth, sizeof(strClientAuth));

            int iRemoveMuteIndex = PlayersVotes_MatchIdentity(g_hArrayVoteMuteClientIdentity, strClientAuth);
            if(iRemoveMuteIndex != -1)
            {
                RemoveFromArray(g_hArrayVoteMuteClientIdentity, iRemoveMuteIndex);
            }
        }
        // If gagged by vote, remove the gag on the user.
        if(g_bVoteGagGagged[iClient] && !BaseComm_IsClientGagged(iClient))
        {
            char strClientAuth[STEAM_NAME_LENGTH];
            PlayersVotes_GetIdentity(iClient, strClientAuth, sizeof(strClientAuth));

            int iRemoveGagIndex = PlayersVotes_MatchIdentity(g_hArrayVoteGagClientIdentity, strClientAuth);
            if(iRemoveGagIndex != -1)
            {
                RemoveFromArray(g_hArrayVoteGagClientIdentity, iRemoveGagIndex);
            }
        }
        // If silenced by vote, remove the silence (mute + gag) status from the user.
        if(g_bVoteSilenceSilenced[iClient] && !BaseComm_IsClientMuted(iClient) && !BaseComm_IsClientGagged(iClient))
        {
            char strClientAuth[STEAM_NAME_LENGTH];
            PlayersVotes_GetIdentity(iClient, strClientAuth, sizeof(strClientAuth));

            int iRemoveSilenceIndex = PlayersVotes_MatchIdentity(g_hArrayVoteSilenceClientIdentity, strClientAuth);
            if(iRemoveSilenceIndex != -1)
            {
                RemoveFromArray(g_hArrayVoteSilenceClientIdentity, iRemoveSilenceIndex);
            }
        }

        g_bVoteMuteMuted[iClient] = false;
        g_bVoteGagGagged[iClient] = false;
        g_bVoteSilenceSilenced[iClient] = false;
    }
}

public void OnClientConnected(int iClient)
{
    if(!IsFakeClient(iClient))
    {
        char strIp[STEAM_NAME_LENGTH];
        GetClientIP(iClient, strIp, sizeof(strIp));

        g_iVoteBanClients[iClient] = PlayersVotes_MatchIdentity(g_hArrayVoteBanClientIdentity, strIp);

        if(PlayersVotes_MatchIdentity(g_hArrayVoteMuteClientIdentity, strIp) != -1)
        {  
            g_bVoteMuteMuted[iClient] = true;
        }

        if(PlayersVotes_MatchIdentity(g_hArrayVoteGagClientIdentity, strIp) != -1)
        {
            g_bVoteGagGagged[iClient] = true;
        }

        if(PlayersVotes_MatchIdentity(g_hArrayVoteSilenceClientIdentity, strIp) != -1)
        {
            g_bVoteSilenceSilenced[iClient] = true;
        }

        int iBanTarget = g_iVoteBanClients[iClient];
        if(iBanTarget != -1)
        {
            char strClientName[STEAM_NAME_LENGTH];
            GetClientName(iClient, strClientName, sizeof(strClientName));

            char strStoredName[STEAM_NAME_LENGTH];
            GetArrayString(g_hArrayVoteBanClientNames, iBanTarget, strStoredName, sizeof(strStoredName));

            if(!StrEqual(strClientName, strStoredName))
            {
                PrintToChatAll("[SM] Bans: %s changed name to %s!", strStoredName, strClientName);
                SetArrayString(g_hArrayVoteBanClientNames, iBanTarget, strClientName);
            }

            SetArrayCell(g_hArrayVoteBanClientCurrentUserId, iBanTarget, GetClientUserId(iClient));
        }
    }
}

public void OnClientAuthorized(int iClient, const char[] strAuth)
{
    if(!IsFakeClient(iClient))
    {
        if(PlayersVotes_MatchIdentity(g_hArrayVoteMuteClientIdentity, strAuth) != -1)
        {
            g_bVoteMuteMuted[iClient] = true;
        }

        if(PlayersVotes_MatchIdentity(g_hArrayVoteGagClientIdentity, strAuth) != -1)
        {
            g_bVoteGagGagged[iClient] = true;
        }

        if(PlayersVotes_MatchIdentity(g_hArrayVoteSilenceClientIdentity, strAuth) != -1)
        {
            g_bVoteSilenceSilenced[iClient] = true;
        }

        int iBanTarget = g_iVoteBanClients[iClient];
        if(iBanTarget != -1)
        {
            if(PlayersVotes_IsValidAuth(strAuth))
            {
                SetArrayString(g_hArrayVoteBanClientIdentity, iBanTarget, strAuth);
            }
        }
        else
        {
            g_iVoteBanClients[iClient] = PlayersVotes_MatchIdentity(g_hArrayVoteBanClientIdentity, strAuth);
            iBanTarget = g_iVoteBanClients[iClient];
        }

        if(iBanTarget != -1)
        {
            char strClientName[STEAM_NAME_LENGTH];
            GetClientName(iClient, strClientName, sizeof(strClientName));

            char strStoredName[STEAM_NAME_LENGTH];
            GetArrayString(g_hArrayVoteBanClientNames, iBanTarget, strStoredName, sizeof(strStoredName));

            if(!StrEqual(strClientName, strStoredName))
            {
                PrintToChatAll("[SM] Bans: %s changed name to %s!", strStoredName, strClientName);
                SetArrayString(g_hArrayVoteBanClientNames, iBanTarget, strClientName);
            }

            SetArrayCell(g_hArrayVoteBanClientCurrentUserId, iBanTarget, GetClientUserId(iClient));
        }
    }
}

public void OnClientPostAdminCheck(int iClient)
{
    if(!IsFakeClient(iClient))
    {
        if(g_bVoteMuteMuted[iClient])
        {
            PlayersVotes_MutePlayer(iClient);
        }

        if(g_bVoteGagGagged[iClient])
        {
            PlayersVotes_GagPlayer(iClient);
        }

        if(g_bVoteSilenceSilenced[iClient])
        {
            PlayersVotes_SilencePlayer(iClient);
        }

        if(g_iVoteImmunity > -1)
        {
            AdminId idTargetAdmin = GetUserAdmin(iClient);
            if(idTargetAdmin != INVALID_ADMIN_ID || CheckCommandAccess(iClient, "playersvotes_immunity", ADMFLAG_GENERIC))
            {
                if(GetAdminImmunityLevel(idTargetAdmin) >= g_iVoteImmunity)
                {
                    g_bImmune[iClient] = true;
                }
            }
        }
    }
}

///////////////////////////////////
//===============================//
//=====[ COMMANDS ]==============//
//===============================//
///////////////////////////////////
public Action Command_ChooseVote(int iClient, int iArgs)
{
    if(!IsValidClient(iClient) || IsFakeClient(iClient))
    {
        return Plugin_Continue;
    }

    Menu_ChooseVote(iClient);
    return Plugin_Handled;
}

public Action Command_Reload(int iClient, int iArgs)
{
    Config_Load();
    ReplyToCommand(iClient, "[SM] Config 'playersvotes.cfg' reloaded");
    return Plugin_Handled;
}

public Action OnClientSayCommand(int iClient, const char[] strCommand, const char[] sArgs)
{
    if(!IsValidClient(iClient) || !g_bChatTriggers || IsFakeClient(iClient))
    {
        return Plugin_Continue;
    }

    char strText[PLATFORM_MAX_PATH];
    strcopy(strText, sizeof(strText), sArgs);
    StripQuotes(strText);

    ReplaceString(strText, sizeof(strText), "!", "");
    ReplaceString(strText, sizeof(strText), "/", "");

    if(StrEqual(strText, "votekick", false))
    {
        Menu_DisplayKickVote(iClient);
    }
    else if(StrEqual(strText, "voteban", false))
    {
        Menu_DisplayBanVote(iClient);
    }
    else if(StrEqual(strText, "votemute", false))
    {
        Menu_DisplayMuteVote(iClient);
    }
    else if(StrEqual(strText, "votegag", false))
    {
        Menu_DisplayGagVote(iClient);   
    }
    else if(StrEqual(strText, "votesilence", false))
    {
        Menu_DisplaySilenceVote(iClient);
    }

    return Plugin_Continue;
}

///////////////////////////////////
//===============================//
//=====[ MENUS ]=================//
//===============================//
///////////////////////////////////
public void Menu_ChooseVote(int iClient)
{
    bool bCanceling = CheckCommandAccess(iClient, "playersvotes_canceling", ADMFLAG_GENERIC);
    if(!bCanceling && !g_bVoteKickEnabled && !g_bVoteBanEnabled && !g_bVoteMuteEnabled && !g_bVoteGagEnabled && !g_bVoteSilenceEnabled)
    {
        PrintToChat(iClient, "[SM] %t.", "all disabled votes");
        return;
    }

    Menu hMenu = CreateMenu(MenuHandler_ChooseVote);
    SetMenuTitle(hMenu, "%t:", "Voting Menu");

    char strBuffer[MENU_SBUFFER_LENGTH];
    if(g_bVoteKickEnabled && CheckCommandAccess(iClient, "playersvotes_kick", 0))
    {
        Format(strBuffer, sizeof(strBuffer), "%t", "Kick");
        AddMenuItem(hMenu, "Kick", strBuffer);
    }

    if(g_bVoteBanEnabled && CheckCommandAccess(iClient, "playersvotes_ban", 0))
    {
        Format(strBuffer, sizeof(strBuffer), "%t", "Ban");
        AddMenuItem(hMenu, "Ban", strBuffer);
    }

    if(g_bVoteMuteEnabled && CheckCommandAccess(iClient, "playersvotes_mute", 0))
    {
        Format(strBuffer, sizeof(strBuffer), "%t", "Mute");
        AddMenuItem(hMenu, "Mute", strBuffer);
    }

    if(g_bVoteGagEnabled && CheckCommandAccess(iClient, "playersvotes_gag", 0))
    {
        Format(strBuffer, sizeof(strBuffer), "%t", "Gag");
        AddMenuItem(hMenu, "Gag", strBuffer);
    }

    if(g_bVoteSilenceEnabled && CheckCommandAccess(iClient, "playersvotes_silence", 0))
    {
        Format(strBuffer, sizeof(strBuffer), "%t", "Silence");
        AddMenuItem(hMenu, "Silence", strBuffer);
    }

    if(bCanceling)
    {
        Format(strBuffer, sizeof(strBuffer), "%t", "Settings");
        AddMenuItem(hMenu, "Settings", strBuffer);
    }

    DisplayMenu(hMenu, iClient, 30);
}

public int MenuHandler_ChooseVote(Menu hMenu, MenuAction iAction, int iParam1, int iParam2)
{
    if(iAction == MenuAction_End)
    {
        CloseHandle(hMenu);
        return;
    }

    if(iAction == MenuAction_Select)
    {
        char strInfo[16];
        GetMenuItem(hMenu, iParam2, strInfo, sizeof(strInfo));

        if(StrEqual(strInfo, "Kick"))
        {
            Menu_DisplayKickVote(iParam1);
        }
        else if(StrEqual(strInfo, "Ban"))
        {
            Menu_DisplayBanVote(iParam1);
        }
        if(StrEqual(strInfo, "Mute"))
        {
            Menu_DisplayMuteVote(iParam1);
        }
        if(StrEqual(strInfo, "Gag"))
        {
            Menu_DisplayGagVote(iParam1);
        }
        if(StrEqual(strInfo, "Silence"))
        {
            Menu_DisplaySilenceVote(iParam1);    
        }
        if(StrEqual(strInfo, "Settings"))
        {
            Menu_Settings(iParam1);
        }
    }
}

public void Menu_Settings(int iClient)
{
    Menu hMenu = CreateMenu(MenuHandler_Settings);

    SetMenuTitle(hMenu, "%t:", "Settings");
    SetMenuExitBackButton(hMenu, true);

    char strBuffer[MENU_SBUFFER_LENGTH];
    if(CheckCommandAccess(iClient, "playersvotes_canceling", ADMFLAG_GENERIC))
    {
        Format(strBuffer, sizeof(strBuffer), "%t", "cancel ban votes");
        AddMenuItem(hMenu, "CancelBan", strBuffer);

        Format(strBuffer, sizeof(strBuffer), "%t", "cancel mute votes");
        AddMenuItem(hMenu, "CancelMute", strBuffer);

        Format(strBuffer, sizeof(strBuffer), "%t", "cancel gag votes");
        AddMenuItem(hMenu, "CancelGag", strBuffer);

        Format(strBuffer, sizeof(strBuffer), "%t", "cancel silence votes");
        AddMenuItem(hMenu, "CancelSilence", strBuffer);

        Format(strBuffer, sizeof(strBuffer), "%t", "cancel kick votes");
        AddMenuItem(hMenu, "CancelKick", strBuffer);
    }

    DisplayMenu(hMenu, iClient, 30);
}

public int MenuHandler_Settings(Menu hMenu, MenuAction iAction, int iParam1, int iParam2)
{
    if(iAction == MenuAction_End)
    {
        CloseHandle(hMenu);
        return;
    }

    if(iAction == MenuAction_Cancel && iParam2 == MenuCancel_ExitBack)
    {
        if(iParam2 == MenuCancel_ExitBack)
        {
            Menu_ChooseVote(iParam1);
        }
    }
    else if(iAction == MenuAction_Select)
    {
        char strInfo[16];
        GetMenuItem(hMenu, iParam2, strInfo, sizeof(strInfo));

        if(StrEqual(strInfo, "CancelBan"))
        {
            PlayersVotes_ResetBanVotes();
            ShowActivity2(iParam1, "[SM] ", "%t.", "canceled votes", "Ban");
        }
        else if(StrEqual(strInfo, "CancelMute"))
        {
            PlayersVotes_ResetMuteVotes();
            ShowActivity2(iParam1, "[SM] ", "%t.", "canceled votes", "Mute");
        }
        else if(StrEqual(strInfo, "CancelGag"))
        {
            PlayersVotes_ResetGagVotes();
            ShowActivity2(iParam1, "[SM] ", "%t.", "canceled votes", "Gag");
        }
        else if(StrEqual(strInfo, "CancelSilence"))
        {
            PlayersVotes_ResetSilenceVotes();
            ShowActivity2(iParam1, "[SM] ", "%t.", "canceled votes", "Silence");
        }
        else if(StrEqual(strInfo, "CancelKick"))
        {
            PlayersVotes_ResetKickVotes();
            ShowActivity2(iParam1, "[SM] ", "%t.", "canceled votes", "Kick");
        }
    }
}

/*********************
**      KICK        **
**********************/
public void Menu_DisplayKickVote(int iClient)
{
    if(!g_bVoteKickEnabled)
    {
        return;
    }

    if(!CheckCommandAccess(iClient, "sm_votemenu", 0) || !CheckCommandAccess(iClient, "playersvotes_kick", 0))
    {
        ReplyToCommand(iClient, "[SM] %t.", "No Access");
        return;
    }

    if(g_iVoteKickLimit != 0 && g_iVoteKickLimit <= g_iVoteKickCount[iClient])
    {
        PrintToChat(iClient, "[SM] %t.", "votes spent", g_iVoteKickLimit, "Votekick");
        return;
    }

    int iTime = GetTime();
    int iFromLast = iTime - g_iVoteKickLast[iClient];
    if(iFromLast < g_iVoteKickInterval)
    {
        PrintToChat(iClient, "[SM] %t.", "voting not allowed again", g_iVoteKickInterval - iFromLast);
        return;
    }

    int iFromStart = iTime - g_iStartTime;
    if(iFromStart < g_iVoteKickDelay)
    {
        PrintToChat(iClient, "[SM] %t.", "voting not allowed", g_iVoteKickDelay - iFromStart);
        return;
    }

    g_iVoteKickLast[iClient] = iTime;

    Menu hMenu = CreateMenu(MenuHandler_DisplayKickVote);
    if(g_iVoteKickLimit > 0)
    {
        SetMenuTitle(hMenu, "%t: %t", "Votekick", "votes remaining", g_iVoteKickLimit - g_iVoteKickCount[iClient]);
    }
    else
    {
        SetMenuTitle(hMenu, "%t:", "Votekick");
    }

    SetMenuExitBackButton(hMenu, true);

    char strName[MAX_NAME_LENGTH + 12];
    char strClient[8];

    for(int i = 1; i <= MaxClients; i++) 
    {
        if(IsClientInGame(i))
        {
            if(IsFakeClient(i))
            {
                continue;
            }

            if(g_bVoteKickTeam && GetClientTeam(iClient) != GetClientTeam(i))
            {
                continue;
            }

            if(i == iClient || g_bImmune[i])
            {
                continue;
            }

            int iVotes = PlayersVotes_GetKickVotesForTarget(i);
            int iRequired = PlayersVotes_GetRequiredKickVotes(iClient);

            IntToString(i, strClient, sizeof(strClient));
            Format(strName, sizeof(strName), "%N [%d/%d]", i, iVotes, iRequired);

            if(iVotes > 0)
            {
                if(i == 1)
                {
                    AddMenuItem(hMenu, strClient, strName);
                }
                else
                {
                    InsertMenuItem(hMenu, 0, strClient, strName);
                }
            }
            else
            {
                AddMenuItem(hMenu, strClient, strName);
            }
        }
    }

    // If no menu items exist, a menu will not show up, which looks like a bug.
    // Let the voter know that there are no valid targets to vote on!
    int pvmCount = GetMenuItemCount(hMenu);
    if (pvmCount == 0)
    {
        PrintToChat(iClient, "[SM] No valid targets to vote on!");
        return;
    }

    DisplayMenu(hMenu, iClient, 30);
}

public int MenuHandler_DisplayKickVote(Menu hMenu, MenuAction iAction, int iParam1, int iParam2)
{
    if(iAction == MenuAction_End)
    {
        CloseHandle(hMenu);
        return;
    }

    if(iAction == MenuAction_Cancel)
    {
        if(iParam2 == MenuCancel_ExitBack)
        {
            Menu_ChooseVote(iParam1);
        }
    }
    else if(iAction == MenuAction_Select)
    {
        char strInfo[8];
        GetMenuItem(hMenu, iParam2, strInfo, sizeof(strInfo));

        int iTarget = StringToInt(strInfo);
        if(IsValidClient(iTarget) && !IsFakeClient(iTarget))
        {
            g_bVoteKickFor[iParam1][iTarget] = true;
            g_iVoteKickCount[iParam1] += 1;
            PlayersVotes_CheckKickVotes(iParam1, iTarget);
        }
    }
}

/*********************
**       BAN        **
**********************/
public void Menu_DisplayBanVote(int iClient)
{
    if(!g_bVoteBanEnabled)
    {
        return;
    }

    if(!CheckCommandAccess(iClient, "sm_votemenu", 0) || !CheckCommandAccess(iClient, "playersvotes_ban", 0))
    {
        ReplyToCommand(iClient, "[SM] %t.", "No Access");
        return;
    }

    if(g_iVoteBanLimit != 0 && g_iVoteBanLimit <= g_iVoteBanCount[iClient])
    {
        PrintToChat(iClient, "[SM] %t.", "votes spent", g_iVoteBanLimit, "Voteban");
        return;
    }

    int iTime = GetTime();
    int iFromLast = iTime - g_iVoteBanLast[iClient];
    if(iFromLast < g_iVoteBanInterval)
    {
        PrintToChat(iClient, "[SM] %t.", "voting not allowed again", g_iVoteBanInterval - iFromLast);
        return;
    }

    int iFromStart = iTime - g_iStartTime;
    if(iFromStart < g_iVoteBanDelay)
    {
        PrintToChat(iClient, "[SM] %t.", "voting not allowed", g_iVoteBanDelay - iFromStart);
        return;
    }

    g_iVoteBanLast[iClient] = GetTime();

    Menu hMenu = CreateMenu(MenuHandler_DisplayBanVote);
    if(g_iVoteBanLimit > 0)
    {
        SetMenuTitle(hMenu, "%t: %t", "Voteban", "votes remaining", g_iVoteBanLimit - g_iVoteBanCount[iClient]);
    }
    else
    {
        SetMenuTitle(hMenu, "%t:", "Voteban");
    }
    SetMenuExitBackButton(hMenu, true);

    char strName[72];
    char strUserId[8];

    int iRequired = PlayersVotes_GetRequiredBanVotes(iClient);
    for(int i = 0; i < GetArraySize(g_hArrayVoteBanClientNames); ++i)
    {
        int iTarget = GetClientOfUserId(GetArrayCell(g_hArrayVoteBanClientCurrentUserId, i));
        bool bShowTarget;
        if(g_bVoteBanTeam)
        {
            int iTeam = GetClientTeam(iClient);
            if(iTarget != 0)
            {
                if(iTeam == GetClientTeam(iTarget))
                {
                    bShowTarget = true;
                }
            }

            if(GetArrayCell(g_hArrayVoteBanClientTeam, i) == iTeam)
            {
                bShowTarget = true;
            }
        }
        else
        {
            bShowTarget = true;
        }

        if(bShowTarget)
        {
            char strBanName[STEAM_NAME_LENGTH];

            GetArrayString(g_hArrayVoteBanClientNames, i, strBanName, sizeof(strBanName));

            IntToString(GetArrayCell(g_hArrayVoteBanClientUserIds, i), strUserId, sizeof(strUserId));
            Format(strName, sizeof(strName), "%s [%d/%d]", strBanName, PlayersVotes_GetBanVotesForTarget(i), iRequired);

            AddMenuItem(hMenu, strUserId, strName);
        }
    }

    for(int i = 1; i <= MaxClients; i++) 
    {
        if(IsClientInGame(i))
        {
            if(IsFakeClient(i))
            {
                continue;
            }

            if(g_iVoteBanClients[i] != -1)
            {
                continue;
            }

            if(g_bVoteBanTeam && GetClientTeam(iClient) != GetClientTeam(i))
            {
                continue;
            }

            if(i == iClient || g_bImmune[i])
            {
                continue;
            }

            IntToString(GetClientUserId(i), strUserId, sizeof(strUserId));
            Format(strName, sizeof(strName), "%N [0/%d]", i, iRequired);

            AddMenuItem(hMenu, strUserId, strName);
        }
    }
    
    // If no menu items exist, a menu will not show up, which looks like a bug.
    // Let the voter know that there are no valid targets to vote on!
    int pvmCount = GetMenuItemCount(hMenu);
    if (pvmCount == 0)
    {
        PrintToChat(iClient, "[SM] No valid targets to vote on!");
        return;
    }

    DisplayMenu(hMenu, iClient, 30);
}

public int MenuHandler_DisplayBanVote(Menu hMenu, MenuAction iAction, int iParam1, int iParam2)
{
    if(iAction == MenuAction_End)
    {
        CloseHandle(hMenu);
        return;
    }

    if(iAction == MenuAction_Cancel)
    {
        if(iParam2 == MenuCancel_ExitBack)
        {
            Menu_ChooseVote(iParam1);
        }
    }
    else if(iAction == MenuAction_Select)
    {
        char strInfo[8];
        GetMenuItem(hMenu, iParam2, strInfo, sizeof(strInfo));

        int iTarget = StringToInt(strInfo);
        if(GetArraySize(g_hArrayVoteBanReasons) > 0)
        {
            Menu_BanReason(iParam1, iTarget);
        }
        else
        {
            PlayersVotes_ProcessBanVote(iParam1, iTarget, -1);
        }
    }
}

public void Menu_BanReason(int iClient, int iTarget)
{
    int iNumReasons = GetArraySize(g_hArrayVoteBanReasons);
    if(iNumReasons <= 0)
    {
        PlayersVotes_ProcessBanVote(iClient, iTarget, -1);
        return;
    }

    Menu hMenu = CreateMenu(MenuHandler_BanReason);

    char strTitle[32];
    Format(strTitle, sizeof(strTitle), "%t:", "ban reasons");
    SetMenuTitle(hMenu, strTitle);

    char strTarget[8];
    Format(strTarget, sizeof(strTarget), "%d", iTarget);

    char strReason[MENU_VOTE_REASON];
    for(int i = 0; i < iNumReasons; ++i)
    {
        GetArrayString(g_hArrayVoteBanReasons, i, strReason, sizeof(strReason));
        AddMenuItem(hMenu, strTarget, strReason);
    }

    DisplayMenu(hMenu, iClient, 30);
}

public int MenuHandler_BanReason(Menu hMenu, MenuAction iAction, int iParam1, int iParam2)
{
    if(iAction == MenuAction_End)
    {
        CloseHandle(hMenu);
        return;
    }

    if(iAction == MenuAction_Select)
    {
        char strInfo[8];
        GetMenuItem(hMenu, iParam2, strInfo, sizeof(strInfo));

        int iTarget = StringToInt(strInfo);
        PlayersVotes_ProcessBanVote(iParam1, iTarget, iParam2);
    }
}

/*********************
**      MUTE        **
**********************/
public void Menu_DisplayMuteVote(int iClient)
{
    if(!g_bVoteMuteEnabled)
    {
        return;
    }

    if(!CheckCommandAccess(iClient, "sm_votemenu", 0) || !CheckCommandAccess(iClient, "playersvotes_mute", 0))
    {
        ReplyToCommand(iClient, "[SM] %t.", "No Access");
        return;
    }

    if(g_iVoteMuteLimit != 0 && g_iVoteMuteLimit <= g_iVoteMuteCount[iClient])
    {
        PrintToChat(iClient, "[SM] %t.", "votes spent", g_iVoteMuteLimit, "Votemute");
        return;
    }

    int iTime = GetTime();
    int iFromLast = iTime - g_iVoteMuteLast[iClient];
    if(iFromLast < g_iVoteMuteInterval)
    {
        PrintToChat(iClient, "[SM] %t.", "voting not allowed again", g_iVoteMuteInterval - iFromLast);
        return;
    }

    int iFromStart = iTime - g_iStartTime;
    if(iFromStart < g_iVoteMuteDelay)
    {
        PrintToChat(iClient, "[SM] %t.", "voting not allowed", g_iVoteMuteDelay - iFromStart);
        return;
    }

    g_iVoteMuteLast[iClient] = iTime;

    Menu hMenu = CreateMenu(MenuHandler_DisplayMuteVote);
    if(g_iVoteMuteLimit > 0)
    {
        SetMenuTitle(hMenu, "%t: %t", "Votemute", "votes remaining", g_iVoteMuteLimit - g_iVoteMuteCount[iClient]);
    }
    else
    {
        SetMenuTitle(hMenu, "%t:", "Votemute");
    }
    SetMenuExitBackButton(hMenu, true);

    char strName[72];
    char strClient[8];

    for(int i = 1; i <= MaxClients; i++) 
    {
        if(IsClientInGame(i))
        {
            if(IsFakeClient(i))
            {
                continue;
            }

            if(g_bVoteMuteTeam && GetClientTeam(iClient) != GetClientTeam(i))
            {
                continue;
            }

            if(i == iClient || g_bImmune[i] || g_bVoteMuteMuted[iClient])
            {
                continue;
            }

            int iVotes = PlayersVotes_GetMuteVotesForTarget(i);
            int iRequired = PlayersVotes_GetRequiredMuteVotes(iClient);

            IntToString(i, strClient, sizeof(strClient));
            Format(strName, sizeof(strName), "%N [%d/%d]", i, iVotes, iRequired);

            if(iVotes > 0)
            {
                if(i == 1)
                {
                    AddMenuItem(hMenu, strClient, strName);
                }
                else
                {
                    InsertMenuItem(hMenu, 0, strClient, strName);
                }
            }
            else
            {
                AddMenuItem(hMenu, strClient, strName);
            }
        }
    }
    
    // If no menu items exist, a menu will not show up, which looks like a bug.
    // Let the voter know that there are no valid targets to vote on!
    int pvmCount = GetMenuItemCount(hMenu);
    if (pvmCount == 0)
    {
        PrintToChat(iClient, "[SM] No valid targets to vote on!");
        return;
    }

    DisplayMenu(hMenu, iClient, 30);
}

public int MenuHandler_DisplayMuteVote(Menu hMenu, MenuAction iAction, int iParam1, int iParam2)
{
    if(iAction == MenuAction_End)
    {
        CloseHandle(hMenu);
        return;
    }

    if(iAction == MenuAction_Cancel)
    {
        if(iParam2 == MenuCancel_ExitBack)
        {
            Menu_ChooseVote(iParam1);
        }
    }
    else if(iAction == MenuAction_Select)
    {
        char strInfo[8];
        GetMenuItem(hMenu, iParam2, strInfo, sizeof(strInfo));

        int iTarget = StringToInt(strInfo);
        if(IsValidClient(iTarget) && !IsFakeClient(iTarget))
        {
            g_bVoteMuteFor[iParam1][iTarget] = true;
            g_iVoteMuteCount[iParam1] += 1;
            PlayersVotes_CheckMuteVotes(iParam1, iTarget);
        }
    }
}

/*********************
**      GAG        **
**********************/
public void Menu_DisplayGagVote(int iClient)
{
    if(!g_bVoteGagEnabled)
    {
        return;
    }

    if(!CheckCommandAccess(iClient, "sm_votemenu", 0) || !CheckCommandAccess(iClient, "playersvotes_gag", 0))
    {
        ReplyToCommand(iClient, "[SM] %t.", "No Access");
        return;
    }

    if(g_iVoteGagLimit != 0 && g_iVoteGagLimit <= g_iVoteGagCount[iClient])
    {
        PrintToChat(iClient, "[SM] %t.", "votes spent", g_iVoteGagLimit, "Votegag");
        return;
    }

    int iTime = GetTime();
    int iFromLast = iTime - g_iVoteGagLast[iClient];
    if(iFromLast < g_iVoteGagInterval)
    {
        PrintToChat(iClient, "[SM] %t.", "voting not allowed again", g_iVoteGagInterval - iFromLast);
        return;
    }

    int iFromStart = iTime - g_iStartTime;
    if(iFromStart < g_iVoteGagDelay)
    {
        PrintToChat(iClient, "[SM] %t.", "voting not allowed", g_iVoteGagDelay - iFromStart);
        return;
    }

    g_iVoteGagLast[iClient] = iTime;

    Menu hMenu = CreateMenu(MenuHandler_DisplayGagVote);
    if(g_iVoteGagLimit > 0)
    {
        SetMenuTitle(hMenu, "%t: %t", "Votegag", "votes remaining", g_iVoteGagLimit - g_iVoteGagCount[iClient]);
    }
    else
    {
        SetMenuTitle(hMenu, "%t:", "Votegag");
    }
    SetMenuExitBackButton(hMenu, true);

    char strName[72];
    char strClient[8];

    for(int i = 1; i <= MaxClients; i++) 
    {
        if(IsClientInGame(i))
        {
            if(IsFakeClient(i))
            {
                continue;
            }

            if(g_bVoteGagTeam && GetClientTeam(iClient) != GetClientTeam(i))
            {
                continue;
            }
        
            if(i == iClient || g_bImmune[i] || g_bVoteGagGagged[iClient])
            {
                continue;
            }

            int iVotes = PlayersVotes_GetGagVotesForTarget(i);
            int iRequired = PlayersVotes_GetRequiredGagVotes(iClient);

            IntToString(i, strClient, sizeof(strClient));
            Format(strName, sizeof(strName), "%N [%d/%d]", i, iVotes, iRequired);

            if(iVotes > 0)
            {
                if(i == 1)
                {
                    AddMenuItem(hMenu, strClient, strName);
                }
                else
                {
                    InsertMenuItem(hMenu, 0, strClient, strName);
                }
            }
            else
            {
                AddMenuItem(hMenu, strClient, strName);
            }
        }
    }

    // If no menu items exist, a menu will not show up, which looks like a bug.
    // Let the voter know that there are no valid targets to vote on!
    int pvmCount = GetMenuItemCount(hMenu);
    if (pvmCount == 0)
    {
        PrintToChat(iClient, "[SM] No valid targets to vote on!");
        return;
    }

    DisplayMenu(hMenu, iClient, 30);
}

public int MenuHandler_DisplayGagVote(Menu hMenu, MenuAction iAction, int iParam1, int iParam2)
{
    if(iAction == MenuAction_End)
    {
        CloseHandle(hMenu);
        return;
    }

    if(iAction == MenuAction_Cancel)
    {
        if(iParam2 == MenuCancel_ExitBack)
        {
            Menu_ChooseVote(iParam1);
        }
    }
    else if(iAction == MenuAction_Select)
    {
        char strInfo[8];
        GetMenuItem(hMenu, iParam2, strInfo, sizeof(strInfo));

        int iTarget = StringToInt(strInfo);
        if(IsValidClient(iTarget) && !IsFakeClient(iTarget))
        {
            g_bVoteGagFor[iParam1][iTarget] = true;
            g_iVoteGagCount[iParam1] += 1;
            PlayersVotes_CheckGagVotes(iParam1, iTarget);
        }
    }
}

/*********************
**     SILENCE      **
**********************/
public void Menu_DisplaySilenceVote(int iClient)
{
    if(!g_bVoteSilenceEnabled)
    {
        return;
    }

    if(!CheckCommandAccess(iClient, "sm_votemenu", 0) || !CheckCommandAccess(iClient, "playersvotes_silence", 0))
    {
        ReplyToCommand(iClient, "[SM] %t.", "No Access");
        return;
    }

    if(g_iVoteSilenceLimit != 0 && g_iVoteSilenceLimit <= g_iVoteSilenceCount[iClient])
    {
        PrintToChat(iClient, "[SM] %t.", "votes spent", g_iVoteSilenceLimit, "Votesilence");
        return;
    }

    int iTime = GetTime();
    int iFromLast = iTime - g_iVoteSilenceLast[iClient];
    if(iFromLast < g_iVoteSilenceInterval)
    {
        PrintToChat(iClient, "[SM] %t.", "voting not allowed again", g_iVoteSilenceInterval - iFromLast);
        return;
    }

    int iFromStart = iTime - g_iStartTime;
    if(iFromStart < g_iVoteSilenceDelay)
    {
        PrintToChat(iClient, "[SM] %t.", "voting not allowed", g_iVoteSilenceDelay - iFromStart);
        return;
    }

    g_iVoteSilenceLast[iClient] = iTime;

    Menu hMenu = CreateMenu(MenuHandler_DisplaySilenceVote);
    if(g_iVoteSilenceLimit > 0)
    {
        SetMenuTitle(hMenu, "%t: %t", "Votesilence", "votes remaining", g_iVoteSilenceLimit - g_iVoteSilenceCount[iClient]);
    }
    else
    {
        SetMenuTitle(hMenu, "%t:", "Votesilence");
    }
    SetMenuExitBackButton(hMenu, true);

    char strName[72];
    char strClient[8];

    for(int i = 1; i <= MaxClients; i++) 
    {
        if(IsClientInGame(i))
        {
            if(IsFakeClient(i))
            {
                continue;
            }

            if(g_bVoteSilenceTeam && GetClientTeam(iClient) != GetClientTeam(i))
            {
                continue;
            }

            if(i == iClient || g_bImmune[i] || g_bVoteSilenceSilenced[iClient])
            {
                continue;
            }
            
            int iVotes = PlayersVotes_GetSilenceVotesForTarget(i);
            int iRequired = PlayersVotes_GetRequiredSilenceVotes(iClient);

            IntToString(i, strClient, sizeof(strClient));
            Format(strName, sizeof(strName), "%N [%d/%d]", i, iVotes, iRequired);

            if(iVotes > 0)
            {
                if(i == 1)
                {
                    AddMenuItem(hMenu, strClient, strName);
                }
                else
                {
                    InsertMenuItem(hMenu, 0, strClient, strName);
                }
            }
            else
            {
                AddMenuItem(hMenu, strClient, strName);
            }
        }
    }

    // If no menu items exist, a menu will not show up, which looks like a bug.
    // Let the voter know that there are no valid targets to vote on!
    int pvmCount = GetMenuItemCount(hMenu);
    if (pvmCount == 0)
    {
        PrintToChat(iClient, "[SM] No valid targets to vote on!");
        return;
    }

    DisplayMenu(hMenu, iClient, 30);
}

public int MenuHandler_DisplaySilenceVote(Menu hMenu, MenuAction iAction, int iParam1, int iParam2)
{
    if(iAction == MenuAction_End)
    {
        CloseHandle(hMenu);
        return;
    }

    if(iAction == MenuAction_Cancel)
    {
        if(iParam2 == MenuCancel_ExitBack)
        {
            Menu_ChooseVote(iParam1);
        }
    }
    else if(iAction == MenuAction_Select)
    {
        char strInfo[8];
        GetMenuItem(hMenu, iParam2, strInfo, sizeof(strInfo));

        int iTarget = StringToInt(strInfo);
        if(IsValidClient(iTarget) && !IsFakeClient(iTarget))
        {
            g_bVoteSilenceFor[iParam1][iTarget] = true;
            g_iVoteSilenceCount[iParam1] += 1;
            PlayersVotes_CheckSilenceVotes(iParam1, iTarget);
        }
    }
}

///////////////////////////////////
//===============================//
//=====[ FUNCTIONS ]=============//
//===============================//
///////////////////////////////////
public void Config_Load()
{
    // Tell user if config file doesn't exist. If it doesn't stop this plugin.
    if(!FileExists(g_strConfigFile))
    {
        SetFailState("Configuration file %s not found!", g_strConfigFile);
        return;
    }
    Handle hKeyValues = CreateKeyValues("playersvotes");
    if(!FileToKeyValues(hKeyValues, g_strConfigFile))
    {
        SetFailState("Configuration file %s not found!", g_strConfigFile);
        return;
    }

    g_bChatTriggers = view_as<bool>(KvGetNum(hKeyValues, "chattriggers", 1));
    g_iVoteImmunity = KvGetNum(hKeyValues, "immunity", 0);

    // Grab every configuration from the config file and set our variables
    // with the configurations values.
    if(KvGotoFirstSubKey(hKeyValues))
    {
        char strSection[32];
        do
        {
            KvGetSectionName(hKeyValues, strSection, sizeof(strSection));

            // Kick vote configuration
            if(StrEqual(strSection, "kick"))
            {
                g_bVoteKickEnabled = view_as<bool>(KvGetNum(hKeyValues, "enabled", 1));
                PrintToServer("%i", g_bVoteKickEnabled);
                g_flVoteKickRatio = KvGetFloat(hKeyValues, "ratio", 0.6);
                g_iVoteKickMinimum = KvGetNum(hKeyValues, "minimum", 4);
                g_iVoteKickDelay = KvGetNum(hKeyValues, "delay", 1);
                g_iVoteKickLimit = KvGetNum(hKeyValues, "limit", 0);
                g_iVoteKickInterval = KvGetNum(hKeyValues, "interval", 0);
                g_bVoteKickTeam = view_as<bool>(KvGetNum(hKeyValues, "team", 0));
            }
            // Ban vote configuration
            else if(StrEqual(strSection, "ban"))
            {
                g_bVoteBanEnabled = view_as<bool>(KvGetNum(hKeyValues, "enabled", 1));
                g_flVoteBanRatio = KvGetFloat(hKeyValues, "ratio", 0.8);
                g_iVoteBanMinimum = KvGetNum(hKeyValues, "minimum", 4);
                g_iVoteBanDelay = KvGetNum(hKeyValues, "delay", 1);
                g_iVoteBanLimit = KvGetNum(hKeyValues, "limit", 0);
                g_iVoteBanInterval = KvGetNum(hKeyValues, "interval", 0);
                g_bVoteBanTeam = view_as<bool>(KvGetNum(hKeyValues, "team", 0));
                g_iVoteBanTime = KvGetNum(hKeyValues, "time", 30);
                KvGetString(hKeyValues, "reasons", g_strVoteBanReasons, sizeof(g_strVoteBanReasons));

                ClearArray(g_hArrayVoteBanReasons);

                char strBanReasonList[PLATFORM_MAX_PATH];
                strcopy(strBanReasonList, sizeof(strBanReasonList), g_strVoteBanReasons);
                StrCat(strBanReasonList, sizeof(strBanReasonList), ";");

                int iBanReasonOffset;
                char strBanReason[MENU_VOTE_REASON];
                for(int i = SplitString(strBanReasonList, ";", strBanReason, sizeof(strBanReason)); i != -1; 
                    i = SplitString(strBanReasonList[iBanReasonOffset], ";", strBanReason, sizeof(strBanReason)))
                {
                    iBanReasonOffset += i;
                    TrimString(strBanReason);
                    if(!StrEqual(strBanReason, ""))
                    {
                        PushArrayString(g_hArrayVoteBanReasons, strBanReason);
                    }
                }
            }
            // Mute vote configuration
            else if(StrEqual(strSection, "mute"))
            {
                g_bVoteMuteEnabled = view_as<bool>(KvGetNum(hKeyValues, "enabled", 1));
                g_flVoteMuteRatio = KvGetFloat(hKeyValues, "ratio", 0.6);
                g_iVoteMuteMinimum = KvGetNum(hKeyValues, "minimum", 4);
                g_iVoteMuteDelay = KvGetNum(hKeyValues, "delay", 1);
                g_iVoteMuteLimit = KvGetNum(hKeyValues, "limit", 0);
                g_iVoteMuteInterval = KvGetNum(hKeyValues, "interval", 0);
                g_bVoteMuteTeam = view_as<bool>(KvGetNum(hKeyValues, "team", 0));
            }
            // Gag vote configuration
            else if(StrEqual(strSection, "gag"))
            {
                g_bVoteGagEnabled = view_as<bool>(KvGetNum(hKeyValues, "enabled", 1));
                g_flVoteGagRatio = KvGetFloat(hKeyValues, "ratio", 0.6);
                g_iVoteGagMinimum = KvGetNum(hKeyValues, "minimum", 4);
                g_iVoteGagDelay = KvGetNum(hKeyValues, "delay", 1);
                g_iVoteGagLimit = KvGetNum(hKeyValues, "limit", 0);
                g_iVoteGagInterval = KvGetNum(hKeyValues, "interval", 0);
                g_bVoteGagTeam = view_as<bool>(KvGetNum(hKeyValues, "team", 0));
            }
            // Silence vote configuration
            else if(StrEqual(strSection, "silence"))
            {
                g_bVoteSilenceEnabled = view_as<bool>(KvGetNum(hKeyValues, "enabled", 1));
                g_flVoteSilenceRatio = KvGetFloat(hKeyValues, "ratio", 0.6);
                g_iVoteSilenceMinimum = KvGetNum(hKeyValues, "minimum", 4);
                g_iVoteSilenceDelay = KvGetNum(hKeyValues, "delay", 1);
                g_iVoteSilenceLimit = KvGetNum(hKeyValues, "limit", 0);
                g_iVoteSilenceInterval = KvGetNum(hKeyValues, "interval", 0);
                g_bVoteSilenceTeam = view_as<bool>(KvGetNum(hKeyValues, "team", 0));
            }
        }
        while(KvGotoNextKey(hKeyValues));
    }
    CloseHandle(hKeyValues);
}

/*********************
**      KICK        **
**********************/
public void PlayersVotes_ResetKickVotes()
{
    for(int iClient = 0; iClient <= MAXPLAYERS; ++iClient)
    {
        for(int iTarget = 0; iTarget <= MAXPLAYERS; ++iTarget)
        {
            g_bVoteKickFor[iClient][iTarget] = false;
        }
    }
}

public void PlayersVotes_CheckKickVotes(int iVoter, int iTarget)
{
    int iVotesRequired = PlayersVotes_GetRequiredKickVotes(iVoter);
    int iVotes = PlayersVotes_GetKickVotesForTarget(iTarget);

    char strVoterName[65];
    GetClientName(iVoter, strVoterName, sizeof(strVoterName));

    char strTargetName[65];
    GetClientName(iTarget, strTargetName, sizeof(strTargetName));

    PrintToChatAll("[SM] %t.", "voted to kick", strVoterName, strTargetName);

    if(iVotes < iVotesRequired)
    {
        PrintToChatAll("[SM] %t.", "votes required", iVotes, iVotesRequired);
        return;
    }

    PrintToChatAll("[SM] %t.", "kicked by vote", strTargetName);
    LogAction(-1, iTarget, "Vote kick successful, kicked \"%L\" (iReason \"voted by players\")", iTarget);
    ServerCommand("kickid %d %t", GetClientUserId(iTarget), "kicked by users");
}

public int PlayersVotes_GetRequiredKickVotes(int iVoter)
{
    int iCount;
    for(int i = 1; i <= MaxClients; i++) 
    {
        if(IsClientInGame(i))
        {
            if(IsFakeClient(i))
            {
                continue;
            }
            
            if(g_bVoteKickTeam && GetClientTeam(i) != GetClientTeam(iVoter))
            {
                continue;
            }
            
            iCount++;
        }
    }

    int iRequired = RoundToCeil(float(iCount) * g_flVoteKickRatio);
    if(iRequired < g_iVoteKickMinimum)
    {
        iRequired = g_iVoteKickMinimum;
    }
    
    return iRequired;
}

public int PlayersVotes_GetKickVotesForTarget(int iTarget)
{
    int iVotes;
    for(int i = 1; i <= MAXPLAYERS; i++)
    {
        if(g_bVoteKickFor[i][iTarget])
        {
            iVotes++;
        }
    }
    return iVotes;
}

/*********************
**       BAN        **
**********************/
public void PlayersVotes_ResetBanVotes()
{
    ClearArray(g_hArrayVoteBanClientUserIds);
    ClearArray(g_hArrayVoteBanClientCurrentUserId);
    ClearArray(g_hArrayVoteBanClientTeam);
    ClearArray(g_hArrayVoteBanClientIdentity);
    ClearArray(g_hArrayVoteBanClientNames);
    for(int iClient = 0; iClient <= MAXPLAYERS; ++iClient)
    {
        ClearArray(g_hArrayVoteBanFor[iClient]);
        ClearArray(g_hArrayVoteBanForReason[iClient]);
        g_iVoteBanClients[iClient] = -1;
    }
}

public void PlayersVotes_RemoveBanVotesFromTarget(int iTarget)
{
    RemoveFromArray(g_hArrayVoteBanClientUserIds, iTarget);
    RemoveFromArray(g_hArrayVoteBanClientCurrentUserId, iTarget);
    RemoveFromArray(g_hArrayVoteBanClientTeam, iTarget);
    RemoveFromArray(g_hArrayVoteBanClientIdentity, iTarget);
    RemoveFromArray(g_hArrayVoteBanClientNames, iTarget);
    for(int i = 1; i <= MAXPLAYERS; ++i)
    {
        int iVoteToRemove = -1;
        for(int j = 0; j < GetArraySize(g_hArrayVoteBanFor[i]); ++j)
        {
            int iVote = GetArrayCell(g_hArrayVoteBanFor[i], j);
            if(iVote == iTarget)
            {
                iVoteToRemove = j;
            }
            else if(iVote > iTarget)
            {
                SetArrayCell(g_hArrayVoteBanFor[i], j, iVote - 1);
            }
        }
        if(iVoteToRemove != -1)
        {
            RemoveFromArray(g_hArrayVoteBanFor[i], iVoteToRemove);
            RemoveFromArray(g_hArrayVoteBanForReason[i], iVoteToRemove);
        }
        if(g_iVoteBanClients[i] == iTarget)
        {
            g_iVoteBanClients[i] = -1;
        }
        else if(g_iVoteBanClients[i] > iTarget)
        {
            --g_iVoteBanClients[i];
        }
    }
}

public void PlayersVotes_CheckBanVotes(int iVoter, int iTarget)
{
    int iVotesRequired = PlayersVotes_GetRequiredBanVotes(iVoter);
    int iVotes = PlayersVotes_GetBanVotesForTarget(iTarget);

    char strVoterName[65];
    GetClientName(iVoter, strVoterName, sizeof(strVoterName));

    char strTargetName[65];
    GetArrayString(g_hArrayVoteBanClientNames, iTarget, strTargetName, sizeof(strTargetName));

    PrintToChatAll("[SM] %t.", "voted to ban", strVoterName, strTargetName);

    if(iVotes < iVotesRequired)
    {
        PrintToChatAll("[SM] %t.", "votes required", iVotes, iVotesRequired);
        return;
    }

    int iUserId = GetArrayCell(g_hArrayVoteBanClientCurrentUserId, iTarget);
    int iClientId = GetClientOfUserId(iUserId);

    int iBanFlags = BANFLAG_AUTHID;
    char strIdentity[STEAM_NAME_LENGTH];
    GetArrayString(g_hArrayVoteBanClientIdentity, iTarget, strIdentity, sizeof(strIdentity));
    if(strncmp(strIdentity, "STEAM", 5) != 0)
    {
        iBanFlags = BANFLAG_IP;
    }

    int iReason = PlayersVotes_GetBanReason(iTarget);
    char strVoteReason[MENU_VOTE_REASON];
    char strReason[100];
    if(iReason > -1)
    {
        GetArrayString(g_hArrayVoteBanReasons, iReason, strVoteReason, sizeof(strVoteReason));
        PrintToChatAll("[SM] %t (\x05%s\x01).", "banned by vote", strTargetName, strVoteReason);
        if(iClientId > 0)
        {
            Format(strReason, sizeof(strReason), "%t (%s)", "banned by users", strVoteReason);
        }
        else
        {
            Format(strReason, sizeof(strReason), "(%s) %t (%s)", strTargetName, "banned by users", strVoteReason);
        }
    }
    else
    {
        strcopy(strVoteReason, sizeof(strVoteReason), "unspecified");
        PrintToChatAll("[SM] %t.", "banned by vote", strTargetName);
        if(iClientId > 0)
        {
            Format(strReason, sizeof(strReason), "%t", "banned by users");
        }
        else
        {
            Format(strReason, sizeof(strReason), "(%s) %t", strTargetName, "banned by users");
        }
    }

    LogAction(-1, -1, "Vote ban successful, banned \"%s\" (iReason \"%s\")", strTargetName, strVoteReason);

    if(g_hCvarVoteBanSB == INVALID_HANDLE)
    {
        BanIdentity(strIdentity, g_iVoteBanTime, iBanFlags, strReason, "players vote");
    }
    else
    {
        if(iClientId > 0)
        {
            ServerCommand("sm_ban #%d %d \"%s\"", iUserId, g_iVoteBanTime, strReason);
        }
        else if(iBanFlags == BANFLAG_AUTHID)
        {
            ServerCommand("sm_addban %d %s \"%s\"", g_iVoteBanTime, strIdentity, strReason);
        }
        else
        {
            ServerCommand("sm_banip %s %d \"%s\"", strIdentity, g_iVoteBanTime, strReason);
        }
    }

    if(iBanFlags == BANFLAG_AUTHID)
    {
        ServerCommand("kickid %d %s", iUserId, strReason);
    }

    PlayersVotes_RemoveBanVotesFromTarget(iTarget);
}

public int PlayersVotes_GetRequiredBanVotes(int iVoter)
{
    int iCount;
    for(int i = 1; i <= MaxClients; i++) 
    {
        if(IsClientInGame(i))
        {
            if(IsFakeClient(i))
            {
                continue;
            }

            if(g_bVoteBanTeam && GetClientTeam(i) != GetClientTeam(iVoter))
            {
                continue;
            }

            iCount++;
        }
    }

    int iRequired = RoundToCeil(float(iCount) * g_flVoteBanRatio);
    if(iRequired < g_iVoteBanMinimum)
    {
        iRequired = g_iVoteBanMinimum;
    }

    return iRequired;
}

public int PlayersVotes_GetBanVotesForTarget(int iTarget)
{
    int iVotes;
    for(int i = 1; i <= MAXPLAYERS; i++)
    {
        int iBanVotes = GetArraySize(g_hArrayVoteBanFor[i]);
        for(int j = 0; j < iBanVotes; ++j)
        {
            if(GetArrayCell(g_hArrayVoteBanFor[i], j) == iTarget)
            {
                iVotes++;
            }
        }
    }
    return iVotes;
}

public void PlayersVotes_ProcessBanVote(int iVoter, int iTarget, int iReason)
{
    int iTargetIndex = FindValueInArray(g_hArrayVoteBanClientUserIds, iTarget);
    if(iTargetIndex == -1)
    {
        int iClient = GetClientOfUserId(iTarget);
        if(IsValidClient(iClient) && !IsFakeClient(iClient))
        {
            char strClientName[MAX_NAME_LENGTH];
            GetClientName(iClient, strClientName, sizeof(strClientName));

            char strClientAuth[24];
            PlayersVotes_GetIdentity(iClient, strClientAuth, sizeof(strClientAuth));

            PushArrayCell(g_hArrayVoteBanClientUserIds, iTarget);
            PushArrayString(g_hArrayVoteBanClientNames, strClientName);
            PushArrayString(g_hArrayVoteBanClientIdentity, strClientAuth);
            PushArrayCell(g_hArrayVoteBanClientCurrentUserId, iTarget);
            PushArrayCell(g_hArrayVoteBanClientTeam, GetClientTeam(iClient));

            g_iVoteBanClients[iClient] = GetArraySize(g_hArrayVoteBanClientNames) - 1;
            iTargetIndex = g_iVoteBanClients[iClient];
        }
    }

    if(iTargetIndex != -1)
    {
        bool bDuplicateVote;
        for(int i = 0; i < GetArraySize(g_hArrayVoteBanFor[iVoter]); ++i)
        {
            if(GetArrayCell(g_hArrayVoteBanFor[iVoter], i) == iTargetIndex)
            {
                bDuplicateVote = true;
            }
        }

        if(!bDuplicateVote)
        {
            PushArrayCell(g_hArrayVoteBanFor[iVoter], iTargetIndex);
            PushArrayCell(g_hArrayVoteBanForReason[iVoter], iReason);
        }

        g_iVoteBanCount[iVoter] += 1;
        PlayersVotes_CheckBanVotes(iVoter, iTargetIndex);
    }
}

public int PlayersVotes_GetBanReason(int iTarget)
{
    if(GetArraySize(g_hArrayVoteBanReasons) <= 0)
    {
        return -1;
    }

    Handle hReasonTally = CreateArray(1, GetArraySize(g_hArrayVoteBanReasons));

    for(int i = 0; i < GetArraySize(hReasonTally); ++i)
    {
        SetArrayCell(hReasonTally, i, 0);
    }

    int iTargetIndex;
    for(int i = 1; i <= MAXPLAYERS; ++i)
    {
        iTargetIndex = FindValueInArray(g_hArrayVoteBanFor[i], iTarget);
        if(iTargetIndex >= 0)
        {
            int iReason = GetArrayCell(g_hArrayVoteBanForReason[i], iTargetIndex);
            int iCount = GetArrayCell(hReasonTally, iReason);
            SetArrayCell(hReasonTally, iReason, iCount + 1);
        }
    }

    int iFinalReason = -1;
    int iFinalReasonCount;
    for(int i = 0; i < GetArraySize(hReasonTally); ++i)
    {
        if(iFinalReasonCount < GetArrayCell(hReasonTally, i))
        {
            iFinalReasonCount = GetArrayCell(hReasonTally, i);
            iFinalReason = i;
        }
    }

    CloseHandle(hReasonTally);
    return iFinalReason;
}

/*********************
**       MUTE       **
**********************/
public void PlayersVotes_ResetMuteVotes()
{
    for(int iClient = 0; iClient <= MAXPLAYERS; ++iClient)
    {
        for(int iTarget = 0; iTarget <= MAXPLAYERS; ++iTarget)
        {
            g_bVoteMuteFor[iClient][iTarget] = false;
        }
    }
}

public void PlayersVotes_CheckMuteVotes(int iVoter, int iTarget)
{
    int iVotesRequired = PlayersVotes_GetRequiredMuteVotes(iVoter);
    int iVotes = PlayersVotes_GetMuteVotesForTarget(iTarget);

    char strVoterName[65];
    GetClientName(iVoter, strVoterName, sizeof(strVoterName));

    char strTargetName[65];
    GetClientName(iTarget, strTargetName, sizeof(strTargetName));

    PrintToChatAll("[SM] %t.", "voted to mute", strVoterName, strTargetName);

    if(iVotes < iVotesRequired)
    {
        PrintToChatAll("[SM] %t.", "votes required", iVotes, iVotesRequired);
        return;
    }

    PrintToChatAll("[SM] %t.", "muted by vote", strTargetName);
    LogAction(-1, iTarget, "Vote mute successful, muted \"%L\" (iReason \"voted by players\")", iTarget);
    g_bVoteMuteMuted[iTarget] = true;
    char strClientAuth[STEAM_NAME_LENGTH];
    PlayersVotes_GetIdentity(iTarget, strClientAuth, sizeof(strClientAuth));
    PushArrayString(g_hArrayVoteMuteClientIdentity, strClientAuth);
    PlayersVotes_MutePlayer(iTarget);
}

public int PlayersVotes_GetRequiredMuteVotes(int iVoter)
{
    int iCount;
    for(int i = 1; i <= MaxClients; i++) 
    {
        if(IsClientInGame(i))
        {
            if(IsFakeClient(i))
            {
                continue;
            }

            if(g_bVoteMuteTeam && GetClientTeam(i) != GetClientTeam(iVoter))
            {
                continue;
            }

            iCount++;
        }
    }

    int iRequired = RoundToCeil(float(iCount) * g_flVoteMuteRatio);
    if(iRequired < g_iVoteMuteMinimum)
    {
        iRequired = g_iVoteMuteMinimum;
    }
    
    return iRequired;
}

public int PlayersVotes_GetMuteVotesForTarget(int iTarget)
{
    int iVotes;
    for(int i = 1; i <= MAXPLAYERS; i++)
    {
        if(g_bVoteMuteFor[i][iTarget])
        {
            iVotes++;
        }
    }
    return iVotes;
}

public void PlayersVotes_MutePlayer(int iClient)
{
    BaseComm_SetClientMute(iClient, true);
}

/*********************
**       GAG        **
**********************/
public void PlayersVotes_ResetGagVotes()
{
    for(int iClient = 0; iClient <= MAXPLAYERS; ++iClient)
    {
        for(int iTarget = 0; iTarget <= MAXPLAYERS; ++iTarget)
        {
            g_bVoteGagFor[iClient][iTarget] = false;
        }
    }
}

public void PlayersVotes_CheckGagVotes(int iVoter, int iTarget)
{
    int iVotesRequired = PlayersVotes_GetRequiredGagVotes(iVoter);
    int iVotes = PlayersVotes_GetGagVotesForTarget(iTarget);

    char strVoterName[65];
    GetClientName(iVoter, strVoterName, sizeof(strVoterName));

    char strTargetName[65];
    GetClientName(iTarget, strTargetName, sizeof(strTargetName));

    PrintToChatAll("[SM] %t.", "voted to gag", strVoterName, strTargetName);

    if(iVotes < iVotesRequired)
    {
        PrintToChatAll("[SM] %t.", "votes required", iVotes, iVotesRequired);
        return;
    }

    PrintToChatAll("[SM] %t.", "gagged by vote", strTargetName);
    LogAction(-1, iTarget, "Vote gag successful, gagged \"%L\" (iReason \"voted by players\")", iTarget);
    g_bVoteGagGagged[iTarget] = true;
    char strClientAuth[STEAM_NAME_LENGTH];
    PlayersVotes_GetIdentity(iTarget, strClientAuth, sizeof(strClientAuth));
    PushArrayString(g_hArrayVoteGagClientIdentity, strClientAuth);
    PlayersVotes_GagPlayer(iTarget);
}

public int PlayersVotes_GetRequiredGagVotes(int iVoter)
{
    int iCount;
    for(int i = 1; i <= MaxClients; i++) 
    {
        if(IsClientInGame(i))
        {
            if(IsFakeClient(i))
            {
                continue;
            }

            if(g_bVoteGagTeam && GetClientTeam(i) != GetClientTeam(iVoter))
            {
                continue;
            }

            iCount++;
        }
    }

    int iRequired = RoundToCeil(float(iCount) * g_flVoteGagRatio);
    if(iRequired < g_iVoteGagMinimum)
    {
        iRequired = g_iVoteGagMinimum;
    }

    return iRequired;
}

public int PlayersVotes_GetGagVotesForTarget(int iTarget)
{
    int iVotes;
    for(int i = 1; i <= MAXPLAYERS; i++)
    {
        if(g_bVoteGagFor[i][iTarget])
        {
            iVotes++;
        }
    }
    return iVotes;
}

public void PlayersVotes_GagPlayer(int iClient)
{
    BaseComm_SetClientGag(iClient, true);
}

/*********************
**     SILENCE      **
**********************/
public void PlayersVotes_ResetSilenceVotes()
{
    for(int iClient = 0; iClient <= MAXPLAYERS; ++iClient)
    {
        for(int iTarget = 0; iTarget <= MAXPLAYERS; ++iTarget)
        {
            g_bVoteSilenceFor[iClient][iTarget] = false;
        }
    }
}

public void PlayersVotes_CheckSilenceVotes(int iVoter, int iTarget)
{
    int iVotesRequired = PlayersVotes_GetRequiredSilenceVotes(iVoter);
    int iVotes = PlayersVotes_GetSilenceVotesForTarget(iTarget);

    char strVoterName[65];
    GetClientName(iVoter, strVoterName, sizeof(strVoterName));

    char strTargetName[65];
    GetClientName(iTarget, strTargetName, sizeof(strTargetName));

    PrintToChatAll("[SM] %t.", "voted to silence", strVoterName, strTargetName);

    if(iVotes < iVotesRequired)
    {
        PrintToChatAll("[SM] %t.", "votes required", iVotes, iVotesRequired);
        return;
    }

    PrintToChatAll("[SM] %t.", "silenced by vote", strTargetName);
    LogAction(-1, iTarget, "Vote silence successful, silenced (mute + gag) \"%L\" (iReason \"voted by players\")", iTarget);
    g_bVoteSilenceSilenced[iTarget] = true;
    char strClientAuth[STEAM_NAME_LENGTH];
    PlayersVotes_GetIdentity(iTarget, strClientAuth, sizeof(strClientAuth));
    PushArrayString(g_hArrayVoteSilenceClientIdentity, strClientAuth);
    PlayersVotes_SilencePlayer(iTarget);
}

public int PlayersVotes_GetRequiredSilenceVotes(int iVoter)
{
    int iCount;
    for(int i = 1; i <= MaxClients; i++) 
    {
        if(IsClientInGame(i))
        {
            if(IsFakeClient(i))
            {
                continue;
            }

            if(g_bVoteSilenceTeam && GetClientTeam(i) != GetClientTeam(iVoter))
            {
                continue;
            }

            iCount++;
        }
    }

    int iRequired = RoundToCeil(float(iCount) * g_flVoteSilenceRatio);
    if(iRequired < g_iVoteSilenceMinimum)
    {
        iRequired = g_iVoteSilenceMinimum;
    }

    return iRequired;
}

public int PlayersVotes_GetSilenceVotesForTarget(int iTarget)
{
    int iVotes;
    for(int i = 1; i <= MAXPLAYERS; i++)
    {
        if(g_bVoteSilenceFor[i][iTarget])
        {
            iVotes++;
        }
    }
    return iVotes;
}

public void PlayersVotes_SilencePlayer(int iClient)
{
    BaseComm_SetClientMute(iClient, true);
    BaseComm_SetClientGag(iClient, true);
}

///////////////////////////////////
//===============================//
//=====[ STOCKS ]================//
//===============================//
///////////////////////////////////
stock bool IsValidClient(int iClient)
{
    if(iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
    {
        return false;
    }
    return true;
}

stock bool PlayersVotes_IsValidAuth(const char[] strClientAuth)
{
    return (strcmp(strClientAuth, "STEAM_ID_LAN", false) != 0) && (strcmp(strClientAuth, "STEAM_ID_PENDING", false) != 0);
}

stock int PlayersVotes_MatchIdentity(const Handle hIdentityArray, const char[] strIdentity)
{
    char strStoredIdentity[STEAM_NAME_LENGTH];
    for(int i = 0; i < GetArraySize(hIdentityArray); ++i)
    {
        GetArrayString(hIdentityArray, i, strStoredIdentity, sizeof(strStoredIdentity));
        if(strcmp(strIdentity, strStoredIdentity, false) == 0)
        {
            return i;
        }
    }
    return -1;
}

stock bool PlayersVotes_GetIdentity(int iClient, char[] strClientIdentity, int iClientIdentitySize)
{
    GetClientAuthId(iClient, AuthId_Steam2, strClientIdentity, iClientIdentitySize);
    if(!IsClientAuthorized(iClient) || !PlayersVotes_IsValidAuth(strClientIdentity))
    {
        GetClientIP(iClient, strClientIdentity, iClientIdentitySize);
        return false;
    }
    return true;
}