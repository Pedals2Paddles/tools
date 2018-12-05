#!/bin/bash

set -e

now=$(date +"%F_%H%M")

FW_SOURCE_WAF_ORIGINAL="/mnt/c/github/ardupilot/build/CubeBlack/bin/arducopter.apj"
FW_SOURCE_MASTER_ORIGINAL="http://firmware.us.ardupilot.org/Copter/latest/CubeBlack/arducopter.apj"
FW_SOURCE_STABLE_ORIGINAL="http://firmware.us.ardupilot.org/Copter/stable/CubeBlack/arducopter.apj"
FW_SOURCE_DESKTOP_ORIGINAL="/mnt/c/Users/Matthew/Desktop/arducopter.apj"

FW_SOURCE_CUSTOM_FILENAME="ac_test_$now.apj"
FW_SOURCE_MASTER_FILENAME="ac_master_$now.apj"
FW_SOURCE_STABLE_FILENAME="ac_stable_$now.apj"

FW_DEST_CUSTOM="/mnt/c/github/tools/fw_binaries/custom/"$FW_SOURCE_CUSTOM_FILENAME
FW_DEST_MASTER="/mnt/c/github/tools/fw_binaries/master/"$FW_SOURCE_MASTER_FILENAME
FW_DEST_STABLE="/mnt/c/github/tools/fw_binaries/stable/"$FW_SOURCE_STABLE_FILENAME

PARAM_MASTER_MATT="/mnt/c/github/tools/params/Solo_AC37_Matt.param"
PARAM_MASTER_SOLO="/mnt/c/github/tools/params/Solo_AC37_Solo.param"
PARAM_STABLE_SOLO="/mnt/c/github/tools/params/Solo_AC36.param"

AP_PATH="/mnt/c/github/ardupilot/"
APJ_TOOL_PATH="/mnt/c/github/tools/apj_tool/apj_tool.py"


getMaster() {
    set -e
    wget -O $FW_DEST_MASTER $FW_SOURCE_MASTER_ORIGINAL
}

getStable() {
    set -e
    wget -O $FW_DEST_STABLE $FW_SOURCE_STABLE_ORIGINAL
}

getWAF() {
    set -e
    cp $FW_SOURCE_WAF_ORIGINAL $FW_DEST_CUSTOM
}

getDesktop() {
    set -e
    cp $FW_SOURCE_DESKTOP_ORIGINAL $FW_DEST_CUSTOM
}

buildWAF() {
    set -e

    echo
    echo
    echo "---------------------------------------------"
    echo "| STARTING WAF BUILD. THIS MAY TAKE A WHILE |"
    echo "---------------------------------------------"
    echo

    cd /mnt/c/github/ardupilot/
    ./waf configure --board CubeBlack
    ./waf copter -j1 --no-submodule-update
}

setParms() {
    set -e
    python $APJ_TOOL_PATH --set-file $param_file_selected $fw_selected
}


selectBuild() {

    PS6='Select Build: '
    options=("Master" "Stable" "WAF" "WAF_New" "Desktop" "Quit")
    select opt in "${options[@]}"
    do
        case $opt in
            "Master")
                echo "you chose choice $REPLY which is $opt"
                fw_selected=$FW_DEST_MASTER
                break
                ;;
            "Stable")
                echo "you chose choice $REPLY which is $opt"
                fw_selected=$FW_DEST_STABLE
                break
                ;;
            "WAF")
                echo "you chose choice $REPLY which is $opt"
                fw_selected=$FW_DEST_CUSTOM
                break
                ;;
            "WAF_New")
                echo "you chose choice $REPLY which is $opt"
                fw_selected=$FW_DEST_CUSTOM
                break
                ;;
            "Desktop")
                echo "you chose choice $REPLY which is $opt"
                fw_selected=$FW_DEST_CUSTOM
                break
                ;;
            "Quit")
                return 1
                break
                ;;
            *) echo "invalid option $REPLY";;
        esac
    done

        build_selection=$REPLY
}

selectParam() {

    PS3='Select Parameter File: '
    options=("Master Matt" "Master Solo" "Stable Solo" "Quit")
    select opt in "${options[@]}"
    do
        case $opt in
            "Master Matt")
                echo "you chose choice $REPLY which is $opt"
                param_file_selected=$PARAM_MASTER_MATT
                break
                ;;
            "Master Solo")
                echo "you chose choice $REPLY which is $opt"
                param_file_selected=$PARAM_MASTER_SOLO
                break
                ;;
            "Stable Solo")
                echo "you chose choice $REPLY which is $opt"
                param_file_selected=$PARAM_STABLE_SOLO
                break
                ;;
            "Quit")
                return 1
                break
                ;;
            *) echo "invalid option $REPLY";;
        esac
    done

}

execute() {
    set -e

    echo
    echo "-----------------------------------------------"
    echo "| SELECT FIRMWARE BINARY TO DOWNLOAD OR BUILD |"
    echo "-----------------------------------------------"
    echo
    
    ## Select the build
    if ! selectBuild; then
        echo "Build select bombed out"
        exit 1
    fi

    echo
    echo
    echo "--------------------------------------------"
    echo "|      SELECT PARAMETER DEFAULT FILE       |"
    echo "--------------------------------------------"
    echo
    
    ## Select a parameter file for defaults
    if ! selectParam; then
        echo "Param select shit itself"
        exit 1
    fi

    echo
    echo
    echo "--------------------------------------------"
    echo "|     FETCHING OR BUILDING BINARIES        |"
    echo "--------------------------------------------"
    echo
    echo "build_selection="$REPLY
    ## Fetch or build FW binaries based on selections
    if [ $build_selection == "1" ]; then
        if ! getMaster; then
            echo "Fetching master flopped"
            exit 1
        fi
    elif [ $build_selection == "2" ]; then
        if ! getStable; then
            echo "Fetching stable fuuuuucked"
            exit 1
        fi
    elif [ $build_selection == "3" ]; then
        if ! getWAF; then
            echo "Fetching from WAF waffled"
            exit 1
        fi
    elif [ $build_selection == "4" ]; then
        echo "Building off current git tree"
        
        if ! buildWAF; then
            echo "You fucked up. WAF failed"
            exit 1
        elif ! getWAF; then
            echo "Fetching from WAF waffled"
            exit 1
        fi
    elif [ $build_selection == "5" ]; then
        if ! getDesktop; then
            echo "Fetching from Desktop didn't"
            exit 1
        fi
    else
        echo "Can't do shit if you don't make a selection asshole"
        exit 1
    fi

    echo
    echo "--------------------------------------------"
    echo "| Setting default parameters with APJ_TOOL |"
    echo "--------------------------------------------"
    echo
    echo

    ## Set default params with APJ_TOOL
    if ! setParms; then
        echo "APJ Tool says you suck. Param setting failed"
        exit 1
    fi

    ## Give the file a .px4 extension so it will load in Solo
    mv $fw_selected $fw_selected.px4

    echo
    echo "--------------------------------------------"
    echo "|                 DONE                     |"
    echo "--------------------------------------------"
    echo
    echo

    ## Unbelievably, everything seems to have completed
    echo "Firmware binary ready at " $fw_selected
    exit 0
}

execute