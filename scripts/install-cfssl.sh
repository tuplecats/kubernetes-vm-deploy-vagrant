#!/bin/bash

install_cfssl() {
    wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
    wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64

    chmod +x cfssl*

    sudo mv cfssl_linux-amd64 /usr/local/bin/cfssl
    sudo mv cfssljson_linux-amd64 /usr/local/bin/cfssljson

    cfssl version
    cat > ca-config.json <<EOF
    {
    "signing": {
        "default": {
        "expiry": "8760h"
        },
        "profiles": {
        "kubernetes": {
            "usages": ["signing", "key encipherment", "server auth", "client auth"],
            "expiry": "8760h"
        }
        }
    }
    }
EOF

    cat > ca-csr.json <<EOF
    {
    "CN": "Kubernetes",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
    {
        "C": "IN",
        "L": "Belgaum",
        "O": "Tansanrao",
        "OU": "CA",
        "ST": "Karnataka"
    }
    ]
    }
EOF

    cfssl gencert -initca ca-csr.json | cfssljson -bare ca

    cat > kubernetes-csr.json <<EOF
    {
    "CN": "Kubernetes",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
    {
        "C": "IN",
        "L": "Belgaum",
        "O": "Tansanrao",
        "OU": "CA",
        "ST": "Karnataka"
    }
    ]
    }
EOF

    cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -hostname=172.16.16.101,172.16.16.102,172.16.16.103,127.0.0.1 \
    -profile=kubernetes kubernetes-csr.json | \
    cfssljson -bare kubernetes

    mkdir -p /tmp/downloaded
    cp ca.pem /tmp/downloaded/
    cp kubernetes.pem /tmp/downloaded/
    cp kubernetes-key.pem /tmp/downloaded/

    sshpass -p "kubeadmin" scp -r -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no /tmp/downloaded root@master2.kube.lan:/tmp/downloaded
    sshpass -p "kubeadmin" scp -r -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no /tmp/downloaded root@master3.kube.lan:/tmp/downloaded
}