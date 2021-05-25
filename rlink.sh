#!/bin/bash
# shellcheck disable=SC2044,SC2181
#
# title         : rlink.sh
# description   : A shell script to mount TOMTOM.xxx files from a TomTom 
#                 SD card to browse/modify its content.
# author        : JV conseil – Internet Consulting
# credits       : JV-conseil
# licence       : BSD 3-Clause License.
# copyright     : Copyright (c) 2021, JV conseil – Internet Consulting,
#                 All rights reserved.
# usage         : bash ./rlink.sh
# requirements  : VirtualBox, VM VirtualBox Extension Pack and one Linux 
#                 distribution like Ubuntu.
# date          : 20210525
# version       : 1.0
# bash_version  : 5.1.8(1)-release
#
#===============================================================================


__TOMTOM_PATH="./"


__rlink_help () {
    cat << EOF

R-Link Evolution Missing Explorer
---------------------------------

Place this file in the same folder where your TOMTOM.000 ... files are, ideally 
on the SD card:

/Volumes/SDCARD
├── TOMTOM.000
├── TOMTOM.001
├── TOMTOM.002
├── TOMTOM.003
└── rlink.sh

options:
h   Help.

A TomTom R-Link SD card is made of multiple TOMTOM.xxx (000, 001, ...) files.

These files contain a splitted Lunux filesystem. The scripts will:
- Attach each file to a virtual block device, called a loopback device : /dev/loopX
- Aggregate all these devices as a big "linear" one: /dev/md/tomtom_vfs, seen a a real disk
- Mount this new device to the /mnt/tomtom_vfs directory.

Once done, you can modify the content, to add, for example, POIs.

EOF
}


# Output to stderr
__rlink_echoerr () {
    echo "$@" 1>&2;
}


# Find first available /dev/loopX
__rlink_loopback_dev () {

    typeset -i num
    num=0
    while [[ ${num} -le 255 ]]
    do
        losetup /dev/loop${num} >/dev/null 2>&1 
        [[ $? -ne 0 ]] && break
        num=$((num + 2))
    done

    echo "/dev/loop${num}"

}


# Count the number of TOMTOM.xxx files
__rlink_count_tomtom_vfs_files () {

    typeset -i count_vfs_files
    count_vfs_files=0

    while [[ -e ${__TOMTOM_PATH}TOMTOM.$(printf "%03d" ${count_vfs_files}) ]]
    do
        count_vfs_files+=1
    done

    echo ${count_vfs_files}

}


# Associate all TOMTOM.xxx files to a loopback device
__rlink_init_loopback_devs () {

    typeset -gi COUNT_VFS_FILES
    LOOPBACK_DEV_LIST=""

    COUNT_VFS_FILES=$(__rlink_count_tomtom_vfs_files ${__TOMTOM_PATH})
    echo "${COUNT_VFS_FILES} tomtom files found."

    echo "Creating loopback devices."

    for ((i=0;i<COUNT_VFS_FILES;i++))
    do
        VFS_FILE=${__TOMTOM_PATH}TOMTOM.$(printf "%03d" "$i")
        LOOPBACK_DEV=$(__rlink_loopback_dev)
        LOOPBACK_DEV_LIST="${LOOPBACK_DEV_LIST} ${LOOPBACK_DEV}"

        # associate file to loopback device
        sudo losetup "${LOOPBACK_DEV}" "${VFS_FILE}"
        if [[ $? -ne 0 ]]
        then
            __rlink_echoerr "Error while creating loopback device ${LOOPBACK_DEV} from ${VFS_FILE}. Cancel."
            __rlink_remove_loopback_devs
            exit 1
        fi
        
        echo "${VFS_FILE} is now associated to ${LOOPBACK_DEV}."
    done

}


# Delete all loopback devices
__rlink_remove_loopback_devs () {

    echo "Removing all loopback devices."
    sudo losetup -d "${LOOPBACK_DEV_LIST}"
    if [[ $? -ne 0 ]]
    then
        __rlink_echoerr "Error while removing one or multiple loopback devices. Please check with losetp and dmesg."
        exit 1
    fi
    return 0

}


# Build the linear raid device from all loopback devices (TOMTOM.xxx files)
__rlink_build_linear_raid () {

    echo "Build linear raid device."
    COMMAND="mdadm --build --auto=part --verbose /dev/md/tomtom_vfs --rounding=32 --level=linear -n${COUNT_VFS_FILES} ${LOOPBACK_DEV_LIST}"
    # shellcheck disable=SC2086
    sudo $COMMAND
    # if [[ $1 -ne 0 ]]
    if [[ $? -ne 0 ]]
    then
        __rlink_echoerr "Error during raid device creation. Trying to cancel. Check /proc/mdstat, mdadm and dmesg."
        __rlink_remove_loopback_devs
        exit 1
    fi
    return 0

}


# Delete the /dev/md/tomtom_vfs raid device
__rlink_delete_linear_raid () {

    echo "Stopping linear raid device."
    sudo mdadm -S /dev/md/tomtom_vfs
    # if [[ $1 -ne 0 ]]
    if [[ $? -ne 0 ]]
    then
        __rlink_echoerr "Error during raid device deletion. Please check /proc/mdstat, mdadm and dmesg. Loopback devices won't be removed."
        exit 1
    fi
    return 0

}


