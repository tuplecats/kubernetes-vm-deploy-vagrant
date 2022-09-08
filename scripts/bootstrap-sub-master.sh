#!/bin/sh

. "/tmp/scripts/bootstrap.sh"
. "/tmp/scripts/install-etcd.sh"

DIR="/tmp/downloaded"
mkdir -p $DIR

apt install -qq -y sshpass >/dev/null 2>&1
sshpass -p "kubeadmin" scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no master1.kube.lan:$DIR $DIR 2>/dev/null
sshpass -p "kubeadmin" scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no master1.kube.lan:/etc/kubernetes/pki $DIR/pki 2>/dev/null

install_etcd

rm $DIR/pki/apiserver.*
sudo mv $DIR/pki /etc/kubernetes/
bash ./join-master-cluster.sh >/dev/null 2>&1