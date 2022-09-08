#!/bin/bash

SYNC_FOLDER="/tmp/downloaded"
PKI_FOLDER="/tmp/pki"

sync_data() {
  dest="$1"
  folder="$2"

  sshpass -p "kubeadmin" rsync -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" -arvc "$folder/" "$dest:$folder"
}

send_data() {
  dest="$1"
  src_data="$2"
  dst_data="$3"
  
  sshpass -p "kubeadmin" scp -r -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $src_data $dest:$dst_data
}

run_script() {
  server="$1"
  script="$2"

  sshpass -p "kubeadmin" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $server "$script"
}

. "/tmp/scripts/bootstrap.sh"
. "/tmp/scripts/install-cfssl.sh"

install_cfssl

# INSTALL etcd
run_script master1.kube.lan 'IP=172.16.16.101 bash /tmp/scripts/install-etcd.sh'
run_script master3.kube.lan 'IP=172.16.16.103 bash /tmp/scripts/install-etcd.sh'
run_script master2.kube.lan 'IP=172.16.16.102 bash /tmp/scripts/install-etcd.sh'

echo "[INIT-TASK 1] Init cluster from config"
kubeadm init --config=/tmp/scripts/config.yaml

echo "[INIT-TASK 2] Start cluster"
. "/tmp/scripts/start-cluster.sh"

echo "[INIT-TASK 3] Deploy Calico network"
kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f https://docs.projectcalico.org/v3.18/manifests/calico.yaml >/dev/null 2>&1

echo "[INIT-TASK 4] Generate and save cluster join command to joincluster.sh"
kubeadm token create --print-join-command > $SYNC_FOLDER/join-worker-cluster.sh 2>/dev/null
{ kubeadm token create --print-join-command; echo "--apiserver-advertise-address=172.16.16.101 --control-plane"; } | tr "\n" " " > $SYNC_FOLDER/join-master-cluster.sh 2>/dev/null
echo >> $SYNC_FOLDER/join-master-cluster.sh 2>/dev/null
echo ". \"/tmp/scripts/start-cluster.sh\"" >> $SYNC_FOLDER/join-master-cluster.sh 2>/dev/null

echo "[INIT-TASK 5] Send data to other master servers"
sync_data master2.kube.lan $SYNC_FOLDER 
sync_data master3.kube.lan $SYNC_FOLDER 
sync_data worker1.kube.lan $SYNC_FOLDER 
sync_data worker2.kube.lan $SYNC_FOLDER 
sync_data worker3.kube.lan $SYNC_FOLDER 

echo "[INIT-TASK 6] Send certs to other master servers"
send_data master2.kube.lan /etc/kubernetes/pki "$PKI_FOLDER/"
send_data master3.kube.lan /etc/kubernetes/pki "$PKI_FOLDER/"

echo "[INIT-TASK 7] Join masters to cluster"
for i in $(seq 2 3); do
  run_script "master${i}.kube.lan" "rm -f $PKI_FOLDER/apiserver*"
  run_script "master${i}.kube.lan" "mv $PKI_FOLDER /etc/kubernetes/pki"
  run_script "master${i}.kube.lan" "bash $SYNC_FOLDER/join-master-cluster.sh"
done

echo "[INIT-TASK 8] Join workers to cluster"
for i in $(seq 1 3); do
  run_script "worker${i}.kube.lan" "bash $SYNC_FOLDER/join-worker-cluster.sh"
done