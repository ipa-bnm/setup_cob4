#!/bin/bash
set -e

# upgrade local pc
sudo apt-get update
sudo apt-get -qq upgrade -y
sudo apt-get autoremove -y

# get installed packages
packages=$(dpkg --get-selections | grep -v "deinstall" | awk '{print $1}')
echo $packages > /tmp/package_list

# get install pip packages
sudo -H pip freeze > /u/robot/pip_freeze_master


#### retrieve client_list variables
source /u/robot/git/setup_cob4/helper_client_list.sh

declare -a aptcommands=(
"sudo apt-get update"
"sudo apt-get -qq install -y --allow-unauthenticated $packages"
"sudo apt-get -qq upgrade -y"
"sudo apt-get autoremove -y"
)

declare -a pipcommands=(
"sudo -H pip freeze > /tmp/pip_freeze_slave"
"comm -23 <(sort /u/robot/pip_freeze_master) <(sort /tmp/pip_freeze_slave) > /tmp/pip_freeze_diff"
"sudo -H pip install -r /tmp/pip_freeze_diff"
)

for client in $client_list_hostnames; do
  echo "-------------------------------------------"
  echo "Installing packages on $client"
  echo "-------------------------------------------"
  echo ""
  for command in "${aptcommands[@]}"; do
    #echo "----> executing: $command"
    ssh $client $command
    ret=${PIPESTATUS[0]}
    if [ $ret != 0 ] ; then
      echo -t "$command return an error in $client (error code: $ret), aborting..."
      exit 1
    fi
  done
  echo ""
  for command in "${pipcommands[@]}"; do
    echo "----> executing: $command"
    ssh $client $command
    ret=${PIPESTATUS[0]}
    if [ $ret != 0 ] ; then
      echo -t "$command return an error in $client (error code: $ret), aborting..."
      exit 1
    fi
  done
  echo ""
done

echo "syncing packages done."
