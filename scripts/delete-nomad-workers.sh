#!/bin/bash

NOMAD_INSTANCE_IDS=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=nomad-worker-dev" \
                            | jq ".Reservations[].Instances[].InstanceId" \
                            | tr -d '"')
echo "Deleting nomad workers: " $NOMAD_INSTANCE_IDS
aws ec2 terminate-instances --instance-ids $(echo -n $NOMAD_INSTANCE_IDS)
