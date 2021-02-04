#!/bin/bash
set -eu
# Script settings
RELEASE=$(lsb_release -c -s)
# Change this to compile a different
NEAR_VERSION="1.17.0-rc.5"
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
        snap restart lxd
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

function get_container
{
    echo "* Detected Ubuntu $RELEASE"
    echo "* Checking for existing containers"
    CONF_CHK=$(lxc list | grep ${vm_name})
    if [ ! -z "$CONF_CHK" ]
    then
    echo "* Found an existing container with the same name attempting to use that"
    prepare_contaioner
    fi

    if [ "$RELEASE" == "focal" ]
    then
    echo "* Launching Ubuntu Cloud Image  $RELEASE LXC container to build in"
    lxc launch images:ubuntu/focal/cloud/amd64 ${vm_name}
    prepare_contaioner
    fi

    if [ "$RELEASE" == "bionic" ]
    then
    echo "* Launching Ubuntu $RELEASE LXC container to build in"
    lxc launch images:ubuntu/18.04/cloud/amd64 ${vm_name}
    prepare_contaioner
    fi
}

function prepare_contaioner
{
    echo "* Pausing for 15 seconds while the container initializes"
    sleep 15

    echo "* Configuring the container with all required development tools"
    lxc exec ${vm_name} -- sh -c "apt-get -qq update"
    lxc exec ${vm_name} -- sh -c "apt-get -qq upgrade"
    lxc exec ${vm_name} -- sh -c "apt-get -qq autoremove"
    lxc exec ${vm_name} -- sh -c "apt-get -qq autoclean"
    lxc exec ${vm_name} -- sh -c "apt-get -qq install git snapd curl libclang-dev build-essential llvm runc gcc g++ g++-multilib make cmake clang pkg-config libssl-dev libudev-dev libx32stdc++6-7-dbg lib32stdc++6-7-dbg python3-dev"
    lxc exec ${vm_name} -- sh -c "snap install rustup --classic"
    lxc exec ${vm_name} -- sh -c "snap install go --classic"
    lxc exec ${vm_name} -- sh -c "rustup default nightly"
    lxc exec ${vm_name} -- sh -c "rustup update"
    echo "* The container is ready for use"
    compile
}


function compile
{
    echo "* Cloning the github source"
    lxc exec ${vm_name} -- sh -c "rm -rf /tmp/src && mkdir -p /tmp/src/ && git clone ${NEAR_REPO} /tmp/src/nearcore"
    lxc exec ${vm_name} -- sh -c "git clone ${NEAR_EXPORTER_REPO} /tmp/src/near-prometheus-exporter"
    lxc exec ${vm_name} -- sh -c "git clone ${NODE_EXPORTER_REPO} /tmp/src/node-exporter"
    echo "* Switching Version"
    lxc exec ${vm_name} -- sh -c "cd /tmp/src/nearcore && git checkout $NEAR_VERSION"
    echo "* Attempting to compile nearcore"
    lxc exec ${vm_name} -- sh -c "cd /tmp/src/nearcore && cargo build -p neard --release"
    echo "* Attempting to compile Near Prometheus Exporter"
    lxc exec ${vm_name} -- sh -c "cd /tmp/src/near-prometheus-exporter && go build -a -installsuffix cgo -ldflags="-w -s" -o main ."
    echo "* Attempting to compile Prometheus Node Exporter"
    lxc exec ${vm_name} -- sh -c "cd /tmp/src/node-exporter/ && make all"
    lxc exec ${vm_name} -- sh -c "mkdir -p /tmp/src/node-exporter/node_exporter_binaries && cp -r /tmp/src/node-exporter/docs /tmp/src/node-exporter/node_exporter_binaries"
    lxc exec ${vm_name} -- sh -c "cp -r /tmp/src/node-exporter/examples /tmp/src/node-exporter/node_exporter_binaries && cp -r /tmp/src/node-exporter/node_exporter /tmp/src/node-exporter/node_exporter_binaries"
    lxc exec ${vm_name} -- sh -c "cp /tmp/src/node-exporter/*.yml /tmp/src/node-exporter/node_exporter_binaries && cp /tmp/src/node-exporter/*.md /tmp/src/node-exporter/node_exporter_binaries"
    lxc exec ${vm_name} -- sh -c "cp -r /tmp/src/node-exporter/text_collector_examples/ /tmp/src/node-exporter/node_exporter_binaries && cp -r /tmp/src/node-exporter/tls_config_noAuth.bad.yml /tmp/src/node-exporter/node_exporter_binaries"
    lxc exec ${vm_name} -- sh -c "tar -cjf /tmp/src/node-exporter/node_exporter.tar.gz -C /tmp/src/node-exporter/ node_exporter_binaries"
}

function get_binary
{
    echo "* Retriving the binary files"
    mkdir -p /tmp/binaries/
    lxc file pull -P $vm_name/tmp/src/nearcore/target/release/neard /tmp/binaries/
    lxc file pull -P $vm_name/tmp/src/near-prometheus-exporter/main /tmp/binaries/
    lxc file pull -p $vm_name/tmp/src/node-exporter/node_exporter.tar.gz /tmp/ 
    lxc file pull -p $vm_name/tmp/src/node-exporter/node_exporter /tmp/binaries/ 
}


if [ "$USER" != "root" ]
then
    echo " You must run the compile script using:  sudo ./compiler.sh "
    exit
fi
update_via_apt
get_container
compile
get_binary

echo "** The binary files are located in /tmp/binaries"
echo "** Please refer to the readme file for further instructions**"
