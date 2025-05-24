# bah-foundations-lab

Becoming a Hacker Foundations Lab running on Cisco Modeling Labs

## Create Labs

* Edit `config.yml` and set `pod_count` to the desired count.
* Run `terraform apply`

```
terraform apply
```

Labs will be created, along with pod users, groups and passwords.

* After the labs are created, get the usernames and passwords with 
  `terraform output`:

```
terraform output -json | jq .cml_credentials.value
```

Example:
```
terraform output -json | jq .cml_credentials.value
{
  "pod1": "personally-cute-manatee",
  "pod2": "evidently-eternal-treefrog",
  "pod3": "plainly-trusted-crane"
} 
```

> [!NOTE]
> If you want to override the randomized passwords that are generated, create a file
> in the workspace root called `cml_credentials.json`.  The file should have the same
> format as `terraform output -json | jq .cml_credentials.value`, e.g.
>
> ```json
> {
>   "pod1": "rarely-valid-sole",
>   "pod10": "lately-settled-ghoul",
>   "pod2": "manually-artistic-penguin",
>   "pod3": "trivially-proper-chigger",
>   "pod4": "strictly-tough-burro",
>   "pod5": "neatly-sunny-crane",
>   "pod6": "thoroughly-settling-beagle",
>   "pod7": "nationally-sincere-gannet",
>   "pod8": "legally-enabled-wolf",
>   "pod9": "presumably-refined-camel"
> }
> ```
> 
> If the pod is not defined, it will get a randomly-generated password based on
> [`random_pet`](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet).

## Bring your own IPv4

We already have PAPs and PDPs set up in `ASIG-BAH-GCP`.  There needs to be a 
forwarding rule for every `/32`.

