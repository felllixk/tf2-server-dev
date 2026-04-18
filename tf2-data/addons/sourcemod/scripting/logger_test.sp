#include <sourcemod>
#include <logger>
#include <dhooks>
#define PLUGIN_VERSION "1.0.0"

public Plugin myinfo =
{
    name        = "Logger Test",
    author      = "felllixk",
    description = "Тест библиотеки logger.inc",
    version     = PLUGIN_VERSION,
    url         = ""
};

public void OnPluginStart()
{
    // Инициализируем логгер с тегом и уровнем по умолчанию
    Logger_Init("logtest", LOG_DEBUG);

    Log_Info("Плагин загружен, версия %s", PLUGIN_VERSION);
    Log_Debug("Это дебаг-сообщение, видно только при LOG_DEBUG");
    Log_Info("Плагин загружен, версия %s", PLUGIN_VERSION);
    Log_Warn("Тестовое предупреждение");
    Log_Err("Тестовая ошибка (не паникуй, это тест)");

    RegConsoleCmd("sm_logtest", Cmd_LogTest, "Тест логирования");
}

public Action Cmd_LogTest(int client, int args)
{
    Log_Debug("Команда вызвана клиентом %d", client);
    Log_Info("Текущий уровень лога: %d", view_as<int>(Logger_GetLevel()));

    if (args >= 1)
    {
        char arg[16];
        GetCmdArg(1, arg, sizeof(arg));
        int newLevel = StringToInt(arg);
        Logger_SetLevel(view_as<LogLevel>(newLevel));
        Log_Info("Уровень лога изменён на %d", newLevel);
    }

    ReplyToCommand(client, "[LogTest] Проверь логи в addons/sourcemod/logs/");
    return Plugin_Handled;
}
