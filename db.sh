#!/bin/bash
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
CYAN="\e[36m"
MAGENTA="\e[35m"
RESET="\e[0m"

DB_ROOT="./databases"
mkdir -p "$DB_ROOT"

while true
do
    clear
    echo -e "${CYAN}========================================${RESET}"
    echo -e "${MAGENTA}************  Main Menu ************${RESET}"
    echo -e "${CYAN}========================================${RESET}"
    echo -e "${YELLOW}1)${RESET} Create Database"
    echo -e "${YELLOW}2)${RESET} List Databases"
    echo -e "${YELLOW}3)${RESET} Connect to Database"
    echo -e "${YELLOW}4)${RESET} Delete Database"
    echo -e "${YELLOW}5)${RESET} Exit"
    echo -e "${CYAN}========================================${RESET}"

    read -p "Choose option [1-5]: " choice

    if [[ ! $choice =~ ^[1-5]$ ]]; then
        echo -e "${RED}❌ Invalid choice! Please enter 1-5.${RESET}"
        read -p "Press Enter to continue..."
        continue
    fi

    case $choice in
    1)
        read -p "Enter database name: " dbname

        if [[ ! $dbname =~ ^[A-Za-z][A-Za-z0-9_]*$ ]]; then
            echo -e "${RED}❌ Name Must start with a letter and contain only letters, numbers, and underscores.${RESET}"
            read -p "Press Enter to continue..."
            continue
        fi

        if [ -d "$DB_ROOT/$dbname" ]; then
            echo -e "${RED}❌ Database already exists!${RESET}"
            read -p "Press Enter to continue..."
            continue
        fi

        mkdir "$DB_ROOT/$dbname"
        touch "$DB_ROOT/$dbname/$dbname.md"
        chmod 700 "$DB_ROOT/$dbname"
        echo -e "${GREEN}✅ Database '$dbname' created successfully!${RESET}"
        read -p "Press Enter to continue..."
        ;;

    2)
        echo -e "${CYAN}📂 Existing Databases:${RESET}"
        if [ "$(ls -A $DB_ROOT)" ]; then
            ls -1 "$DB_ROOT"
        else
            echo -e "${YELLOW}No databases found.${RESET}"
        fi
        read -p "Press Enter to continue..."
        ;;
    3)
        echo -e "${CYAN}📂 Existing Databases:${RESET}"
        if [ "$(ls -A $DB_ROOT)" ]; then
            ls -1 "$DB_ROOT"
        else
            echo -e "${YELLOW}No databases found.${RESET}"
        fi

        read -p "Enter database name to connect: " dbname

        if [[ ! $dbname =~ ^[A-Za-z][A-Za-z0-9_]*$ ]]; then
            echo -e "${RED}❌ Invalid database name!${RESET}"
            read -p "Press Enter to continue..."
            continue
        fi

        if [ ! -d "$DB_ROOT/$dbname" ]; then
            echo -e "${RED}❌ Database not found!${RESET}"
            read -p "Press Enter to continue..."
            continue
        fi

        export CURRENT_DB="$DB_ROOT/$dbname"
        echo -e "${GREEN}✅ Connected to '$dbname'${RESET}"
        read -p "Press Enter to open table menu..."
        source table.sh
        ;;

    4)
        read -p "Enter database name to delete: " dbname

        if [ ! -d "$DB_ROOT/$dbname" ]; then
            echo -e "${RED}❌ Database not found!${RESET}"
            read -p "Press Enter to continue..."
            continue
        fi

        read -p "Are you sure you want to delete '$dbname'? (y/n): " confirm
        if [[ $confirm =~ ^[yY]$ ]]; then
            rm -r "$DB_ROOT/$dbname"
            echo -e "${GREEN}✅ Database '$dbname' deleted successfully!${RESET}"
        else
            echo -e "${YELLOW}Operation canceled.${RESET}"
        fi
        read -p "Press Enter to continue..."
        ;;

    5)
        echo -e "${CYAN}👋 Goodbye!${RESET}"
        break
        ;;
    esac
done