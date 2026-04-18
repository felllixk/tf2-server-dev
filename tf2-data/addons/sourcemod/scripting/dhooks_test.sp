#include <sourcemod>
#include <dhooks>
#include <logger>

#define PLUGIN_VERSION "1.0.0"

public Plugin myinfo =
{
    name        = "DHooks Test – CTFPlayer::Regenerate",
    author      = "felllixk",
    description = "Проверяет работу DHooks DynamicDetour на 64-бит сервере",
    version     = PLUGIN_VERSION,
    url         = ""
};

// Обёртка для DynamicDetour::Enable/Disable
static DynamicDetour g_hDetourRegenerate = null;

public void OnPluginStart()
{
    Logger_Init("dhooks_test", LOG_DEBUG);

    // Загружаем наш custom gamedata файл
    GameData gd = new GameData("custom/dhooks_test.games");
    if (gd == null)
    {
        Log_Err("Не удалось загрузить gamedata custom/dhooks_test.games!");
        SetFailState("Gamedata not found");
        return;
    }

    // Создаём DynamicDetour по имени из секции "Functions"
    g_hDetourRegenerate = DynamicDetour.FromConf(gd, "CTFPlayer::Regenerate");
    delete gd;

    if (g_hDetourRegenerate == null)
    {
        Log_Err("DynamicDetour.FromConf не смог найти CTFPlayer::Regenerate!");
        SetFailState("Detour setup failed");
        return;
    }

    // Включаем хук — Pre (до того как оригинальная функция выполнится)
    if (!g_hDetourRegenerate.Enable(Hook_Pre, Detour_OnRegenerate_Pre))
    {
        Log_Err("Не удалось активировать Pre-хук Regenerate!");
        SetFailState("Detour enable failed");
        return;
    }

    // Post — после выполнения оригинальной функции
    if (!g_hDetourRegenerate.Enable(Hook_Post, Detour_OnRegenerate_Post))
    {
        Log_Err("Не удалось активировать Post-хук Regenerate!");
        SetFailState("Detour post enable failed");
        return;
    }

    Log_Info("DHooks DynamicDetour успешно установлен на CTFPlayer::Regenerate ✓");
    PrintToServer("[DHooksTest] Хук Regenerate активен. Возьми resupply — увидишь логи.");
}

public void OnPluginEnd()
{
    // Отключаем хуки при выгрузке плагина
    if (g_hDetourRegenerate != null)
    {
        g_hDetourRegenerate.Disable(Hook_Pre, Detour_OnRegenerate_Pre);
        g_hDetourRegenerate.Disable(Hook_Post, Detour_OnRegenerate_Post);
        Log_Info("DHooks хук Regenerate отключён.");
    }
}

// ─── Pre-хук: вызывается ДО оригинальной функции ─────────────────────────────
public MRESReturn Detour_OnRegenerate_Pre(int player, DHookParam hParams)
{
    // hParams.Get(1) — первый аргумент: bool bFull
    bool bFull = view_as<bool>(hParams.Get(1));

    char name[64];
    if (IsValidClient(player))
        GetClientName(player, name, sizeof(name));
    else
        Format(name, sizeof(name), "entity#%d", player);

    ForcePlayerSuicide(player);
    Log_Debug("[PRE]  Regenerate(%s, bFull=%s) — ЗАБЛОКИРОВАНО!", name, bFull ? "true" : "false");

    // MRES_Supercede — оригинальная функция НЕ вызывается, шкафчик не работает
    return MRES_Supercede;
}

// ─── Post-хук: вызывается ПОСЛЕ оригинальной функции ─────────────────────────
public MRESReturn Detour_OnRegenerate_Post(int player, DHookParam hParams)
{
    bool bFull = view_as<bool>(hParams.Get(1));

    char name[64];
    if (IsValidClient(player))
        GetClientName(player, name, sizeof(name));
    else
        Format(name, sizeof(name), "entity#%d", player);

    Log_Info("[POST] Regenerate завершён: %s (bFull=%s) ✓", name, bFull ? "true" : "false");

    // В чат самому игроку (только если это реальный клиент)
    if (IsValidClient(player) && !IsFakeClient(player))
        PrintToChat(player, " \x01[\x04DHooksTest\x01] Regenerate перехвачен! bFull=\x05%s", bFull ? "true" : "false");

    return MRES_Ignored;
}

// ─── Хелпер ───────────────────────────────────────────────────────────────────

stock bool IsValidClient(int client)
{
    return (client >= 1 && client <= MaxClients && IsClientInGame(client));
}
