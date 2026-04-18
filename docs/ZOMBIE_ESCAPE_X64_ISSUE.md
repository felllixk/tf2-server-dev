# Проблема: Zombie Escape + SourceMod x64 на Linux

## Дата обнаружения
2026-04-18

## Суть проблемы
Плагин **Zombie Escape: Open Source** (и многие другие продвинутые TF2-плагины) требуют расширения **DHooks** (`dhooks.ext`).

В официальных стабильных сборках **SourceMod 1.12 / 1.13 для Linux x64 файл `extensions/x64/dhooks.ext.so` отсутствует**.

Это приводит к ошибкам при старте сервера:
```
Unable to load extension "dhooks.ext": .../extensions/x64/dhooks.ext.so: cannot open shared object file: No such file or directory
Unable to load plugin "zombie-escape.smx": Required extension "dhooks" file("dhooks.ext") not running
```

## Почему так происходит
- DHooks (Dynamic Hooks) позволяет хукать как виртуальные функции (vtable), так и обычные функции движка (detours).
- В SourceMod для Windows x64 DHooks добавили официально (`Add x64 Windows support to DHooks`).
- В стандартных **Linux** сборках AlliedModders `dhooks.ext.so` для архитектуры `x86-64` не включается в пакет (проверено на билдах 1.12.0-git7223, 1.12.0-git7228, 1.13.0-git7329).
- Существуют **кастомные/самособранные сборки** SourceMod с работающим x64 DHooks (например, репозиторий UNLOZE), но они не являются официальными.

## Что использует DHooks в Zombie Escape
- `CTFPlayer::CanPickupDroppedWeapon` — блокировать подбор оружия зомби
- `CTFPlayer::DropAmmoPack` — контроль выпадения аммопаков
- `CTFPlayer::RegenThink` — кастомная регенерация
- `CTFWeaponBaseMelee::DoSwingTraceInternal` — кастомный нокбек от ближнего оружия
- `CBasePlayer::ForceRespawn` — перехват респавна
- `CTeamplayRoundBasedRules::RoundRespawn` — старт раунда
- `CTFWeaponBase::ApplyOnInjuredAttributes` — обработка урона

Без DHooks плагин теряет критическую механику и фактически не работает как Zombie Escape.

## Возможные решения

### ✅ Рекомендуемое: 32-битный сервер
Переключить Docker-образ на `cm2network/tf2:sourcemod` (32-bit).  
В 32-битных сборках SourceMod `dhooks.ext.so` присутствует и работает стабильно.  
Подавляющее большинство публичных ZE-серверов до сих пор используют именно 32-битный режим.

### Кастомная x64-сборка SourceMod
Найти или самостоятельно собрать SourceMod из исходников с включённым DHooks для Linux x64.  
UNLOZE и ряд других сообществ используют именно такой подход, но это требует полноценного билд-окружения (clang, AMBuild, HL2SDK).

### VScript
**Нет.** VScript (Squirrel) в TF2 работает на уровне entity I/O и игровых событий. Он **не может** перехватывать произвольные C++ функции движка (detours/vtable hooks), поэтому не заменяет DHooks.

## Статус в проекте
- Переключено на 32-битный образ: `docker-compose.yml` использует `cm2network/tf2:sourcemod`
- Плагин `zombie-escape.smx` скомпилирован и работает в 32-битном режиме
- BLU = Zombies, RED = Survivors (форсировано в исходниках)
