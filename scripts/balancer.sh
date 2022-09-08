#!/bin/bash

apt update && apt install -y haproxy

cat > /etc/haproxy/haproxy.cfg << EOF
frontend kubernetes-frontend
    bind 172.16.16.100:6443
    mode tcp
    option tcplog
    default_backend kubernetes-backend

backend kubernetes-backend
    mode tcp
    option tcp-check
    balance roundrobin
    server kmaster1 172.16.16.101:6443 check fall 3 rise 2
    server kmaster2 172.16.16.102:6443 check fall 3 rise 2
    server kmaster3 172.16.16.103:6443 check fall 3 rise 2
EOF

systemctl restart haproxy

cat >>/etc/hosts<<EOF
172.16.16.100   haproxy.kube.lan    kube-balancer
172.16.16.101   master1.kube.lan    kube-master1
172.16.16.102   master2.kube.lan    kube-master2
172.16.16.103   master3.kube.lan    kube-master3
EOF