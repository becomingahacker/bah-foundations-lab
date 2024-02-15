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
  all nodes from Tools &rarr; System Administration &rarr; Node Administration
  &rarr; Select All, then `Start`.
