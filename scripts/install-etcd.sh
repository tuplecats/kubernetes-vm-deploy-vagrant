#!/bin/bash

service="/etc/systemd/system/etcd.service"
if [ -f "$service" ]; then
    sudo systemctl stop etcd
fi

sudo rm -rf /etc/etcd 2>/dev/null
sudo rm -rf /var/lib/etcd 2>/dev/null
sudo mkdir -p /etc/etcd /var/lib/etcd

cp /tmp/downloaded/ca.pem /etc/etcd/
cp /tmp/downloaded/kubernetes.pem /etc/etcd/
cp /tmp/downloaded/kubernetes-key.pem /etc/etcd/

wget https://github.com/etcd-io/etcd/releases/download/v3.3.13/etcd-v3.3.13-linux-amd64.tar.gz
tar xvzf etcd-v3.3.13-linux-amd64.tar.gz
sudo mv etcd-v3.3.13-linux-amd64/etcd* /usr/local/bin/

cat > /etc/systemd/system/etcd.service <<EOF
[Unit]
Description=etcd
Documentation=https://github.com/coreos


[Service]
ExecStart=/usr/local/bin/etcd \
--name $IP \
--cert-file=/etc/etcd/kubernetes.pem \
--key-file=/etc/etcd/kubernetes-key.pem \
--peer-cert-file=/etc/etcd/kubernetes.pem \
--peer-key-file=/etc/etcd/kubernetes-key.pem \
--trusted-ca-file=/etc/etcd/ca.pem \
--peer-trusted-ca-file=/etc/etcd/ca.pem \
--peer-client-cert-auth \
--client-cert-auth \
--initial-advertise-peer-urls https://$IP:2380 \
--listen-peer-urls https://$IP:2380 \
--listen-client-urls https://$IP:2379,http://127.0.0.1:2379 \
--advertise-client-urls https://$IP:2379 \
--initial-cluster-token etcd-cluster-0 \
--initial-cluster 172.16.16.101=https://172.16.16.101:2380,172.16.16.102=https://172.16.16.102:2380,172.16.16.103=https://172.16.16.103:2380 \
--initial-cluster-state new \
--data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5



[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable etcd
sudo systemctl start etcd
