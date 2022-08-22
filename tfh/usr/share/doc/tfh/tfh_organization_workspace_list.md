## `tfh organization workspace list`

/organizations/{ORGANIZATION_NAME}/workspaces

### Synopsis

    tfh organization workspace list [ ... ]

### REST endpoint

    GET https://{HOSTNAME}/api/v2/organizations/{ORGANIZATION_NAME}/workspaces

### Description

https://www.terraform.io/enterprise/api-docs/workspaces

### Positional parameters

* `ORGANIZATION_NAME`

### Output

| ID                   | Name                               | Terraform version | Locked | Execution mode | VCS repo                                |
| -------------------- | ---------------------------------- | ------------------------------- | -------------------- | ---------------------------- | --------------------------------- |
| `.id`                | `.attributes.name`                 | `.attributes.terraform-version` | `.attributes.locked` | `.attributes.execution-mode` | `.attributes.vcs-repo.identifier` | `.data` |
