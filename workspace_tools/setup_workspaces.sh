#!/bin/bash
set -e

function setup_ws {
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
    wstool merge -y /tmp/setup_workspace/setup_`basename $new_ws`_${ROS_DISTRO}.rosinstall
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
        return
    else
        echo "need to install packages"
    fi
    # enalbe script cancelation on firts error
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
if [ $# -ne 1 ]; then
    echo "ERROR: wrong number of arguments, expecting:"
    echo "setup_workspace.sh [local|robot]"
    exit 1
fi

if [ "$1" != "local" ] && [ "$1" != "robot" ]; then
    echo "ERROR: please provide argument [local|robot]. Got: $1"
    exit 2
else
    mode=$1
    echo "using mode: $mode"
fi

# we'll start with cloning msh manually as it contains the rosinstall files for all workspaces
if [ ! -d /tmp/setup_workspace ]; then
    git clone git@github.com:unity-robotics/msh.git /tmp/setup_workspace
fi

if [ "$mode" == "robot" ]; then
    echo "Installation on robot!"
    rosdep update
    su robot -c "rosdep update"
    su robot -c "sudo apt-get update"
    su robot -c "sudo apt-get upgrade"
    export -f setup_ws
    export -f install_dependencies
    su robot -c "setup_ws ~/git/care-o-bot /opt/ros/${ROS_DISTRO}/setup.bash"
    setup_ws ~/git/cob_ws /u/robot/git/care-o-bot/devel/setup.bash
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
    setup_ws ~/git/cob_ws ~/git/robot_ws/devel/setup.bash
else
	echo "ERROR: invalid mode: $mode"
	exit 3
fi

setup_ws ~/git/nav_ws ~/git/cob_ws/devel/setup.bash
setup_ws ~/git/msh_ws ~/git/nav_ws/devel/setup.bash
setup_ws ~/git/care-o-bot ~/git/msh_ws/devel/setup.bash

