#!/bin/bash

# Color Variables 
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
CYAN="\e[36m"
MAGENTA="\e[35m"
RESET="\e[0m"

options=(
    "Create Table"
    "List tables"
    "Drop table"
    "Insert row"
    "Show data"
    "Delete row"
    "Update cell"
    "Export CSV"
    "Exit"
)

dataTypes=(
    "INT"
    "STRING"
    "DONE"
)

validateName(){
    if [ $# -ne 1 ]; then
        returnVal=1;
    elif [[ "$1" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        returnVal=0
    else 
        returnVal=2
    fi
}

validateNumber(){
    if [ $# -ne 1 ]; then
        returnVal=1;
    elif [[ "$1" =~ ^[0-9]+$ ]]; then
        returnVal=0
    else 
        returnVal=2
    fi
}

validateType(){
    if [ "$#" -ne 2 ]; then
        echo -e "${RED}Invalid number of parameters in validateType(), must be 2....${RESET}"
        return 1
    fi
    if [[ "$2" == "INT" ]]; then
        if [[ $1 =~ ^[-+]?[0-9]+$ ]]; then
            return 0
        else
            echo -e "${RED}Error: Column value must be Integer.${RESET}"
            return 1;
        fi
    elif [[ "$2" == "STRING" ]]; then
        pattern='^[a-zA-Z_ .@]+$'
        if [[ $1 =~ $pattern ]]; then
            return 0
        else
            echo -e "${RED}Error: '$1' contains invalid string characters.${RESET}"
            return 1;
        fi
    fi
}

readMetaData(){
    if [ "$#" -ne 1 ]; then
        echo -e "${RED}Invalid number of parameters in readColums(), must be 1....${RESET}"
        return 1
    fi

    hasPrimary="U" 
    while ! [[ "$hasPrimary" =~ ^[yYnN]$ ]]; do
        read -p "If table has primary key, you must enter its data first. Do you have primary key in your table?(y/n) " hasPrimary
    done
    metaData=""
    numOfColumns=0
    if [[ "$hasPrimary" =~ ^[nN]$ ]]; then
        echo -e "${YELLOW}Added defaultPK column as PRIMARY KEY in table $1${RESET}"
        metaData+="INT:defaultPK;"
        (( numOfColumns+=1 ))
    else
        echo -e "${CYAN}You must enter your primary key first....${RESET}"
    fi

    PS3="Choose column type from list above (1-2 for types, or 3 when finished): "
    select type in "${dataTypes[@]}"; do
        case $type in
            "INT"|"STRING")
                read -p "Enter name of column $(( numOfColumns+1 )): " columnName
                validateName $columnName
                if [ $returnVal -ne 0 ]; then
                    echo -e "${RED}Invalid column name: must start with a (letter or _) and contain only (letters or digits or _).${RESET}"
                    read -p "Press any key to continue"
                    continue
                fi
                if [[ "$metaData" == *":$columnName;"* ]]; then
                    echo -e "${RED}$columnName already exists in the table!${RESET}"
                    read -p "Press any key to continue.."
                    continue
                fi
                metaData+="$type:${columnName};"
                (( numOfColumns+=1 ))
                ;;
            "DONE")
                if [[ numOfColumns -lt 1 ]]; then
                    echo -e "${RED}Number of columns must be greater than 0.${RESET}"
                    return 1
                fi 
                break
                ;;
            *)
                echo -e "${RED}Invalid option $REPLY. Please choose a number from the list.${RESET}"
                ;;
        esac
    done
    metaData="$1:$numOfColumns;$metaData"
    echo "$metaData" >> "$CURRENT_DB/$dbname.md"
    touch "$CURRENT_DB/$tableName"
    return 0
}

createTable(){
    echo -e "${CYAN}Action: Creating a table...${RESET}"
    read -p "Enter table name: " tableName
    validateName "$tableName"
    if [ $returnVal -ne 0 ]; then
        echo -e "${RED}Invalid table name: must start with a (letter or _) and contain only (letters or digits or _).${RESET}"
        read
        return 1
    fi

    if [ -f $CURRENT_DB/$tableName ]; then
        echo -e "${RED}Table exists already...${RESET}"
        read -p "Press any key to continue..."
        return 1
    fi

    readMetaData "$tableName"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Table $tableName created successfully!${RESET}"
    else
        echo -e "${RED}❌ Failed to create Table $tableName....${RESET}"
    fi
    read -p "Press Enter to continue."
}

# Initial UI Setup
clear
echo -e "${CYAN}========================================${RESET}"
echo -e "${MAGENTA}************ Table Menu  ************${RESET}"
echo -e "${CYAN}========================================${RESET}"

PS3="Select a number (1-9): "
select opt in "${options[@]}"
do
    case $opt in
        "Create Table")
            createTable
            ;;
        "List tables")
            echo -e "${CYAN}📂 Existing tables found below:${RESET}"
            ls "$CURRENT_DB" | grep -v "$dbname.md" || echo -e "${YELLOW}No tables found.${RESET}"
            read -p "Press Enter to continue..."
            ;;
        "Drop table")
            echo -e "${CYAN}Action: Dropping table...${RESET}"
            read -p "Enter table name: " tableName
            validateName "$tableName"
            if [ $returnVal -ne 0 ]; then
                echo -e "${RED}Invalid table name.${RESET}"
                read -p "Press Enter to continue..."
                continue
            fi

            if [[ ! -f $CURRENT_DB/$tableName ]]; then
                echo -e "${RED}Table does not exist...${RESET}"
                read -p "Press Enter to continue..."
                continue
            fi
            rm $CURRENT_DB/$tableName
            sed -i "/^$tableName:/d" "$CURRENT_DB/$dbname.md"
            echo -e "${GREEN}✅ Table dropped successfully!${RESET}"
            read -p "Press Enter to continue..."
            ;;
        "Insert row")
            echo -e "${CYAN}Action: Inserting row...${RESET}"
            ls "$CURRENT_DB" | grep -v "$dbname.md"
            read -p "Choose a table name to insert data: " tableName
            
            validateName "$tableName"
            if [ $returnVal -ne 0 ]; then
                echo -e "${RED}Invalid table name.${RESET}"
                read -p "Press Enter to continue..."
                continue
            fi
            
            if [[ ! -f $CURRENT_DB/$tableName ]]; then
                echo -e "${RED}Table does not exist...${RESET}"
                read -p "Press Enter to continue..."
                continue
            fi

            tableMetaData=$(awk -F'[:;]' -v row=$tableName '($1==row) {print; exit;}' $CURRENT_DB/$dbname.md)
            numOfColumns=$(echo "$tableMetaData" | awk -F'[;]' '{print (NF-2)}')
            tableMetaData=$(echo "$tableMetaData" | awk -F'[;]' '{for(i=2; i<=NF; i++) print $i}')

            dataRow=""
            for ((i=1; i<=numOfColumns; i++)); do
                currentColName=$(echo "$tableMetaData"| awk -F: '{print $2}' | sed -n "${i}p")
                currentColType=$(echo "$tableMetaData"| awk -F: '{print $1}' | sed -n "${i}p")
                columnAdded=0
                while (($columnAdded==0)); do
                    read -p "Enter column $i ($currentColName, type: $currentColType) value: " colValue
                    validateType "$colValue" "$currentColType"
                    if [ $? -ne 0 ]; then
                        read -p "Press Enter to continue..."
                        continue
                    fi
                    if [[ $i == 1 ]]; then
                        PKValues=$(awk -F';' '{print $1;}' "$CURRENT_DB/$tableName")
                        PKExist=$(grep -Fx -- "$colValue" <<< "$PKValues")
                        if [ "$PKExist" ]; then
                            echo -e "${RED}The Primary key already exists in the table${RESET}"
                            continue
                        else
                            echo -e "${GREEN}The Primary key is unique.${RESET}"
                        fi
                    fi
                    if [[ $? == 0 ]]; then  
                        columnAdded=1
                        dataRow+="$colValue;"
                    fi
                done
            done
            echo "$dataRow" >> "$CURRENT_DB/$tableName"
            echo -e "${GREEN}✅ Row successfully added!${RESET}"
            read -p "Press Enter to continue.."
            ;;
        "Show data")
            echo -e "${CYAN}Action: Displaying data...${RESET}"
            ls "$CURRENT_DB" | grep -v "$dbname.md"
            read -p "Choose a table name: " tableName
            validateName "$tableName"
            if [ $returnVal -ne 0 ]; then
                echo -e "${RED}Invalid name.${RESET}"
            elif [[ ! -f $CURRENT_DB/$tableName ]]; then
                echo -e "${RED}Table does not exist...${RESET}"
            else
                tableMetaData=$(awk -F'[:;]' -v row=$tableName '($1==row) {print; exit;}' "$CURRENT_DB/$dbname.md")
                allColNames=$(echo "$tableMetaData" | awk -F'[;]' '{for(i=2; i<NF; i++) {split($i, a, ":"); printf "%s ", a[2]}}')
                
                echo -e "${MAGENTA}--- Table: $tableName ---${RESET}"
                echo -e "${YELLOW}Available Columns: $allColNames${RESET}"
                echo -e "1) Show All Columns"
                echo -e "2) Select Specific Columns"
                read -p "Choose an option [1-2]: " displayChoice
                if [[ ! "$displayChoice" =~ ^[1-2]$ ]]; then
                    read -p "Invalid option...press any key to continue"
                    continue
                fi
                if [[ "$displayChoice" == "2" ]]; then
                    read -p "Enter column names to show (separated by space): " selectedCols
                    if [[ ! $selectedCols =~ ^[a-zA-Z_][a-zA-Z0-9_]*([[:blank:]]+[a-zA-Z_][a-zA-Z0-9_]*)*$ ]]; then
                        read -p "Invalid format. Use names separated by spaces...press Enter to continue"
                        continue
                    fi
                    
                    headerRow=""
                    awkString=""
                    err_col="0"
                    for col in $selectedCols; do
                        # Find the index of the column name in the metadata
                        index=$(echo "$tableMetaData" | awk -F'[;]' -v c="$col" '{
                            for(i=2; i<NF; i++) {
                                split($i, a, ":");
                                if(a[2] == c) {print i-1; exit}
                            }
                        }')

                        if [[ -n "$index" ]]; then
                            headerRow+="$col;"
                            awkString+="$"$index","
                        else
                            echo -e "${RED}Error: Column '$col' not found.${RESET}"
                            err_col="1"
                        fi
                    done

                    if [[ "$err_col" == "1" ]]; then
                        read -p "Press enter"
                        continue
                    fi

                    if [[ -n "$awkString" ]]; then
                        # Remove trailing comma from awkString
                        awkString=${awkString%,}
                        echo -e "${YELLOW}$headerRow${RESET}" | sed 's/;/ | /g' | column -t -s '|'
                        awk -F';' "{print $awkString}" "$CURRENT_DB/$tableName" | sed 's/ / | /g' | column -t -s '|'
                    fi
                else
                    # Default: Show All 
                    headers=$(awk -F'[:;]' -v tbl="$tableName" '$1 == tbl {for(i=4; i<=NF; i+=2) printf "%s%s", $i, (i+2<=NF ? ";" : "") }' "$CURRENT_DB/$dbname.md")
                    ( echo -e "${YELLOW}$headers${RESET}"; cat "$CURRENT_DB/$tableName" ) | sed 's/;/ | /g' | column -t -s '|'
                fi

            fi
            read -p "Press Enter to continue..."s
            ;;
        "Delete row")
            echo -e "${CYAN}Action: Deleting row...${RESET}"
            ls "$CURRENT_DB" | grep -v "$dbname.md"
            read -p "Choose a table name: " tableName
            validateName "$tableName"
            if [[ $returnVal -eq 0 && -f $CURRENT_DB/$tableName ]]; then
                tableMetaData=$(awk -F'[:;]' -v row=$tableName '($1==row) {print; exit;}' $CURRENT_DB/$dbname.md)
                tableMetaData=$(echo "$tableMetaData" | awk -F'[;]' '{for(i=2; i<=NF; i++) print $i}')
                currentColName=$(echo "$tableMetaData"| awk -F: '{print $2}' | sed -n "1p")
                currentColType=$(echo "$tableMetaData"| awk -F: '{print $1}' | sed -n "1p")
                read -p "Enter primary key ($currentColName): " colValue
                validateType "$colValue" "$currentColType"
                if [ $? -eq 0 ]; then
                    PKValues=$(awk -F';' '{print $1;}' "$CURRENT_DB/$tableName")
                    if grep -Fxq -- "$colValue" <<< "$PKValues"; then
                        awk -F';' -v pk="$colValue" '$1 != pk' "$CURRENT_DB/$tableName" > "$CURRENT_DB/$tableName.tmp" && mv "$CURRENT_DB/$tableName.tmp" "$CURRENT_DB/$tableName"
                        echo -e "${GREEN}✅ Row $colValue deleted!${RESET}"
                    else
                        echo -e "${RED}Primary key does not exist.${RESET}"
                    fi
                fi
            else
                echo -e "${RED}Invalid or missing table.${RESET}"
            fi
            read -p "Press Enter to continue..."
            ;;
        "Update cell")
            echo -e "${CYAN}Action: Updating cell...${RESET}"
            ls "$CURRENT_DB" | grep -v "$dbname.md"
            read -p "Choose a table: " tableName
            validateName "$tableName"
            if [[ $returnVal -eq 0 && -f $CURRENT_DB/$tableName ]]; then
                tableMetaData=$(awk -F'[:;]' -v row=$tableName '($1==row) {print; exit;}' $CURRENT_DB/$dbname.md)
                tableMetaData=$(echo "$tableMetaData" | awk -F'[;]' '{for(i=2; i<=NF; i++) print $i}')
                currentColName=$(echo "$tableMetaData"| awk -F: '{print $2}' | sed -n "1p")
                currentColType=$(echo "$tableMetaData"| awk -F: '{print $1}' | sed -n "1p")
                read -p "Enter primary key ($currentColName): " colValue
                validateType "$colValue" "$currentColType"
                if [ $? -eq 0 ]; then
                    if grep -Fxq -- "$colValue" <(awk -F';' '{print $1}' "$CURRENT_DB/$tableName"); then
                        colNames=$(echo "$tableMetaData"| awk -F: '(NR>1) {print $2}')
                        echo -e "${YELLOW}Available columns: $colNames${RESET}"
                        read -p "Column to update: " updateCol
                        validateName "$updateCol"
                        if [ $returnVal -eq 0 ] && grep -Fxq -- "$updateCol" <<< "$colNames"; then
                            colType=$(echo "$tableMetaData"| awk -F: -v col=$updateCol '($2==col) {print $1}')
                            colIndex=$(echo "$tableMetaData"| awk -F: -v col=$updateCol '($2==col) {print NR}')
                            read -p "Enter new value: " newValue
                            awk -F';' -v OFS=';' -v idx=$colIndex -v pk=$colValue -v new=$newValue '($1==pk){$idx=new}{print}' "$CURRENT_DB/$tableName" > "$CURRENT_DB/$tableName.tmp" && mv "$CURRENT_DB/$tableName.tmp" "$CURRENT_DB/$tableName"
                            echo -e "${GREEN}✅ Cell updated.${RESET}"
                        else
                            echo -e "${RED}Invalid column.${RESET}"
                        fi
                    else
                        echo -e "${RED}Primary key not found.${RESET}"
                    fi
                fi
            else
                echo -e "${RED}Invalid table.${RESET}"
            fi
            read -p "Press Enter to continue..."
            ;;

        "Export CSV")
            echo -e "${CYAN}Action: Exporting .CSV file...${RESET}"
            ls "$CURRENT_DB" | grep -v "$dbname.md"
            read -p "Enter table name: " tableName
            validateName "$tableName"
            if (( returnVal != 0 )); then
                echo -e "${RED}Invalid table name.${RESET}"
                read -p "Press Enter to continue..."
                continue
            fi
            if [[ ! -f "$CURRENT_DB/$tableName" ]]; then
                echo -e "${RED}Table does not exist...${RESET}"
                read -p "Press Enter to continue..."
                continue
            fi

            headers=$(awk -F'[:;]' -v tbl="$tableName" '$1 == tbl {for(i=4; i<=NF; i+=2) printf "%s%s", $i, (i+2<=NF ? "," : "") }' "$CURRENT_DB/$dbname.md")
            echo $headers > ./$tableName.csv
            awk -F';' 'BEGIN { OFS="," }
            {
                if ($NF == "") NF--
                print
            }' "$CURRENT_DB/$tableName" >> "./$tableName.csv"

            echo -e "${GREEN}Exported $tableName.csv successfully.${RESET}"
            read -p "Press Enter to continue..."
            ;;

        "Exit")
            clear
            break
            ;;
        *)
            echo -e "${RED}Invalid option $REPLY. Choose 1-9.${RESET}"
            ;;
    esac
    
    # Refresh screen and show menu again
    clear
    echo -e "${CYAN}========================================${RESET}"
    echo -e "${MAGENTA}************ Table Menu  ************${RESET}"
    echo -e "${CYAN}========================================${RESET}"
done