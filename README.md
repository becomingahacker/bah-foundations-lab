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
