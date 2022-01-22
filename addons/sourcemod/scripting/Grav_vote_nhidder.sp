#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <multicolors>

#define PLUGIN_VERSION "1.0"
#define VOTE_NO "###no###"
#define VOTE_YES "###yes###"

new StartTime;
new LastVote;
new Handle:g_cvarVoteDelay;
new Handle:g_cvarVotesInterval;
ConVar g_CVar_sv_gravity;
ConVar g_CVar_sv_airaccelerate;
ConVar g_cvarGravVotePercent = null;

public Plugin:myinfo =
{
	name = "Gravity Vote and hide sv_tags change",
	author = ".Rushaway",
	description = "If you read this you are fucking gay and if you keep reading you are dumb",
	version = PLUGIN_VERSION,
	url = "https://nide.gg/"
};

public void OnPluginStart()
{
	LoadTranslations("basevotes.phrases");
	LoadTranslations("common.phrases"); 
	
	g_CVar_sv_gravity = FindConVar("sv_gravity");
	g_CVar_sv_airaccelerate = FindConVar("sv_airaccelerate");
	g_cvarVotesInterval = CreateConVar("sm_grav_vote_interval", "300.0", "Interval in seconds between vote casts.", FCVAR_NONE, true, 0.0, true, 1200.0);
	g_cvarVoteDelay= CreateConVar("sm_grav_vote_delay","13.0", "Time in minutes before the GravityMod vote is allowed after map start.", FCVAR_NONE, true, 0.0, true, 1440.0);
	g_cvarGravVotePercent = CreateConVar("sm_grav_vote_percent", "0.7", "Percentage of \"yes\" votes required to consider the vote successful", FCVAR_NONE, true, 0.05, true, 1.0);
	
	RegAdminCmd("sm_grav",	Command_GravVote, ADMFLAG_BAN, "Start a vote for enabled GravityMod" );
	RegAdminCmd("sm_gravitymod",	Command_GravVote, ADMFLAG_BAN, "Start a vote for enabled GravityMod" );
	RegAdminCmd("sm_forcegrav", Command_Forcegrav, ADMFLAG_CONVARS, "Force GravityMod 1/0");
	RegAdminCmd("sm_fgrav", Command_Forcegrav, ADMFLAG_CONVARS, "Force GravityMod 1/0");
	RegAdminCmd("sm_fgravity", Command_Forcegrav, ADMFLAG_CONVARS, "Force GravityMod 1/0");
	
	AutoExecConfig(true);
	
	new flags, Handle:cvar = FindConVar("sv_tags");
    
    flags = GetConVarFlags(cvar);
    flags &= ~FCVAR_NOTIFY;
    SetConVarFlags(cvar, flags);

    CloseHandle(cvar);
}

public OnMapStart()
{
	StartTime = GetTime();
}

public Action:Command_Forcegrav(client, Arguments)
{
	//Error Check:
	if(Arguments < 1)
	{
		CPrintToChat(client, "{green}[SM] {default}Usage: sm_forcegrav {fullred}1/0");
		CPrintToChat(client, "{green}[SM] {default}Or Usage: sm_fgrav {fullred}1/0");
		return Plugin_Handled;
	}

	//Retrieve Arguments:
	new String:Given_Grav[32], Changer_Grav;
	GetCmdArg(1, Given_Grav, sizeof(Given_Grav));
		
	//Convert:
	StringToIntEx(Given_Grav, Changer_Grav);
	
	char User[32];
	GetClientName(client,User,32);

	if(Changer_Grav == 1)
	{
		CPrintToChatAll("{green}[SM] {default}%s {fullred}forced {default}GravityMod", User);
		LogAction(client, -1, "\"%s\" Forced GravityMod ON.", User);
		SetConVarInt(g_CVar_sv_gravity, 200);
		SetConVarInt(g_CVar_sv_airaccelerate, 150);
	}

	if(Changer_Grav == 0)
	{
		CPrintToChatAll("{green}[SM] {default}%s {fullred}disabled {default}GravityMod", User);
		LogAction(client, -1, "\"%s\" Forced GravityMod OFF.", User);
		SetConVarInt(g_CVar_sv_gravity, 800);
		SetConVarInt(g_CVar_sv_airaccelerate, 12);
	}

	return Plugin_Handled;
}

