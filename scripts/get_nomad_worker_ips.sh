#!/bin/bash

# get nomad server privateDnsNames or ipv4s
NOMAD_SERVER_IPV4=$(aws ec2 describe-instances \
                        --filters "Name=tag:Name,Values=nomad-worker-dev" \
                           | jq -r ".Reservations[0].Instances[].NetworkInterfaces[0].PrivateIpAddresses[0].PrivateIpAddress")
echo -n $NOMAD_SERVER_IPV4
