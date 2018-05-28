#!/bin/bash
set -e

function setup_ws {
    set -e
    new_ws=$1
    chained_ws=$2
    echo ""
    echo "creating new workspace in $new_ws chaining $chained_ws"

    mkdir -p $new_ws/src

    ###############################################
    ### install dependencies from previous runs ###
    ###############################################
    # this is needed for multiple executions
    cd $new_ws
    install_dependencies
    
    ################################
    ### setup workspace chaining ###
    ################################
    cd $new_ws
    source $chained_ws
    catkin init
    catkin config -DCMAKE_BUILD_TYPE=Release
    catkin build

    ######################
    ### fill workspace ###
    ######################
    cd $new_ws/src
    if [ ! -f .rosinstall ]; then
        wstool init
    fi
    if [ -z ${3+x} ]; then
        rosinstall=$setup_dir/setup_`basename $new_ws`_${ROS_DISTRO}.rosinstall
    else
        echo "overwrite app_ws rosinstall with $3"
        rosinstall=$3
    fi

    echo "create workspace with $rosinstall"
    wstool merge -y $rosinstall
    if [ $? -ne 0 ]; then
        echo "could not setup $new_ws workspace"
        exit -1
    fi
    wstool update -j9
    
    ############################
    ### install dependencies ###
    ############################
    cd $new_ws
    install_dependencies
    
    #######################
    ### build workspace ###
    #######################
    cd $new_ws
    catkin build
    
    source $new_ws/devel/setup.bash
}

function install_dependencies {
    # check if rosdep is satisfied
    # do not cancel script during this step on error
    # if deps are missing we would like to install them
    # instead of canceling the script
    set +e
    if (rosdep check --from-path src -i -y); then
        echo "rosdep satisfied"
        set -e
        return
    else
        echo "need to install packages"
    fi
    # enable script cancelation on firts error
    set -e

    if [ "$mode" == "robot" ]; then
        echo "executing 'rosdep install', please enter robot password"
        su robot -c "
        source $chained_ws
        rosdep install --from-path src -i -y"
    elif [ "$mode" == "local" ]; then
        sudo whoami
        if [ $? -eq 0 ]; then # only execute if user has sudo rights
            echo "executing 'rosdep install'"
            source $chained_ws
            rosdep install --from-path src -i -y
        else
            echo "WARN: skipping rosdep install because user does not have sudo rights"
        fi
    else
        echo "ERROR: wrong mode: $mode"
        exit 1
    fi
}

############
### main ###
############
if [ $# -ne 2 ]; then
    echo "ERROR: wrong number of arguments, expecting:"
    echo "setup_workspace.sh [local|robot] [msh|hdg|...]"
    exit 1
fi

if [ "$1" != "local" ] && [ "$1" != "robot" ]; then
    echo "ERROR: please provide argument [local|robot]. Got: $1"
    exit 2
else
    mode=$1
    echo "using mode: $mode"
fi

# we'll store the current execution path to find the rosinstall files for all workspaces
setup_dir=$PWD

rosinstall_app_ws="$setup_dir/setup_app_ws_$2_${ROS_DISTRO}.rosinstall"

if [[ -f $rosinstall_app_ws ]]; then
    echo "setting up app_ws for $2"
else
    echo "ERROR: rosinstall file for app_ws $2 not found"
    exit 3
fi

if [ "$mode" == "robot" ]; then
    echo "Installation on robot!"
    rosdep update
    su robot -c "rosdep update"
    su robot -c "sudo apt-get update"
    su robot -c "sudo apt-get upgrade"
    export setup_dir
    export -f setup_ws
    export -f install_dependencies
    su robot -c "setup_ws ~/git/care-o-bot /opt/ros/${ROS_DISTRO}/setup.bash"
    setup_ws ~/git/nav_ws /u/robot/git/care-o-bot/devel/setup.bash
elif [ "$mode" == "local" ]; then
    echo "Installation on local computer"
    rosdep update
    sudo whoami
    if [ $? -eq 0 ]; then # only execute if user has sudo rights
        sudo apt-get update
        sudo apt-get upgrade
        sudo apt-get install build-essential python-catkin-tools python-wstool -y
    else
        echo "WARN: skipping apt-get upgrade because user does not have sudo rights"
    fi
    setup_ws ~/git/robot_ws /opt/ros/${ROS_DISTRO}/setup.bash
    setup_ws ~/git/nav_ws ~/git/robot_ws/devel/setup.bash
else
	echo "ERROR: invalid mode: $mode"
	exit 3
fi

setup_ws ~/git/mojin_ws ~/git/nav_ws/devel/setup.bash
setup_ws ~/git/app_ws ~/git/mojin_ws/devel/setup.bash $rosinstall_app_ws
setup_ws ~/git/care-o-bot ~/git/app_ws/devel/setup.bash

