#!/bin/bash

# get nomad server privateDnsNames or ipv4s
NOMAD_SERVER_IPV4=$(aws ec2 describe-instances \
                        --filters "Name=tag:Name,Values=nomad-worker-dev" "Name=instance-state-code,Values=16" \
                        | jq -r ".Reservations[].Instances[].NetworkInterfaces[0].PrivateIpAddresses[0].PrivateIpAddress")
echo -n $NOMAD_SERVER_IPV4