public Action:Command_GravVote(int client, int argc)
{
	if (IsVoteInProgress())
	{
		CPrintToChat( client ,"{green}[SM] {default}Vote is in Progress...");
		return Plugin_Handled;
	}

	new nFromStart = GetTime() - StartTime;
	new nFromLast = GetTime() - LastVote;	

	new sv_gravity = GetConVarInt(g_CVar_sv_gravity);
	if(nFromLast >= GetConVarInt(g_cvarVotesInterval))
	{
		if(nFromStart >= GetConVarInt(g_cvarVoteDelay))
		{
			if(sv_gravity == 800)
			{
				Menu hVoteMenu = new Menu(Handler_VoteCallback, MenuAction_End|MenuAction_DisplayItem|MenuAction_VoteCancel|MenuAction_VoteEnd);
				hVoteMenu.SetTitle("Turn ON Gravity Mod?");
				hVoteMenu.AddItem(VOTE_YES, "Yes !! PLS ADMUN!!");
				hVoteMenu.AddItem(VOTE_NO, "No Thanks !");
				hVoteMenu.ExitButton = false;
				hVoteMenu.DisplayVoteToAll(20);
			}
			if(sv_gravity == 200)
			{
				Menu hVoteMenu = new Menu(Handler_VoteCallback, MenuAction_End|MenuAction_DisplayItem|MenuAction_VoteCancel|MenuAction_VoteEnd);
				hVoteMenu.SetTitle("Go back with Normal Gravity ?");
				hVoteMenu.AddItem(VOTE_YES, "Yes! Pleaseee!!");
				hVoteMenu.AddItem(VOTE_NO, "No we wanna keep it !");
				hVoteMenu.ExitButton = false;
				hVoteMenu.DisplayVoteToAll(20);
			}
			LastVote = GetTime();
			ShowActivity2(client, "[SM] ", "Initiated an GravityMod vote");
			LogAction(client, -1, "\"%L\" initiated an GravityMod vote.", client);
		}
		else
		{
			CPrintToChat( client ,"{green}[SM] {default}Gravity vote not allowed yet.");
		}
	}
	else
	{
		CPrintToChat( client ,"{green}[SM] {default}Gravity vote is on Cooldown between 2 votes.");
	}
	return Plugin_Handled;
}

public int Handler_VoteCallback(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_DisplayItem)
	{
		char display[64];
		menu.GetItem(param2, "", 0, _, display, sizeof(display));

	 	if (strcmp(display, VOTE_NO) == 0 || strcmp(display, VOTE_YES) == 0)
	 	{
			char buffer[255];
			Format(buffer, sizeof(buffer), "%T", display, param1);

			return RedrawMenuItem(buffer);
		}
	}
	else if (action == MenuAction_VoteCancel && param1 == VoteCancel_NoVotes)
	{
		CPrintToChatAll("{green}[SM]{default} %t", "No Votes Cast");
	}
	else if (action == MenuAction_VoteEnd)
	{
		char item[64], display[64];
		float percent, limit;
		int votes, totalVotes;

		new sv_gravity = GetConVarInt(g_CVar_sv_gravity);
		GetMenuVoteInfo(param2, votes, totalVotes);
		menu.GetItem(param1, item, sizeof(item), _, display, sizeof(display));

		if (strcmp(item, VOTE_NO) == 0)
		{
			votes = totalVotes - votes;
		}

		limit = g_cvarGravVotePercent.FloatValue;
		percent = float(votes) / float(totalVotes);

		if ((strcmp(item, VOTE_YES) == 0 && FloatCompare(percent, limit) < 0) || strcmp(item, VOTE_NO) == 0)
		{
			LogAction(-1, -1, "GravityMod Vote failed.");
			CPrintToChatAll("{green}[SM] {default}%t", "Vote Failed", RoundToNearest(100.0 * limit), RoundToNearest(100.0 * percent), totalVotes);
		}

		else if (sv_gravity == 200)
		{	
				LogAction(-1, -1, "GravityMod Vote successful, Disable GravityMod");
				CPrintToChatAll("{green}[SM] {default}%t", "Vote Successful", RoundToNearest(100.0 * percent), totalVotes);
				CPrintToChatAll("{green}[SM] {default}GravityMod is now {fullred}Disabled");
				SetConVarInt(g_CVar_sv_gravity, 800);
				SetConVarInt(g_CVar_sv_airaccelerate, 12);
		 }
		else if (sv_gravity == 800)
		{
				LogAction(-1, -1, "GravityMod Vote successful, Enable GravityMod");
				CPrintToChatAll("{green}[SM] {default}%t", "Vote Successful", RoundToNearest(100.0 * percent), totalVotes);
				CPrintToChatAll("{green}[SM] {default}GravityMod is now {fullred}Enabled");
				SetConVarInt(g_CVar_sv_gravity, 200);
				SetConVarInt(g_CVar_sv_airaccelerate, 150);
		}
		if (strcmp(item, VOTE_NO) == 0 || strcmp(item, VOTE_YES) == 0)
			{
			strcopy(item, sizeof(item), display);
			}
	}
	
	return 0;	
}
