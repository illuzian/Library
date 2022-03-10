#!/usr/bin/env bash
# Uninstalls and reinstalls a Qualys agent
ACTIVATION_ID=''
CUSTOMER_ID=''
SERVER_URI='https://qualys-agent/CloudAgent'

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


find_distro

if [[ $DISTRO = 'Oracle' ]] || [[ $DISTRO = 'RedHat' ]]; then
    sudo yum remove -y qualys-cloud-agent
    sudo yum install -y ~/QualysCloudAgent.rpm
elif [[ $DISTRO = 'DebianBased' ]]; then
    sudo apt remove qualys-cloud-agent
    sudo apt install ~/QualysCloudAgent.deb
else
    echo "Couldn't find a suitable distro. Don't know what to do"
    exit 3
fi

sudo /usr/local/qualys/cloud-agent/bin/qualys-cloud-agent.sh ActivationId=$ACTIVATION_ID CustomerId=$CUSTOMER_ID ServerUri=$SERVER_URI

