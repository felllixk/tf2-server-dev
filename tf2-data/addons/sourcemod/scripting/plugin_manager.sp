#include <sourcemod>
#include <logger>

#define PLUGIN_VERSION "1.0.0"

public Plugin myinfo =
{
    name        = "Plugin Manager",
    author      = "felllixk",
    description = "Меню для управления плагинами (перезагрузка без рестарта сервера)",
    version     = PLUGIN_VERSION,
    url         = ""
};

// Хранит имя файла плагина, выбранного для перезагрузки
static char g_sPendingPlugin[256];

public void OnPluginStart()
{
    Logger_Init("pluginmgr", LOG_INFO);
    Logger_SetChatOutput(true);    // дублировать INFO/WARN/ERROR в чат всем

    RegAdminCmd("sm_plugins_menu", Cmd_PluginsMenu, ADMFLAG_ROOT, "Открыть меню управления плагинами");
    RegAdminCmd("sm_preload", Cmd_ReloadPlugin, ADMFLAG_ROOT, "Перезагрузить плагин по имени файла: sm_preload <file.smx>");

    Log_Info("Plugin Manager v%s загружен", PLUGIN_VERSION);
}

// ─── Команда открытия меню ────────────────────────────────────────────────────
public Action Cmd_PluginsMenu(int client, int args)
{
    if (client == 0)
    {
        ReplyToCommand(client, "[PluginMgr] Эта команда доступна только из игры.");
        return Plugin_Handled;
    }

    ShowPluginListMenu(client);
    return Plugin_Handled;
}

// ─── Список плагинов ──────────────────────────────────────────────────────────

void ShowPluginListMenu(int client)
{
    Menu menu = new Menu(Handler_PluginList, MenuAction_Select | MenuAction_End);
    menu.SetTitle("Список плагинов (выбери для перезагрузки)");

    Handle iter = GetPluginIterator();
    while (MorePlugins(iter))
    {
        Handle pl = ReadPlugin(iter);

        char   filename[256];
        GetPluginFilename(pl, filename, sizeof(filename));

        char displayName[256];
        char pluginName[128];
        GetPluginInfo(pl, PlInfo_Name, pluginName, sizeof(pluginName));

        // Показываем: "Имя плагина  [file.smx]"
        // Извлекаем только имя файла без пути
        char shortFile[128];
        int  slash = -1;
        for (int i = strlen(filename) - 1; i >= 0; i--)
        {
            if (filename[i] == '/' || filename[i] == '\\')
            {
                slash = i;
                break;
            }
        }
        strcopy(shortFile, sizeof(shortFile), filename[slash + 1]);

        Format(displayName, sizeof(displayName), "%s  [%s]", pluginName, shortFile);
        menu.AddItem(shortFile, displayName);
    }
    delete iter;

    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int Handler_PluginList(Menu menu, MenuAction action, int client, int param2)
{
    if (action == MenuAction_Select)
    {
        char filename[256];
        menu.GetItem(param2, filename, sizeof(filename));

        // Сохраняем выбранный плагин и показываем подтверждение
        strcopy(g_sPendingPlugin, sizeof(g_sPendingPlugin), filename);
        ShowConfirmMenu(client, filename);
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
    return 0;
}

// ─── Меню подтверждения перезагрузки ─────────────────────────────────────────

void ShowConfirmMenu(int client, const char[] filename)
{
    char title[256];
    Format(title, sizeof(title), "Перезагрузить плагин?\n%s", filename);

    Menu menu = new Menu(Handler_Confirm, MenuAction_Select | MenuAction_End);
    menu.SetTitle(title);
    menu.AddItem("yes", "✓ Да, перезагрузить");
    menu.AddItem("no", "✗ Нет, отмена");
    menu.ExitButton = false;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int Handler_Confirm(Menu menu, MenuAction action, int client, int param2)
{
    if (action == MenuAction_Select)
    {
        char choice[8];
        menu.GetItem(param2, choice, sizeof(choice));

        if (StrEqual(choice, "yes"))
        {
            ReloadPluginByFile(client, g_sPendingPlugin);
        }
        else
        {
            PrintToChat(client, " \x01[\x04PluginMgr\x01] Перезагрузка отменена.");
            ShowPluginListMenu(client);    // возвращаемся к списку
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
    return 0;
}

// ─── Перезагрузка плагина ─────────────────────────────────────────────────────

void ReloadPluginByFile(int client, const char[] filename)
{
    // Ищем загруженный плагин по имени файла
    Handle targetPlugin = null;
    Handle iter         = GetPluginIterator();
    while (MorePlugins(iter))
    {
        Handle pl = ReadPlugin(iter);
        char   plFile[256];
        GetPluginFilename(pl, plFile, sizeof(plFile));

        // Сравниваем только короткое имя файла
        char shortFile[128];
        int  slash = -1;
        for (int i = strlen(plFile) - 1; i >= 0; i--)
        {
            if (plFile[i] == '/' || plFile[i] == '\\')
            {
                slash = i;
                break;
            }
        }
        strcopy(shortFile, sizeof(shortFile), plFile[slash + 1]);

        if (StrEqual(shortFile, filename, false))
        {
            targetPlugin = pl;
            break;
        }
    }
    delete iter;

    if (targetPlugin == null)
    {
        // Плагин не найден среди загруженных — пробуем просто загрузить
        Log_Warn("Плагин %s не найден среди загруженных, пробуем загрузить...", filename);
        ServerCommand("sm plugins load %s", filename);

        if (client != 0)
            PrintToChat(client, " \x01[\x04PluginMgr\x01] \x05%s\x01 не был загружен — выполнена загрузка.", filename);

        Log_Info("Загрузка плагина: %s (запрос от клиента %d)", filename, client);
        return;
    }

    // Перезагружаем — unload и load в одном буфере, выполняются по порядку
    Log_Info("Перезагрузка плагина: %s (запрос от клиента %d)", filename, client);
    ServerCommand("sm plugins unload %s", filename);
    ServerCommand("sm plugins load %s", filename);

    if (client != 0)
        PrintToChat(client, " \x01[\x04PluginMgr\x01] \x04✓\x01 Плагин \x05%s\x01 перезагружен!", filename);

    Log_Info("Команда reload отправлена для плагина: %s", filename);
}

// ─── Консольная команда быстрой перезагрузки ─────────────────────────────────
public Action Cmd_ReloadPlugin(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, "[PluginMgr] Использование: sm_preload <file.smx>");
        return Plugin_Handled;
    }

    char filename[256];
    GetCmdArg(1, filename, sizeof(filename));

    ReloadPluginByFile(client, filename);
    return Plugin_Handled;
}
