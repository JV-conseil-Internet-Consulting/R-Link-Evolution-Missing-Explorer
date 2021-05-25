#!/usr/bin/env bash
# -*- coding: UTF-8 -*-

__VIRTUALBOX_PATH="$HOME/VirtualBox/Ubuntu"


__virtualbox_help () {
    cat << EOF

VirtualBox v6.1 Extra Ressources
--------------------------------

VirtualBox is a powerful x86 and AMD64/Intel64
virtualization product for enterprise as well as home use:
https://www.virtualbox.org

Download Ubuntu Desktop
Ubuntu 20.04.2.0 LTS
LTS stands for long-term support — which means 
five years, until April 2025, of free security 
and maintenance updates, guaranteed:
https://ubuntu.com/download/desktop

options:
c       Check your installation.
s       Create a Virtual Machine VMDK for your SD card.
l       Launch RLinkToolbox.
h       Help.

Your VirtualBox VM path:
${__VIRTUALBOX_PATH}

EOF
}


__virtualbox_brew () {

    __brew_pkg=("virtualbox" "virtualbox-extension-pack")

    echo
    echo "Checking your Homebrew packages list"
    echo "------------------------------------"
    for pkg in "${__brew_pkg[@]}"
    do
        brew list --cask --versions "$pkg" || brew install "$pkg"
    done
    echo

}


__virtualbox_kill_apps () {

    echo
    echo "VirtualBox should not run during this procedure."
    echo
    pkill -x VirtualBox RLinkToolbox

}


__virtualbox_sdcard () {

    cd "${__VIRTUALBOX_PATH}" || exit

    __virtualbox_kill_apps

    echo
    echo "Create a Virtual Machine VMDK for your SD card"
    echo "----------------------------------------------"

    sudo diskutil list

    echo
    read -p "Enter the correct disk number /dev/disk[0-9] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[0-9]$ ]]
    then
        __disk="/dev/disk${REPLY}"
        __sdcard="SDcard.vmdk"
        __unmount () {
            sudo diskutil unmountDisk "${__disk}"
        }

        echo "You have selected ${__disk}"
        sudo chown "$USER" "${__disk}"
        sudo chmod 777 "${__disk}"

        if [[ -f "${__sdcard}" ]]
        then
            echo "Removing previous VDMK."
            rm "${__sdcard}"
        
        else
            echo "No previous ${__sdcard} found to delete."

        fi

        __unmount

        sudo VBoxManage internalcommands createrawvmdk -filename "${__sdcard}" -rawdisk "${__disk}"
        sudo chown "$USER" "${__sdcard}"
        sudo chmod 777 "${__sdcard}"

        __unmount

        # __uuid=$(sed -En 's/.*?ddb.uuid.image="([a-z0-9\-]+)".*?/\1/' "${__sdcard}")
        __uuid=$(grep -Eo 'ddb.uuid.image="[a-z0-9\-]+"' "${__sdcard}" | sed -E 's/ddb.uuid.image="([a-z0-9\-]+)"/\1/')
        if [[ "${__uuid}" ]]
        then
            open -a TextEdit "Ubuntu.vbox"
            echo
            echo "In TextEdit look for this line:"
            echo '<HardDisk uuid="{e19b7ecb-3193-4f9b-98ad-d6a0d56ad436}" location="SDcard.vmdk" format="VMDK" type="Normal"/>'
            echo
            echo "And this second line:"
            echo '<AttachedDevice type="HardDisk" hotpluggable="true" port="1" device="0"><Image uuid="{e19b7ecb-3193-4f9b-98ad-d6a0d56ad436}"/></AttachedDevice>'
            echo
            echo "Replace the uuid value by: $__uuid"
            echo 
            echo "Save & Quit"
            echo
            __unmount
        fi

    else
        echo "You did not provide a valid number disk. Cancel."
        exit 1
    fi

}


vbox () {

    if [[ -z "$1" ]]
    then
        echo
        read -p "Do you want to create a VMDK for your SD card? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
            __virtualbox_sdcard
        else
            __virtualbox_help
        fi

    else
        while getopts ":hcsl" option
        do
        case $option in
            h) # display Help
                __virtualbox_help
                ;;

            c)
                __virtualbox_brew
                ;;

            s)
                __virtualbox_sdcard
                ;;
            
            l)
                open "https://myr.renault.fr/r-link-store.html"
                open -a RLinkToolbox
                ;;

            \?) # incorrect option
                echo "Error: Invalid option"
                exit 1;;
        esac
        done

    fi

}