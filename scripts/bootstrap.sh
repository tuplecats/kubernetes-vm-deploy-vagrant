#!/bin/bash

sudo apt update && sudo apt upgrade

echo "[TASK 1] Disable and turnoff swap"
sed -i '/swap/d' /etc/fstab
swapoff -a

echo "[TASK 2] Enable and Load Kernel modules"
cat >>/etc/modules-load.d/containerd.conf<<EOF
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

echo "[TASK 3] Add Kernel settings"
cat >>/etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system >/dev/null 2>&1

echo "[TASK 4] Install containerd runtime"
apt update -qq >/dev/null 2>&1
apt install -qq -y containerd apt-transport-https >/dev/null 2>&1
mkdir /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd >/dev/null 2>&1


echo "[TASK 5] Add apt repo for kubernetes"
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - >/dev/null 2>&1
apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main" >/dev/null 2>&1


echo "[TASK 6] Install Kubernetes components (kubeadm, kubelet and kubectl)"
apt install -qq -y kubeadm kubelet kubectl >/dev/null 2>&1

echo "[TASK 7] Enable ssh password authentication"
sed -i 's/^PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
systemctl reload sshd

echo "[TASK 8] Set root password"
printf "kubeadmin\nkubeadmin" | passwd root >/dev/null 2>&1
echo "export TERM=xterm" >> /etc/bash.bashrc

echo "[TASK 9] Update /etc/hosts file"
cat >>/etc/hosts<<EOF
172.16.16.100   haproxy.kube.lan    kube-balancer
172.16.16.101   master1.kube.lan    kube-master1
172.16.16.102   master2.kube.lan    kube-master2
172.16.16.103   master3.kube.lan    kube-master3
172.16.16.201   worker1.kube.lan    kube-worker1
172.16.16.202   worker2.kube.lan    kube-worker2
172.16.16.203   worker3.kube.lan    kube-worker3
EOF

echo "[TASK 10] Install sshpass"
sudo apt install -qq -y sshpass