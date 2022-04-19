#!/bin/bash

CLUSTER_VIP=$1
CLUSTER_PORT=$2
re='^[0-9]+$'

# Prepping settings
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system


# Written for Ubuntu but may expand for other OS
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl docker.io
sudo apt-mark hold kubelet kubeadm kubectl

# Set cgroup driver to systemd



# Ask if this is the first kuberenetes controlplane node so initial install can occur.
# Joining additional nodes is done differently.
while true; do
    read -p "Do you wish to install this as the first kubernetes controlplane node? " yn
    case $yn in
        [Yy]* ) make install; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
if [ -z ${CLUSTER_VIP+x} ];
then
  echo "You must provide the cluster VIP or FQDN for the VIP"
elif [[ $CLUSTER_PORT =~ $re ]];
then
  sudo kubeadm init --control-plane-endpoint "${CLUSTER_VIP}:${CLUSTER_PORT}" --upload-certs
else
  sudo kubeadm init --control-plane-endpoint $CLUSTER_VIP --upload-certs
fi


