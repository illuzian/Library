#!/usr/bin/env bash
# Adds a user to a machine and sets it to be able to sudo without password
# NOTE: Use of variables not verified - run tests before use. Added after initial use.
USER='admin_user'
USER_COMMENT='User description'
AUTHORIZED_KEY='ssh-rsa pubkey user@host'

find_distro() {
    if [ -f /etc/lsb-release ]; then
        DISTRO='DebianBased'
    elif [ -f /etc/redhat-release ]; then
        DISTRO='RedHat'
    elif [ -f /etc/oracle-release ]; then
        DISTRO='Oracle'
    else
        DISTRO='Unknown'
    fi
}


find_sudo_group() {
    if [[ $( grep wheel /etc/group ) ]] &> /dev/null; then
        SUDO_GROUP='wheel'
    elif [[ $( grep sudo /etc/group ) ]] &> /dev/null; then
        SUDO_GROUP='sudo'
    elif [[ $( grep admin /etc/group ) ]] &> /dev/null; then
        SUDO_GROUP='admin'
    else
        SUDO_GROUP='Unknown'
    fi
}


if [[ $( grep $USER /etc/passwd ) ]] &> /dev/null; then
    echo "User $USER exists? Stopping"
    exit 2
fi

if [[ -d /home/$USER ]]; then
    echo "$USER user dir exists? Stopping"
    exit 3
fi





find_distro
find_sudo_group

if [[ ! $SUDO_GROUP = 'Unknown' ]] && [[ ! $DISTRO = 'Unknown' ]]; then
    useradd -c $USER_COMMENT -d /home/$USER -s /bin/bash -G wheel $USER
    mkdir -p /home/$USER/.ssh
    echo $AUTHORIZED_KEY >> /home/$USER/.ssh/authorized_keys
    chmod 700 /home/$USER/.ssh
    chmod 600 /home/$USER/.ssh/*
    chown -R $USER:$USER /home/$USER
    echo "Adding user ended."
else
    echo "Couldn't find suitable combination."
    echo "Distro: $DISTRO"
    echo "Sudo group: $SUDO_GROUP"
    exit 5
fi
echo "Trying to add NOPASSWD"
if [[ -d /etc/sudoers.d ]]; then
    echo "Found /etc/sudoers.d - adding"
    echo "$USER ALL=(ALL) NOPASSWD:ALL" | tee /etc/sudoers.d/$USER
else
    echo "/etc/sudoers.d not found, checking for other includedir locations"
    INCDIR="$(sudo cat /etc/sudoers | grep includedir | cut -d' ' -f2 | head -n1)"
    if [[ $INCDIR ]]; then
        echo "Found $INCDIR"
        echo "$USER ALL=(ALL) NOPASSWD:ALL" | tee $INCDIR/$USER
    else
        echo "No sudo include dir found. Adding directly to /etc/sudoers"
        echo "Backing up sudoers to /home/$USER/sudoers.bk"
        cp /etc/sudoers /home/$USER/sudoers.bk
        echo "Adding to sudoers"
        echo "$USER ALL=(ALL) NOPASSWD:ALL" | tee -a /etc/sudoers
    fi
fi

exit 0