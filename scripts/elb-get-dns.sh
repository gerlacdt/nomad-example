#!/bin/bash

aws elb describe-load-balancers --load-balancer-names nomad-worker | jq -r ".LoadBalancerDescriptions[].DNSName"
