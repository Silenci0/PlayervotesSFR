/**
 * vim: set ts=4 :
 * =============================================================================
 * SourceMod Basic Votes Plugin
 * Implements basic vote commands.
 *
 * SourceMod (C)2004-2008 AlliedModders LLC.  All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */

#pragma semicolon 1

#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <adminmenu>

public Plugin:myinfo =
{
	name = "Admin Votes",
	author = "AlliedModders LLC",
	description = "Admin vote commands",
	version = SOURCEMOD_VERSION,
	url = "http://www.sourcemod.net/"
};

#define VOTE_NO "###no###"
#define VOTE_YES "###yes###"

Menu g_hVoteMenu = null;

ConVar g_Cvar_Limits[3] = {null, ...};

enum voteType
{
	question
}

new voteType:g_voteType = voteType:question;

// Menu API does not provide us with a way to pass multiple peices of data with a single
// choice, so some globals are used to hold stuff.
//
#define VOTE_CLIENTID	0
#define VOTE_USERID	1
//new g_voteClient[2];		/* Holds the target's client id and user id */

#define VOTE_NAME	0
#define VOTE_AUTHID	1
#define	VOTE_IP		2
new String:g_voteInfo[3][65];	/* Holds the target's name, authid, and IP */

new String:g_voteArg[256];	/* Used to hold ban/kick reasons or vote questions */

TopMenu hTopMenu;

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("basevotes.phrases");
	LoadTranslations("plugin.basecommands");
	LoadTranslations("basebans.phrases");
	
	RegAdminCmd("sm_vote", Command_Vote, ADMFLAG_VOTE, "sm_vote <question> [Answer1] [Answer2] ... [Answer5]");	
	
	/* Account for late loading */
	TopMenu topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != null))
	{
		OnAdminMenuReady(topmenu);
	}
}

public OnAdminMenuReady(Handle aTopMenu)
{
	TopMenu topmenu = TopMenu.FromHandle(aTopMenu);

	/* Block us from being called twice */
	if (topmenu == hTopMenu)
	{
		return;
	}
	
	/* Save the Handle */
	hTopMenu = topmenu;
}

public Action:Command_Vote(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_vote <question> [Answer1] [Answer2] ... [Answer5]");
		return Plugin_Handled;	
	}
	
	if (IsVoteInProgress())
	{
		ReplyToCommand(client, "[SM] %t", "Vote in Progress");
		return Plugin_Handled;
	}
		
	if (!TestVoteDelay(client))
	{
		return Plugin_Handled;
	}
	
	decl String:text[256];
	GetCmdArgString(text, sizeof(text));

	decl String:answers[5][64];
	new answerCount;	
	new len = BreakString(text, g_voteArg, sizeof(g_voteArg));
	new pos = len;
	
	while (args > 1 && pos != -1 && answerCount < 5)
	{	
		pos = BreakString(text[len], answers[answerCount], sizeof(answers[]));
		answerCount++;
		
		if (pos != -1)
		{
			len += pos;
		}	
	}

	LogAction(client, -1, "\"%L\" initiated a generic vote.", client);
	ShowActivity2(client, "[SM] ", "%t", "Initiate Vote", g_voteArg);
	
	g_voteType = voteType:question;
	
	g_hVoteMenu = CreateMenu(Handler_VoteCallback, MenuAction:MENU_ACTIONS_ALL);
	g_hVoteMenu.SetTitle("%s?", g_voteArg);
	
	if (answerCount < 2)
	{
		g_hVoteMenu.AddItem(VOTE_YES, "Yes");
		g_hVoteMenu.AddItem(VOTE_NO, "No");
	}
	else
	{
		for (new i = 0; i < answerCount; i++)
		{
			g_hVoteMenu.AddItem(answers[i], answers[i]);
		}	
	}
	
	g_hVoteMenu.ExitButton = false;
	g_hVoteMenu.DisplayVoteToAll(20);		
	
	return Plugin_Handled;	
}

public Handler_VoteCallback(Menu menu, MenuAction action, param1, param2)
{
	if (action == MenuAction_End)
	{
		VoteMenuClose();
	}
	else if (action == MenuAction_Display)
	{
	 	if (g_voteType != voteType:question)
	 	{
			char title[64];
			menu.GetTitle(title, sizeof(title));
			
	 		char buffer[255];
			Format(buffer, sizeof(buffer), "%T", title, param1, g_voteInfo[VOTE_NAME]);

			Panel panel = Panel:param2;
			panel.SetTitle(buffer);
		}
	}
	else if (action == MenuAction_DisplayItem)
	{
		decl String:display[64];
		menu.GetItem(param2, "", 0, _, display, sizeof(display));
	 
	 	if (strcmp(display, "No") == 0 || strcmp(display, "Yes") == 0)
	 	{
			decl String:buffer[255];
			Format(buffer, sizeof(buffer), "%T", display, param1);

			return RedrawMenuItem(buffer);
		}
	}
	else if (action == MenuAction_VoteCancel && param1 == VoteCancel_NoVotes)
	{
		PrintToChatAll("[SM] %t", "No Votes Cast");
	}	
	else if (action == MenuAction_VoteEnd)
	{
		char item[64], display[64];
		float percent, limit;
		int votes, totalVotes;

		GetMenuVoteInfo(param2, votes, totalVotes);
		menu.GetItem(param1, item, sizeof(item), _, display, sizeof(display));
		
		if (strcmp(item, VOTE_NO) == 0 && param1 == 1)
		{
			votes = totalVotes - votes; // Reverse the votes to be in relation to the Yes option.
		}
		
		percent = GetVotePercent(votes, totalVotes);
		
		if (g_voteType != voteType:question)
		{
			limit = g_Cvar_Limits[g_voteType].FloatValue;
		}
		
		/* :TODO: g_voteClient[userid] needs to be checked */

		// A multi-argument vote is "always successful", but have to check if its a Yes/No vote.
		if ((strcmp(item, VOTE_YES) == 0 && FloatCompare(percent,limit) < 0 && param1 == 0) || (strcmp(item, VOTE_NO) == 0 && param1 == 1))
		{
			/* :TODO: g_voteClient[userid] should be used here and set to -1 if not applicable.
			 */
			LogAction(-1, -1, "Vote failed.");
			PrintToChatAll("[SM] %t", "Vote Failed", RoundToNearest(100.0*limit), RoundToNearest(100.0*percent), totalVotes);
		}
		else
		{
			PrintToChatAll("[SM] %t", "Vote Successful", RoundToNearest(100.0*percent), totalVotes);
			
			switch (g_voteType)
			{
				case (voteType:question):
				{
					if (strcmp(item, VOTE_NO) == 0 || strcmp(item, VOTE_YES) == 0)
					{
						strcopy(item, sizeof(item), display);
					}
					
					PrintToChatAll("[SM] %t", "Vote End", g_voteArg, item);
				}
			}
		}
	}
	
	return 0;
}

VoteMenuClose()
{
	delete g_hVoteMenu;
	g_hVoteMenu = null;
}

Float:GetVotePercent(votes, totalVotes)
{
	return FloatDiv(float(votes),float(totalVotes));
}

bool:TestVoteDelay(client)
{
 	new delay = CheckVoteDelay();
 	
 	if (delay > 0)
 	{
 		if (delay > 60)
 		{
 			ReplyToCommand(client, "[SM] %t", "Vote Delay Minutes", delay % 60);
 		}
 		else
 		{
 			ReplyToCommand(client, "[SM] %t", "Vote Delay Seconds", delay);
 		}
 		
 		return false;
 	}
 	
	return true;
}