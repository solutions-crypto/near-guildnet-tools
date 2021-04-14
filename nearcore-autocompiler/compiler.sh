#!/bin/bash
set -eu
# Script settings
RELEASE=$(lsb_release -c -s)
# Change this to compile a different
NEAR_VERSION="1.18.1-rc.2"
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
    apt-get -qq install snapd squashfs-tools git curl python3

    echo '* Install lxd using snap'
    snap install lxd
    usermod -aG lxd "$USER"
    systemctl restart snapd
    sleep 5
    snap restart lxd
    sleep 5
    init_lxd
}

function init_lxd
{
    echo "* Init LXD With Preseed ---> https://linuxcontainers.org/lxd/docs/master/preseed  "
    echo "* Cloud init + lxd examples  ---> https://github.com/lxc/lxd/issues/3347 "
    cat <<EOF | lxd init --auto
EOF
    systemctl restart snapd
    sleep 5
}

function get_container
{
    echo "* Detected Ubuntu $RELEASE"
    if [ "$RELEASE" == "focal" ]
    then
    echo "* Launching Ubuntu $RELEASE Cloud Image"
    lxc launch images:ubuntu/focal/cloud/amd64 ${vm_name}
    prepare_contaioner
    fi

    if [ "$RELEASE" == "bionic" ]
    then
    echo "* Launching Ubuntu $RELEASE Cloud Image"
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
    lxc exec ${vm_name} -- sh -c "cd /tmp/src/node-exporter/ && make "
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
    lxc file pull -p ${vm_name}/tmp/src/nearcore/target/release/neard /tmp/binaries/
    lxc file pull -p ${vm_name}/tmp/src/near-prometheus-exporter/near-exporter /tmp/binaries/
    lxc file pull -p ${vm_name}/tmp/src/node-exporter/node_exporter.tar.gz /tmp/binaries/
    lxc file pull -p ${vm_name}/tmp/src/node-exporter/node_exporter /tmp/binaries/
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
