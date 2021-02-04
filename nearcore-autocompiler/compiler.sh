#!/bin/bash
set -eu
# Script settings
RELEASE=$(lsb_release -c -s)
# Change this to compile a different
NEAR_VERSION=1.17.0-rc.5
# Change this to use a different repo
NEAR_REPO="https://github.com/near-guildnet/nearcore.git"
NODE_EXPORTER_REPO="https://github.com/prometheus/node_exporter.git"
NEAR_EXPORTER_REPO="https://github.com/masknetgoal634/near-prometheus-exporter.git"
vm_name="compiler"

echo "* Starting the NEARCORE compile process"

function update_via_apt
{
    echo "* Updating via APT and installing required packages"
    apt-get -qq update && apt-get -qq upgrade
    TEST=$(snap -h | tail -n 1)
    SNAP=$(echo "$TEST" | cut -c1-5)
    if [ "$SNAP" = "For a" ]
    then
        echo "snap is already installed"
    else
        apt-get -qq install snapd squashfs-tools git curl python3
        sleep 5
    fi
    echo '* Install lxd using snap'
    LXD=$(snap list lxd | tail -n 1)
    if [ "$LXD" = "error: no matching snaps installed" ]
    then
        snap install lxd
        usermod -aG lxd "$USER"
        init_lxd
    fi
}

function init_lxd
{
    echo "* Initializing LXD"
    cat <<EOF | lxd init --preseed
config: {}
networks:
- config:
    ipv4.address: auto
    ipv6.address: none
  description: ""
  name: lxdbr0
  type: ""
  project: default
storage_pools:
- config:
  description: ""
  name: default-compiler
  driver: dir
profiles:
- name: default-compiler
  description: "default compiling profile"
  devices:
    eth0:
      name: eth0
      network: lxdbr1
      type: nic
    root:
      path: /
      pool: default
      type: disk
  name: default-compiler
cluster: null
EOF
    systemctl restart snapd
    sleep 5
}

function launch_container
{
    echo "* Detected Ubuntu $RELEASE"
    echo "* Checking for conficting containers"
    CONF_CHK=$(lxc list | grep compiler)
    COMPILER_STATUS=$(lxc info compiler | grep stopped)
    if [ -n "$CONF_CHK" ] && [ -n "$COMPILER_STATUS" ]
    then
    lxc stop ${vm_name}
    lxc rename ${vm_name} ${vm_name}old
    else
    if [ -n "$CONF_CHK" ] && [ -z "$COMPILER_STATUS" ]
    then
    lxc rename ${vm_name} ${vm_name}old
    fi
    
    if [ "$RELEASE" == "focal" ] && [ -z "$CONF_CHK" ]
    then
    echo "* Launching Ubuntu $RELEASE LXC container to build in"
    lxc launch images:ubuntu/focal/cloud/amd64 ${vm_name}
    fi
    if [ "$RELEASE" == "bionic" ] && [ -z "$CONF_CHK" ]
    then
    echo "* Launching Ubuntu $RELEASE LXC container to build in"
    lxc launch images:ubuntu/18.04/cloud/amd64 ${vm_name}
    fi
    echo "* Pausing for 15 seconds while the container initializes"
    sleep 15
    echo "* Install Required Packages"
    fi
    lxc exec ${vm_name} -- /usr/bin/apt-get -qq update
    lxc exec ${vm_name} -- /usr/bin/apt-get -qq upgrade
    lxc exec ${vm_name} -- /usr/bin/apt-get -qq autoremove
    lxc exec ${vm_name} -- /usr/bin/apt-get -qq autoclean
    lxc exec ${vm_name} -- /usr/bin/apt-get -qq install git curl libclang-dev build-essential iperf llvm runc gcc g++ g++-multilib make cmake clang pkg-config libssl-dev libudev-dev libx32stdc++6-7-dbg lib32stdc++6-7-dbg python3-dev
    lxc exec ${vm_name} -- /usr/bin/snap install rustup --classic
    lxc exec ${vm_name} -- /usr/bin/snap install go --classic
    lxc exec ${vm_name} -- /snap/bin/rustup default nightly
    lxc exec ${vm_name} -- /snap/bin/rustup update
}


function compile_source
{
    echo "* Cloning the github source"
    lxc exec ${vm_name} -- sh -c "rm -rf /tmp/src && mkdir -p /tmp/src/ && git clone ${NEAR_REPO} /tmp/src/nearcore"
    lxc exec ${vm_name} -- sh -c "git clone ${NEAR_EXPORTER_REPO} /tmp/src/near-prometheus-exporter"
    lxc exec ${vm_name} -- sh -c "git clone ${NODE_EXPORTER_REPO} /tmp/src/node-exporter"
    echo "* Switching Version"
    lxc exec ${vm_name} -- sh -c "cd /tmp/src/nearcore && git checkout $NEAR_VERSION"
    echo "* Attempting to compile"
    lxc exec ${vm_name} -- sh -c "cd /tmp/src/nearcore && cargo build -p neard --release"
    lxc exec ${vm_name} -- sh -c "cd /tmp/src/near-prometheus-exporter && go build -a -installsuffix cgo -ldflags="-w -s" -o main ."
    lxc exec ${vm_name} -- sh -c "/tmp/src/node-exporter/make"
}

function get_compiled_binary
{
    echo "* Retriving the binary files and storing in /usr/local/bin"
    lxc file pull ${vm_name}/tmp/src/nearcore/target/release/neard /usr/local/bin/neard
    lxc file pull ${vm_name}/tmp/src/near-prometheus-exporter/main /usr/local/bin/near-exporter
    lxc file pull ${vm_name}/tmp/src/node-exporter/node_exporter /usr/local/bin/near-exporter
}


if [ "$USER" != "root" ]
then
    echo " You must run the compile script using sudo"
    exit
fi
update_via_apt
launch_container
compile_source
get_compiled_binary

echo "** You have now compiled the nearcore binary neard. It is located in /tmp/"
echo "** Please refer to the readme file in the installer folder for further instructions**"
