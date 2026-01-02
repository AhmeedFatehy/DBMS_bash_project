#!/bin/bash

options=(
    "Create Table"
    "List tables"
    "Drop table"
    "Insert row"
    "Show data"
    "Delete row"
    "Update cell"
    "Exit"
)

dataTypes=(
    "INT"
    "STRING"
    "DONE"
)

createTable(){
    echo "Action: Creating a table..."

    read -p "Enter table name: " tableName
    validateName "$tableName"
    if [ $returnVal -ne 0 ]; then
        echo "Invalid table name: must start with a (letter or _) and contain only (letters or digits or _)."
        return 1
    fi

    #->>>Ensure table does not exixt here
    if [ -f $CURRENT_DB/$tableName ]; then
        echo "Table exists already..."
        read -p "Press any key to continue..."
        return 1
    fi

    readMetaData "$tableName"
    touch "$CURRENT_DB/$tableName"
    echo "Table $tableName created...."
    read -p "press any key to continue."
}

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

readMetaData(){
    if [ "$#" -ne 1 ]; then
        echo "Invalid number of parameters in readColums(), must be 1...."
        read -p "Press any key to continue"
        return 0
    fi

    hasPrimary="U" #unknown
    while ! [[ "$hasPrimary" =~ ^[yYnN]$ ]]; do
        read -p "If table has primary key, you must enter its data first. Do you have primary key in your table?(y/n) " hasPrimary
    done
    metaData=""
    numOfColumns=0
    if [[ $hasPrimary =~ [n|N] ]]; then
        echo "Added defaultPK column as PRIMARY KEY in table $1"
        metaData+="INT:defaultPK;"
        (( numOfColumns+=1 ))
    fi
    PS3="Choose column type from list above (1-2 for types, or 3 when finished): "
    select type in "${dataTypes[@]}"; do
        case $type in
            "INT"|"STRING")
                read -p "Enter name of column $(( numOfColumns+1 )): " columnName
                validateName $columnName
                ##->ensure table column does not exixt here
                if [[ "$metaData" == *":$columnName;"* ]]; then
                    echo "$columnName already exists in the table!"
                    read -p "Press any key to continue.."
                    continue
                fi
                metaData+="$type:${columnName};"
                (( numOfColumns+=1 ))
                ;;
            "DONE")
                break
                ;;
            *)
                echo "Invalid option $REPLY. Please choose a number from the list."
                ;;
        esac
    done
    metaData="$1:$numOfColumns;$metaData"
    echo "$metaData" >> "$DB_ROOT/$dbname/$dbname.md"

}

# Start the select loop
PS3="Select a number(1-8) from the list above: "
select opt in "${options[@]}"
do
    case $opt in
        "Create Table")
             createTable
            ;;
        "List tables")
            echo "Action: Listing tables, existing tables found below..."
            ls "$CURRENT_DB" | grep -v "$dbname.md"
            ;;
        "Drop table")
            echo "Action: Dropping table..."
            read -p "Enter table name: " tableName
            validateName "$tableName"
            if [ $returnVal -ne 0 ]; then
                echo "Invalid table name: must start with a (letter or _) and contain only (letters or digits or _)."
                continue
            fi

            #->>>Ensure table exixt here
            if [[ ! -f $CURRENT_DB/$tableName ]]; then
                echo "Table does not exist..."
                read -p "Press any key to continue..."
                continue
            fi
            rm $CURRENT_DB/$tableName
            sed -i "/^$tableName:/d" "$CURRENT_DB/$dbname.md"
            ;;
        "Insert row")
            echo "Action: Inserting row..."
            ls "$CURRENT_DB" | grep -v "$dbname.md"
            read -p "Choose a table name to insert data into it: " tableName
            if [[ ! -f $CURRENT_DB/$tableName ]]; then
                echo "Table does not exist..."
                read -p "Press any key to continue..."
                continue
            fi
            
            ;;
        "Show data")
            echo "Action: Displaying data..."
            ls "$CURRENT_DB" | grep -v "$dbname.md"
            read -p "Choose a table name to show its data: " tableName
            if [[ ! -f $CURRENT_DB/$tableName ]]; then
                echo "Table does not exist..."
                read -p "Press any key to continue..."
                continue
            fi
            cat $CURRENT_DB/$tableName
            echo
            ;;
        "Delete row")
            echo "Action: Deleting row..."
            ;;
        "Update cell")
            echo "Action: Updating cell..."
            ;;
        "Exit")
            break
            ;;
        *)
            echo "Invalid option $REPLY. Please choose 1-8."
            ;;
    esac
    PS3="Select a number(1-8) from the list above: "
done