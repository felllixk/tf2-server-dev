#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name        = "[TF2] Engi Mini-Sentry Only",
    author      = "YourNameHere",
    description = "Forces all engineers to only build mini-sentries.",
    version     = "1.0.0",
    url         = "https://yourwebsite.com/"
};

public void OnPluginStart()
{
    // Цепляемся за событие, когда игрок построил объект
    HookEvent("player_builtobject", Event_OnPlayerBuiltObject);
}

public void Event_OnPlayerBuiltObject(Event event, const char[] name, bool dontBroadcast)
{
    // Получаем ID игрока и саму постройку
    int client = GetClientOfUserId(event.GetInt("userid"));
    int entity = event.GetInt("index");

    // Проверяем на всякий случай, что игрок и постройка валидны
    if (!IsValidClient(client) || !IsValidEntity(entity))
        return;

    // Проверяем, что игрок действительно инженер
    if (TF2_GetPlayerClass(client) != TFClass_Engineer)
        return;

    // Получаем тип постройки
    int iObjectType = event.GetInt("object");

    // Если это турель (тип 2) и она не является мини-турелью (на всякий случай)
    if (iObjectType == 2)
    {
        // Устанавливаем сетевое свойство "m_bMiniBuilding" в true (1)
        // Это превращает обычную турель в мини-турель
        SetEntProp(entity, Prop_Send, "m_bMiniBuilding", 1);

        // Опционально: выводим сообщение инженеру
        PrintHintText(client, "Вы построили мини-турель!");
    }
}

// Вспомогательная функция для проверки игрока
stock bool IsValidClient(int client)
{
    if (client <= 0 || client > MaxClients) return false;
    if (!IsClientInGame(client)) return false;
    return true;
}