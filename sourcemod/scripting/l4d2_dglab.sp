#include <sourcemod>
#include <sdktools>
#include <steamworks>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
    name = "L4D2 DG-LAB Bridge V2 (CFG Edition)",
    author = "Nya_Fish",
    description = "Connects L4D2 events to DG-Lab with CFG support",
    version = "2.1.0",
    url = ""
};

// --- ConVars 句柄 ---
ConVar g_cvEnable;
ConVar g_cvHost;
// 强度变量
ConVar g_cvHurtStrength;
ConVar g_cvIncapStrength;
ConVar g_cvDeathStrength;
// 时间变量 (毫秒)
ConVar g_cvHurtTime;
ConVar g_cvIncapTime;
ConVar g_cvDeathTime;

public void OnPluginStart() {
    // 基础设置
    g_cvEnable = CreateConVar("sm_dglab_enable", "1", "是否启用插件 (0/1)");
    g_cvHost   = CreateConVar("sm_dglab_url", "http://127.0.0.1:8920", "Hub的根地址");
    
    // 强度设置 (默认值设为你之前的数值)
    g_cvHurtStrength  = CreateConVar("sm_dglab_hurt_power", "20", "受伤时的电击强度 (0-100)");
    g_cvIncapStrength = CreateConVar("sm_dglab_incap_power", "50", "倒地时的电击强度 (0-100)");
    g_cvDeathStrength = CreateConVar("sm_dglab_death_power", "100", "死亡时的电击强度 (0-100)");
    
    // 时间设置 (单位：毫秒)
    g_cvHurtTime  = CreateConVar("sm_dglab_hurt_time", "1000", "受伤电击持续时间");
    g_cvIncapTime = CreateConVar("sm_dglab_incap_time", "5000", "倒地电击持续时间");
    g_cvDeathTime = CreateConVar("sm_dglab_death_time", "10000", "死亡电击持续时间");
    
    // 监听事件
    HookEvent("player_hurt", Event_PlayerHurt);
    HookEvent("player_incapacitated", Event_PlayerIncap);
    HookEvent("player_death", Event_PlayerDeath);
    
    // 关键：自动生成并执行配置文件
    // 文件将生成在: left4dead2/cfg/sourcemod/l4d2_dglab_v2.cfg
    AutoExecConfig(true, "l4d2_dglab_v2");
}

void SendFireAction(int strength, int timeMs) {
    if (!g_cvEnable.BoolValue) return;

    char baseUrl[256];
    g_cvHost.GetString(baseUrl, sizeof(baseUrl));
    
    char fullUrl[512];
    Format(fullUrl, sizeof(fullUrl), "%s/api/v2/game/all/action/fire", baseUrl);

    Handle req = SteamWorks_CreateHTTPRequest(k_EHTTPMethodPOST, fullUrl);
    
    char json[256];
    Format(json, sizeof(json), "{\"strength\": %d, \"time\": %d, \"override\": true}", strength, timeMs);
    
    SteamWorks_SetHTTPRequestRawPostBody(req, "application/json", json, strlen(json));
    SteamWorks_SetHTTPRequestHeaderValue(req, "Accept", "application/json");
    SteamWorks_SendHTTPRequest(req);
}

// --- 事件触发：改为从 ConVar 获取数值 ---

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast) {
    int victim = GetClientOfUserId(event.GetInt("userid"));
    if (victim > 0 && IsClientInGame(victim) && !IsFakeClient(victim)) {
        SendFireAction(g_cvHurtStrength.IntValue, g_cvHurtTime.IntValue);
    }
}

public void Event_PlayerIncap(Event event, const char[] name, bool dontBroadcast) {
    int victim = GetClientOfUserId(event.GetInt("userid"));
    if (victim > 0 && !IsFakeClient(victim)) {
        SendFireAction(g_cvIncapStrength.IntValue, g_cvIncapTime.IntValue);
    }
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
    int victim = GetClientOfUserId(event.GetInt("userid"));
    if (victim > 0 && !IsFakeClient(victim)) {
        SendFireAction(g_cvDeathStrength.IntValue, g_cvDeathTime.IntValue);
    }
}