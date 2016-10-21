#!/bin/bash

export AWS_DEFAULT_REGION="eu-west-1"
export IP_ADDRESS=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)

## change working directory
mkdir -p /tmp
cd /tmp

## install aws-cli

curl -O https://bootstrap.pypa.io/get-pip.py
python3 get-pip.py
pip install awscli
rm get.pip.py

apt-get update
apt-get install -y unzip dnsmasq jq

# aws-cli and jq needed...
export NOMAD_SERVER_IPV4=$(aws ec2 describe-instances \
                               --filters "Name=tag:Name,Values=nomad-server-dev" \
                                  | jq ".Reservations[0].Instances[].NetworkInterfaces[0].PrivateIpAddresses[0].PrivateIpAddress" | tr "\n" "," | sed 's/,$//';)

## Setup dnsmasq

mkdir -p /etc/dnsmasq.d
cat > /etc/dnsmasq.d/10-consul <<'EOF'
server=/consul/127.0.0.1#8600
EOF

systemctl enable dnsmasq
systemctl start dnsmasq

## install docker

apt-get install -y linux-image-extra-$(uname -r) linux-image-extra-virtual apt-transport-https ca-certificates
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" | tee /etc/apt/sources.list.d/docker.list
apt-get update
apt-cache policy docker-engine
apt-get install -y docker-engine

systemctl enable docker
systemctl start docker

## install nomad worker (at last so that system is ready for jobs)

wget https://releases.hashicorp.com/nomad/0.4.1/nomad_0.4.1_linux_amd64.zip
unzip nomad_0.4.1_linux_amd64.zip
mv nomad /usr/local/bin/

mkdir -p /var/lib/nomad
mkdir -p /etc/nomad

rm nomad_0.4.1_linux_amd64.zip

cat > client.hcl <<EOF
addresses {
    rpc  = "ADVERTISE_ADDR"
    http = "ADVERTISE_ADDR"
}

advertise {
    http = "ADVERTISE_ADDR:4646"
    rpc  = "ADVERTISE_ADDR:4647"
}

data_dir  = "/var/lib/nomad"
bind_addr = "0.0.0.0"
log_level = "DEBUG"

client {
    enabled = true
    servers = [
      NOMAD_SERVERS
    ]
    options {
        "driver.raw_exec.enable" = "1"
    }
}
EOF
sed -i "s/ADVERTISE_ADDR/${IP_ADDRESS}/" client.hcl
sed -i "s/NOMAD_SERVERS/${NOMAD_SERVER_IPV4}/" client.hcl
mv client.hcl /etc/nomad/client.hcl

cat > nomad.service <<'EOF'
[Unit]
Description=Nomad
Documentation=https://nomadproject.io/docs/

[Service]
ExecStart=/usr/local/bin/nomad agent -config /etc/nomad
ExecReload=/bin/kill -HUP $MAINPID
LimitNOFILE=65536
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
mv nomad.service /etc/systemd/system/nomad.service

systemctl enable nomad
systemctl start nomad
