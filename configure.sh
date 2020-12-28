#!/bin/bash

set -e

read -p "Enter desired app name or press return to have a name generated:" appname

if [ -z "$appname" ]; then
    appname="--generatename"
fi

read -p "Enter desired organization name or press return to use your personal org:" orgname

if [ -z "$orgname" ]; then
    orgname="personal"
fi

read -p "Enter disk size in GB or press return for default 10GB:" disksizenum

if [ -z "$disksizenum" ]; then
    disksize=""
else
    disksize="--size ${disksizenum}"
fi

read -p "Use Docker on remote machine (y/n):" usedockerresponse

case $usedockerresponse in 
[Yy])
    usedocker="--build-arg USE_DOCKER=y"
;;
*)
    usedocker=""
;;
esac

echo

read -p "Any extra packages:" extrapackages


AUTHORIZED_KEYS=""

for i in ~/.ssh/*.pub; do
    AUTHORIZED_KEYS="$AUTHORIZED_KEYS$(cat $i)\n"
done

echo "
[[services]]
internal_port = 22
protocol = \"tcp\"

[[services.ports]]
port = 10022

[[mounts]]
source = \"data\"
destination = \"/data\"

[env]
HOME_SSH_AUTHORIZED_KEYS = '''
$AUTHORIZED_KEYS
'''
">import.toml

fly init $appname --import import.toml --org $orgname --overwrite

rm import.toml

REGION=`fly regions list --json | awk '/"Code"/ { sub(/\ *"Code\": \"/ , "")
sub(/",/,"")
print }'`

fly volumes create data --region $REGION $disksize

fly deploy --build-arg USER=$(whoami) --build-arg EXTRA_PKGS="$extrapackages" $usedocker 

echo
echo
echo "To use in VS Code, tell the remote-ssh package to connect to $(whoami)@$(fly info --host):10022"