Becoming a Hacker Foundations has one `/28`
[delegated to it](https://console.cloud.google.com/networking/byoip/list?invt=Abms5A&project=gcp-asigbahgcp-nprd-47930) in `us-east1`, this prefix can be used with VMs or a Load Balancer:

* `172.98.19.240/28`

Example using gloud CLI:

```
$ gcloud compute public-delegated-prefixes describe sub-172-98-19-240-28
byoipApiVersion: V2
creationTimestamp: '2025-03-14T14:31:25.815-07:00'
description: ''
fingerprint: Bjex8Votv0g=
id: '7360803315358703298'
ipCidrRange: 172.98.19.240/28
kind: compute#publicDelegatedPrefix
name: sub-172-98-19-240-28
parentPrefix: https://www.googleapis.com/compute/v1/projects/gcp-asigaurynbyoipg-nprd-33190/regions/us-east1/publicDelegatedPrefixes/pdp-172-98-19-240-28
publicDelegatedSubPrefixs:
- delegateeProject: gcp-asigbahgcp-nprd-47930
  description: ''
  ipCidrRange: 172.98.19.240/28
  isAddress: true
  name: sub-172-98-19-240-28-addresses
  region: us-east1
  status: ACTIVE
region: https://www.googleapis.com/compute/v1/projects/gcp-asigbahgcp-nprd-47930/regions/us-east1
selfLink: https://www.googleapis.com/compute/v1/projects/gcp-asigbahgcp-nprd-47930/regions/us-east1/publicDelegatedPrefixes/sub-172-98-19-240-28
status: ANNOUNCED_TO_INTERNET
```

It's not [currently possible](https://github.com/hashicorp/terraform-provider-google/issues/19147) to create addresses from a PDP in Terraform.  This has to be done manually and should already be done for you.


## Bring your own IPv6

We already have PAPs and PDPs set up in `ASIG-BAH-GCP`.  There needs to be a 
forwarding rule for every `/64`.

Becoming a Hacker Foundations has two `/56`s
[delegated to it](https://console.cloud.google.com/networking/byoip/list?invt=Abms5A&project=gcp-asigbahgcp-nprd-47930) in `us-east1`, one prefix is for [Subnets](https://cloud.google.com/compute/docs/reference/rest/v1/subnetworks/insert) to assign to hosts in GCE, the other is for Load Balancer Forwarding Rules:

* `2602:80a:f004:100::/56`
* `2602:80a:f004:200::/56`

Example using gloud CLI:

```
$ gcloud compute public-delegated-prefixes describe nlb-2602-80a-f004-100-56
allocatablePrefixLength: 64
byoipApiVersion: V2
creationTimestamp: '2025-03-16T16:47:52.097-07:00'
description: ''
fingerprint: EGVdzQREMEQ=
id: '4107084448669556167'
ipCidrRange: 2602:80a:f004:100::/56
kind: compute#publicDelegatedPrefix
mode: EXTERNAL_IPV6_FORWARDING_RULE_CREATION
name: nlb-2602-80a-f004-100-56
parentPrefix: https://www.googleapis.com/compute/v1/projects/gcp-asigaurynbyoipg-nprd-33190/regions/us-east1/publicDelegatedPrefixes/sub-2602-80a-f004-100-56
region: https://www.googleapis.com/compute/v1/projects/gcp-asigbahgcp-nprd-47930/regions/us-east1
selfLink: https://www.googleapis.com/compute/v1/projects/gcp-asigbahgcp-nprd-47930/regions/us-east1/publicDelegatedPrefixes/nlb-2602-80a-f004-100-56
status: ANNOUNCED_TO_INTERNET
```

## Start Labs

* You can either ask the students to start the labs themselves, or you can start
  all labs from the Dashboard, Choose `Rows per Page: All`, Select All,
  then `Start`.
  
## Troubleshooting

### cty.StringVal("STARTED")

If you see an error like this:
```
│ Error: Provider produced inconsistent result after apply
│
│ When applying changes to module.pod[1].cml2_lifecycle.top, provider
| "provider[\"registry.terraform.io/ciscodevnet/cml2\"]" produced an unexpected
| new value: .state: was cty.StringVal("DEFINED_ON_CORE"), but now
| cty.StringVal("STARTED").
```
It means you're trying to change labs that are currently running.  You have to
stop and wipe them before making kinds of changes.

* Stop all labs from the Dashboard, Choose `Rows per Page: All`, Select All,
  then `Stop`, followed by `Wipe`, then `terraform apply` again:

```
terraform apply
```

* If this doesn't fix it, delete the single applicable pod in the error message
  and reapply:

```
terraform destroy -target 'module.pod[1]'
```
```
terraform apply
```

If this still doesn't fix it, delete all the pods and start over:

```
terraform destroy -target 'module.pod'
```
```
terraform apply
```

This is, of course, a destructive operation and the whole class will have to restart their labs.

**Note**: If you destroy the entire deployment, all the passwords will change upon apply!

### Lab is not in DEFINED_ON_CORE state

For this error:
```
│ Error: CML2 Provider Error
│
│ lab is not in DEFINED_ON_CORE state
```
Wipe the pod, and try again.  Let's say it's pod 1 you want to recreate:

```
terraform destroy -target module.pod[0]
terraform apply
```

### Lab compute hosts have been preempted and the cluster is an unhealthy state

The symptoms are the cluster is unhealthy, and some/all lab nodes are in a
`DISCONNECTED` state signified by an orange chain link icon with a white slash
through it.

#### Recovery

As far as what it takes to recover, these are the steps:

* In [CML node administration](https://becomingahacker.com/system_admin/nodes), filter by state `DISCONNECTED`, select All, then **Stop** and **Wipe** the nodes.  This will remove them from that compute node.
* In [CML compute hosts](https://becomingahacker.com/system_admin/compute_hosts), select the `Disconnected` host (with the red X state), change the admission state to `REGISTERED`, then choose `DECOMMISSION`, then chose `REMOVE`.
* The System Health should return back to green.
* In the [Google Compute Engine Instance Groups](https://console.cloud.google.com/compute/instanceGroups/list?inv=1&invt=AbyRIA&project=gcp-asigbahgcp-nprd-47930), choose the `cml-instance-group-manager-XXXXXX`, chose the VM that was preempted in the compute hosts above, then delete the node(s).
* The `Target running size` will shrink by the number of nodes you delete.  Set it back to the desired state by `Edit`ing the instance group manager and set back to the desired target size.
* New nodes will be created, and they will automatically be registered in CML.  Just be patient.  It takes a couple of minutes.
* Monitor the [CML Cluster Status](https://becomingahacker.com/diagnostics/cluster_status) page and wait for the system to return to normal and all services are healthy
* Have the students start their lab pods, if desired.  I'd recommend not provisioning the compute nodes as Spot for a class.  Reserve Spot for off-times.  You can change the provisioning model on the fly by changing the Template from the instance group manager for the compute nodes.

#### Long Term Fix

* The root cause is when a machine is preempted, it's stopped by Google, and the machine's [local storage on SSDs is lost](https://cloud.google.com/compute/docs/disks/local-ssd#data_persistence).  This state can be preserved by Google, but that's a relatively new feature in Preview at the time of writing and we aren't using it.  We use Local Storage for running labs because the performance is 100x better than running on mounted disks (like EBS if you're familiar with AWS).  It seriously makes a huge difference.
* The [machine](https://cloud.google.com/compute/docs/instances/preemptible#preemption-process) needs to recognize it's being [preempted](https://cloud.google.com/compute/docs/instances/create-use-preemptible#detecting_if_an_instance_was_preempted), and not just with an ordinary shutdown.  The Google Guest Agent can run [scripts](https://github.com/GoogleCloudPlatform/guest-agent?tab=readme-ov-file#metadata-scripts) during a shutdown.  See this [Stack Overflow Post](https://stackoverflow.com/a/57862925/29463184) for details.
* This script can query the machine preemption state from the metadata server with `curl "http://metadata.google.internal/computeMetadata/v1/instance/preempted" -H "Metadata-Flavor: Google"` and check for a return value of `TRUE`.  If the target state is `TRUE` the server has been preempted and Google will destroy the instance in or around *30 seconds*.
* Next the script should [**Stop** and **Wipe**](https://developer.cisco.com/docs/modeling-labs/deleting-labs/) all its [resident Nodes with the appropriate compute ID](https://becomingahacker.com/api/v0/ui/#/Nodes) with the CML controller (as shown in the recovery steps above, but using the [APIs](https://becomingahacker.com/api/v0/ui/#/System)), and deregister itself before committing Seppuku.  When CML stops a node, it doesn't stop them gracefully with the current version and it's relatively quick.  This API needs privileged credentials and the compute nodes should probably each have their own, rather than using a common one.
* The compute host will die, and the instance group manager will restart the node in the same availability zone with the same boot disk.  This means the compute node may stay down if there are no more resources, but this is rare.  The compute node will register itself and be available for use with labs and nodes.  This step will likely need some further fixes.  The instance group manager likely needs some tweaks to do some health checking to force recreations in different zones in the region.

