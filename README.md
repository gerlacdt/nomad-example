# Nomad tutorial

This guide is shamelessly copied from Kelsey Hightower's great presentation at
[hashiconf-eu-2016](https://github.com/kelseyhightower/hashiconf-eu-2016)

[AWS](https://aws.amazon.com/) is used instead of
[Google Cloud Platform](https://cloud.google.com/)

## Instructions

### Install terraform

see [terraform](https://www.terraform.io/intro/getting-started/install.html)
This guide uses terrform v0.8.6

### Create aws infrastructure


The stack contains:

* 3 master consul/nomad-nodes (m4.large)
* an autoscaling-group with 2 nomad-workers (m4.large)
* an ELB attached with the autoscaling-group

The stack uses:

* ubuntu AMI `ami-98ecb7fe`, name: `ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-20170202`
  * username is `ubuntu`
* aws-region is `eu-west-1`

``` bash
cd terraform

cp terrafrom.tfvars.tmpl terraform.tfvars
# adjust the variables
# vim terraform.tfvars

terraform validate  # validate terraform project files
terraform plan      # look what will be created
terraform apply     # create infrastructure
terraform destroy   # clean up your resources!
```

### Setup consul, nomad, vault on your local machine

The guide is based
on
[consul-v0.7.5](https://www.consul.io/downloads.html),
[nomad-v0.5.4](https://www.nomadproject.io/downloads.html),
[vault-v0.6.5](https://www.vaultproject.io/downloads.html)

```bash
# download consul, nomad and vault to your laptop
# put them in your $PATH

cd terraform/helpers

NOMAD_SERVER_IPS=$(./get_nomad_server_ips.sh)
MASTER_IP=$(echo -n $NOMAD_SERVER_IPS | awk '{print $1}')

# joining the nomad and consul cluster is not necessary (it's done automatically)
# nomad server-join --address="http://$MASTER_IP:4646" $(echo -n $NOMAD_SERVER_IPS | awk '{print $2,$3}')
# consul join --rpc-addr="$MASTER_IP:8400" $(echo -n $NOMAD_SERVER_IPS | awk '{print $2,$3}')

# check nomad and consul master nodes
nomad server-members --address="http://$MASTER_IP:4646"
consul members --rpc-addr="$MASTER_IP:8400"

# check nomad workers (takes some time)
nomad node-status --address="http://$MASTER_IP:4646"

# get ELB dns-name
export ELB=$(./get_elb_dns.sh)
```

### Setup Vault (optional)

``` bash
export VAULT_ADDR=http://$MASTER_IP:8200

# get all the 5 unseal keys and root token (store them somewhere!)
vault init

# unseal vault
vault unseal
vault unseal
vault unseal

# check unseal status
vault status

# login
vault auth <root-token>

# vault is ready to use
```

## Nomad usage guide

### Rollout consul workers

```bash
nomad plan --address=http://$MASTER_IP:4646 consul.nomad
nomad run --address=http://$MASTER_IP:4646 consul.nomad
nomad status --address=http://$MASTER_IP:4646 consul
```

### Rollout fabio (zero-conf load balancing)

```bash
nomad plan --address=http://$MASTER_IP:4646 fabio.nomad
nomad run --address=http://$MASTER_IP:4646 fabio.nomad
nomad status --address=http://$MASTER_IP:4646 fabio
```

### consul and fabio web-uis

``` bash
# consul
http://$ELB:8500/ui

# fabio
http://$ELB:9998
```

### Rollout helloapp v1

```bash
nomad plan --address=http://$MASTER_IP:4646 helloapp.nomad
nomad run --address=http://$MASTER_IP:4646 helloapp.nomad
nomad status --address=http://$MASTER_IP:4646 helloapp

# make some requests
curl -s -H "Host: hello.internal" http://$ELB/version
curl -s -H "Host: hello.internal" http://$ELB/hello
curl -s -H "Host: hello.internal" http://$ELB/health

nomad logs -f --address=http://$MASTER_IP:4646 -stderr <alloc-id>
```

### Scale helloapp v1

```bash
# set count = 5

nomad plan --address=http://$MASTER_IP:4646 helloapp.nomad
nomad run --address=http://$MASTER_IP:4646 helloapp.nomad
```

### Poll helloapp periodically

```bash
while true; do curl -s -H "Host: hello.internal" http://$ELB/version; sleep 1; done
```

### Update helloapp v2
```bash
# set new docker image helloapp v2

nomad plan --address=http://$MASTER_IP:4646 helloapp.nomad
nomad run --address=http://$MASTER_IP:4646 helloapp.nomad
nomad status --address=http://$MASTER_IP:4646 helloapp

# stop job after playing around
nomad stop --address=http://$MASTER_IP:4646 helloapp
```

### Blue-green Deployment / Canary

```bash
nomad plan --address=http://$MASTER_IP:4646 helloapp-blue-green.nomad
nomad run --address=http://$MASTER_IP:4646 helloapp-blue-green.nomad
nomad status --address=http://$MASTER_IP:4646 helloapp-blue-green

# change blue count to 0
# change green count to 2
nomad plan --address=http://$MASTER_IP:4646 helloapp-blue-green.nomad
nomad run --address=http://$MASTER_IP:4646 helloapp-blue-green.nomad
nomad status --address=http://$MASTER_IP:4646 helloapp-blue-green

# finer grained routing
# set blue count 2 and green count 2
nomad plan --address=http://$MASTER_IP:4646 helloapp-blue-green.nomad
nomad run --address=http://$MASTER_IP:4646 helloapp-blue-green.nomad
nomad status --address=http://$MASTER_IP:4646 helloapp-blue-green

# change fabio route weight overrides in fabio-web-ui
route weight hello-service hello.internal weight 1.0 tags "blue"   # v0.1.0
route weight hello-service hello.internal weight 1.0 tags "green"  # v0.2.0
```

### Install Redis

```bash
nomad plan --address=http://$MASTER_IP:4646 redis.nomad
nomad run --address=http://$MASTER_IP:4646 redis.nomad
nomad status --address=http://$MASTER_IP:4646 redis
nomad logs -f --address=http://$MASTER_IP:4646 <alloc-id>

# lookup redis port
curl $ELB:8500/v1/catalog/service/cache-redis | jq
```

### Create Schedule Batch Job

``` bash
nomad plan batch.nomad
nomad run batch.nomad
nomad status batch
nomad status <batch/periodic-id>
nomad logs --address=http://$MASTER_IP:4646 <alloc-id>
```

### Nomad dynamic port binding

More information can be found in the nomad docs:

* [nomad-docker](https://www.nomadproject.io/docs/drivers/docker.html)
* [nomad-runtime-environment](https://www.nomadproject.io/docs/runtime/environment.html)

```bash
# nomad can bind ports dynamically so you don't have to expose them in the Dockerfile
# i.e. manual docker command:
# docker run --rm  --expose 8080 -p 8080:8080 -e NOMAD_PORT_http=8080 gerlacdt/helloapp:v0.3.0

nomad plan --address=http://$MASTER_IP:4646 helloapp-dynamic.nomad
nomad run --address=http://$MASTER_IP:4646 helloapp-dynamic.nomad
nomad status --address=http://$MASTER_IP:4646 helloapp-dynamic
```

# References

* [nomad](https://www.nomadproject.io/)
* [Large-scale cluster management at Google with Borg](http://research.google.com/pubs/pub43438.html)
