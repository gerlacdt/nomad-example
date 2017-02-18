#!/bin/bash

mkdir -p local/data

export AWS_DEFAULT_REGION=eu-west-1
# get nomad server ipv4s
NOMAD_SERVER_IPV4=$(aws ec2 describe-instances \
                        --filters "Name=tag:Name,Values=nomad-server-dev" "Name=instance-state-code,Values=16" \
                        | jq ".Reservations[].Instances[].NetworkInterfaces[0].PrivateIpAddresses[0].PrivateIpAddress")

SERVERS=""
for i in $NOMAD_SERVER_IPV4
do
    SERVERS+="${i}, "
done

SERVERS=$(echo -n $SERVERS | sed -e "s/,$//")
IP_ADDRESS=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)

cat > local/config.json <<'EOF'
{
  "bootstrap": false,
  "server": false,
  "datacenter": "dc1",
  "data_dir": "local/data",
  "retry_join": [CONSUL_SERVERS],
  "advertise_addr": "IP_ADDRESS",
  "client_addr": "0.0.0.0",
  "ui_dir": "local/ui"
}
EOF

sed -i -e "s/CONSUL_SERVERS/$SERVERS/" local/config.json
sed -i -e "s/IP_ADDRESS/$IP_ADDRESS/" local/config.json



# starting consul
local/consul agent --config-file local/config.json
