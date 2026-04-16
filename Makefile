# Makefile

# Установка цели по умолчанию
.DEFAULT_GOAL := help

help: # Документация
	@grep -E '^[a-zA-Z0-9 -]+:.*#'  Makefile | sort | while read -r l; do printf "\033[1;32m$$(echo $$l | cut -f 1 -d':')\033[00m:$$(echo $$l | cut -f 2- -d'#')\n"; done

up: # Поднятие контейнеров
	docker compose up --remove-orphans

up-d: # Поднятие контейнеров в фоне
	docker compose up -d --remove-orphans

down: # Удаление контейнеров
	docker compose down

sh: # Вход в контейнер
	docker compose exec -it tf2 bash

run-sh: # Вход в контейнер
	docker compose run --rm tf2 bash

compile: # Компиляция плагина: make compile PLUGIN=path/to/plugin.sp
	@bash dev/compile_plugin.sh $(PLUGIN)

sync: # Компиляция плагина: make compile PLUGIN=path/to/plugin.sp
	@bash dev/sync.sh

pull-modules: # Обновление подмодулей
	git submodule update --init --recursive
