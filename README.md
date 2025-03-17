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
[delegated to it](https://console.cloud.google.com/networking/byoip/list?invt=Abms5A&project=gcp-asigbahgcp-nprd-47930) in `us-east1`:

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

```
for i in `seq 240 255`
do 
  gcloud compute forwarding-rules create --ip-protocol=L3_DEFAULT \
    --ports=ALL \
    --backend-service="projects/gcp-asigbahgcp-nprd-47930/regions/us-east1/backendServices/c8k-backend-service" \
    --ip-version=IPV4 \
    --load-balancing-scheme=EXTERNAL \
    --network-tier=PREMIUM \
    --region=us-east1 \
    --address=172.98.19.$i \
    fr-172-98-19-$i
done
```

## Bring your own IPv6

We already have PAPs and PDPs set up in `ASIG-BAH-GCP`.  There needs to be a 
forwarding rule for every `/64`.

Becoming a Hacker Foundations has two `/56`s
[delegated to it](https://console.cloud.google.com/networking/byoip/list?invt=Abms5A&project=gcp-asigbahgcp-nprd-47930) in `us-east1`:

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

```
for i in `seq 100 105`
do 
  gcloud compute forwarding-rules create --ip-protocol=L3_DEFAULT \
    --ports=ALL \
    --backend-service="projects/gcp-asigbahgcp-nprd-47930/regions/us-east1/backendServices/c8k-backend-service" \
    --ip-version=IPV6 \
    --load-balancing-scheme=EXTERNAL \
    --network-tier=PREMIUM \
    --region=us-east1 \
    --ip-collection="nlb-2602-80a-f004-100-56" \
    --address="2602:80a:f004:${i}::/64" \
    fr-2602-80a-f004-${i}-64
done
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
