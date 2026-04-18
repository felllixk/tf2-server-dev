/**
 * logger.inc - Удобная библиотека логирования и дебага для SourceMod плагинов.
 *
 * Использование:
 *   1. Поместите этот файл в scripting/include/
 *   2. Добавьте в свой плагин: #include <logger>
 *   3. В OnPluginStart вызовите: Logger_Init("myplugin");
 *
 * Уровни логирования (LogLevel):
 *   LOG_NONE  (0) - логирование отключено
 *   LOG_ERROR (1) - только ошибки
 *   LOG_WARN  (2) - предупреждения и выше
 *   LOG_INFO  (3) - информационные сообщения и выше
 *   LOG_DEBUG (4) - всё, включая отладочные сообщения
 *
 * Пример:
 *   Logger_Init("myplugin");
 *   Log_Info("Плагин загружен, версия %s", PLUGIN_VERSION);
 *   Log_Debug("Игрок %d подключился, steamid: %s", client, steamid);
 *   Log_Warn("Конфиг не найден, используем defaults");
 *   Log_Err("Не удалось создать таймер!");
 */

#if defined _logger_included
    #endinput
#endif
#define _logger_included

// ─── Уровни логирования ───────────────────────────────────────────────────────

enum LogLevel
{
    LOG_NONE  = 0,
    LOG_ERROR = 1,
    LOG_WARN  = 2,
    LOG_INFO  = 3,
    LOG_DEBUG = 4,
}

// ─── Внутренние переменные ────────────────────────────────────────────────────

static ConVar g_cvLogLevel                  = null;
static char   g_sLogTag[64]                 = "plugin";
static char   g_sLogFile[PLATFORM_MAX_PATH] = "";
static bool   g_bPrintToChat                = false;    // выводить ли INFO/WARN/ERROR в чат всем игрокам

// ─── Инициализация ────────────────────────────────────────────────────────────

/**
 * Инициализирует логгер. Вызывай в OnPluginStart().
 *
 * @param tag         Короткое имя плагина, будет появляться в логах: [tag]
 * @param defaultLevel  Уровень логирования по умолчанию (LOG_INFO рекомендуется для прода)
 */
stock void    Logger_Init(const char[] tag, LogLevel defaultLevel = LOG_INFO)
{
    strcopy(g_sLogTag, sizeof(g_sLogTag), tag);

    // Путь к файлу лога: logs/tag-YYYY-MM-DD.log
    char date[16];
    FormatTime(date, sizeof(date), "%Y-%m-%d");
    BuildPath(Path_SM, g_sLogFile, sizeof(g_sLogFile), "logs/%s-%s.log", tag, date);

    // ConVar для управления уровнем прямо из консоли сервера
    char cvarName[64];
    Format(cvarName, sizeof(cvarName), "sm_%s_log_level", tag);

    g_cvLogLevel = CreateConVar(
        cvarName,
        "3",
        "Уровень логирования: 0=выкл, 1=error, 2=warn, 3=info, 4=debug",
        FCVAR_NONE,
        true, 0.0,
        true, 4.0);

    // Применяем уровень по умолчанию, если ConVar только что создан
    if (g_cvLogLevel != null)
        g_cvLogLevel.IntValue = view_as<int>(defaultLevel);
}

/**
 * Возвращает текущий уровень логирования.
 */
stock LogLevel Logger_GetLevel()
{
    if (g_cvLogLevel == null)
        return LOG_INFO;
    return view_as<LogLevel>(g_cvLogLevel.IntValue);
}

/**
 * Устанавливает уровень логирования напрямую из кода.
 */
stock void Logger_SetLevel(LogLevel level)
{
    if (g_cvLogLevel != null)
        g_cvLogLevel.IntValue = view_as<int>(level);
}

/**
 * Включить/выключить дублирование INFO/WARN/ERROR сообщений в чат всем игрокам.
 * По умолчанию выключено.
 */
stock void Logger_SetChatOutput(bool enabled)
{
    g_bPrintToChat = enabled;
}

// ─── Ядро логирования ─────────────────────────────────────────────────────────

/**
 * Внутренняя функция — записывает уже готовое сообщение в лог.
 */
static stock void Logger_WriteRaw(LogLevel level, const char[] msg)
{
    // Метка уровня
    char levelStr[8];
    switch (level)
    {
        case LOG_ERROR: strcopy(levelStr, sizeof(levelStr), "ERROR");
        case LOG_WARN: strcopy(levelStr, sizeof(levelStr), "WARN ");
        case LOG_INFO: strcopy(levelStr, sizeof(levelStr), "INFO ");
        case LOG_DEBUG: strcopy(levelStr, sizeof(levelStr), "DEBUG");
        default: strcopy(levelStr, sizeof(levelStr), "?????");
    }

    char fullMsg[640];
    Format(fullMsg, sizeof(fullMsg), "[%s] [%s] %s", g_sLogTag, levelStr, msg);

    // Пишем в файл
    if (g_sLogFile[0] != '\0')
        LogToFileEx(g_sLogFile, "%s", fullMsg);

    // Ошибки и дебаг всегда дублируем в консоль сервера
    if (level == LOG_ERROR || level == LOG_DEBUG)
        PrintToServer("%s", fullMsg);

    // Дублируем в чат всем игрокам (если включено)
    if (g_bPrintToChat && level >= LOG_INFO)
        PrintToChatAll(" [%s] %s", g_sLogTag, msg);
}

// ─── Публичные функции логирования ───────────────────────────────────────────

/**
 * Логирует отладочное сообщение (видно только при LOG_DEBUG).
 */
stock void Log_Debug(const char[] fmt, any...)
{
    if (Logger_GetLevel() < LOG_DEBUG)
        return;
    char msg[512];
    VFormat(msg, sizeof(msg), fmt, 2);
    Logger_WriteRaw(LOG_DEBUG, msg);
}

/**
 * Логирует информационное сообщение.
 */
stock void Log_Info(const char[] fmt, any...)
{
    if (Logger_GetLevel() < LOG_INFO)
        return;
    char msg[512];
    VFormat(msg, sizeof(msg), fmt, 2);
    Logger_WriteRaw(LOG_INFO, msg);
}

/**
 * Логирует предупреждение.
 */
stock void Log_Warn(const char[] fmt, any...)
{
    if (Logger_GetLevel() < LOG_WARN)
        return;
    char msg[512];
    VFormat(msg, sizeof(msg), fmt, 2);
    Logger_WriteRaw(LOG_WARN, msg);
}

/**
 * Логирует ошибку.
 */
stock void Log_Err(const char[] fmt, any...)
{
    if (Logger_GetLevel() < LOG_ERROR)
        return;
    char msg[512];
    VFormat(msg, sizeof(msg), fmt, 2);
    Logger_WriteRaw(LOG_ERROR, msg);
}