# wait for a carriage return
__press_enter_to_continue () {

    # echo "Please press return to finish :"
    # read -r dummy
    # shellcheck disable=SC2162
    read -p "Please press enter to continue"
    echo "Thank you"
    return 0

}


# Mount the TOMTOM.xxx linear raid ex3 filesystem in /mnt/tomtom_vfs
__rlink_mount_vfs () {

    # Ensure it's not already mounted
    mount | grep "on /mnt/tomtom_vfs " >/dev/null 2>&1
    if [[ $? -eq 0 ]]
    then
        echo "Mountpoint already in use. Cancel."
    else
        echo "Creating mount point and mount tomtom filesystem"
        sudo mkdir -p /mnt/tomtom_vfs 2>/dev/null
        sudo mount /dev/md/tomtom_vfs /mnt/tomtom_vfs
        if [[ $? -eq 0 ]]
        then 
            vfs_user=$(stat -c "%u" /mnt/tomtom_vfs/common)
            vfs_group=$(stat -c "%g" /mnt/tomtom_vfs/common)
            current_group=$(id -gn)

            # bind to 
            mkdir -p "$HOME/tomtom_vfs"
            sudo bindfs -u "$USER" -g "${current_group}" --create-for-user="${vfs_user}" --create-for-group="${vfs_group}" /mnt/tomtom_vfs/ "$HOME/tomtom_vfs"
            echo "Filesystem is now available in /mnt/tomtom_vfs as root and $HOME/tomtom_vfs as $USER"
            sleep 1
        else
            __rlink_echoerr "Something is wrong. Corrupted files ? Trying to cancel."
            __rlink_umount_vfs
            __rlink_delete_linear_raid
            __rlink_remove_loopback_devs
            exit 1
        fi     
    fi
    return 0
}


# unmount /mnt/tomtom_vfs (TOMTOM.xxx linear raid ext3 filesystem)
__rlink_umount_vfs () {
    # Ensure it's mounted
    mount | grep "on /mnt/tomtom_vfs " >/dev/null 2>&1
    if [[ $? -ne 0 ]]
    then
        echo "Nothing to do, /mnt/tomtom_vfs Not mounted"
        return 0
    fi

    # synchronise files
    sync

    # check if there's something to kill
    fuserkill=0
    lsof "$HOME/tomtom_vfs" >/dev/null 2>&1
    [[ $? -ne 1 ]] && fuserkill=1
    lsof /mnt/tomtom_vfs >/dev/null 2>&1
    [[ $? -ne 1 ]] && fuserkill=1

    if [[ ${fuserkill} -eq 1 ]]
    then
        # Killing local users
        echo "Killing remaining processus using the mountpoints"
        sudo fuser -k "$HOME/tomtom_vfs"

        # First kill everything that is related to the mountpoint
        sudo fuser -k /mnt/tomtom_vfs

        echo "Waiting 5 seconds"
        sleep 5
    fi

    # Then, umount
    echo "Unmounting tomtom filesystem and remove mount point"
    sudo fusermount -u "$HOME/tomtom_vfs"
    sudo umount /mnt/tomtom_vfs
    if [[ $? -ne 0 ]]
    then
        __rlink_echoerr "Cannot unmount /mnt/tomtom_vfs. Please check dmesg, fuser and dmesg. raid and loopback devices left untouched."
        exit 1
    fi
    sudo rmdir /mnt/tomtom_vfs
    sudo rmdir "$HOME/tomtom_vfs"
    return 0
}


# If on X, open default file manager
__rlink_open_default_file_manager () {

    if xhost >& /dev/null
    then 
        echo "Launching default file manager"
        xdg-open "$HOME/tomtom_vfs"
    fi
    return 0

}


# Check if prerequires are installed
__rlink_check_prerequires () {

    ERR=0
    PREREQUIRES="mdadm losetup bindfs"
    for prerequire in $PREREQUIRES
    do
        which "$prerequire" >/dev/null 2>&1
        if [[ $? -ne 0 ]]
        then
            __rlink_echoerr "$prerequire command is missing."
            echo "Please install it (the method depends of your Linux distribution)."
            echo "For Ubuntu: apt-get install $prerequire"
            ERR=1
        fi
    done
    return $ERR

}


__rlink_search_cards () {

    typeset -i COUNT_CARDS
    COUNT_CARDS=0
    for card in $(find "$HOME/tomtom_vfs" -name "*.pna")
    do
        echo "Found $card card."
        COUNT_CARDS+=1
    done
    echo "Found ${COUNT_CARDS} card(s)."
    return 0

}


rlink () {

    __rlink_check_prerequires
    [[ $? -ne 0 ]] && exit 1

    echo "Starting."

    __rlink_init_loopback_devs
    __rlink_build_linear_raid
    __rlink_mount_vfs
    __rlink_search_cards
    __rlink_open_default_file_manager
    __press_enter_to_continue
    __rlink_umount_vfs
    __rlink_delete_linear_raid
    __rlink_remove_loopback_devs

    echo "End."
    return 0

}


# Tree
if [[ -z "$1" ]]
then
    __rlink_help
    echo
    read -p "Do you want to assemble your TOMTOM files? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        rlink "$@"
    fi
else
    while getopts ":h" option
            do
            case $option in
                h) # display Help
                    __rlink_help
                    ;;

                \?) # incorrect option
                    __rlink_echoerr "Error: Invalid option"
                    __rlink_help
                    ;;
            esac
            done
fi
