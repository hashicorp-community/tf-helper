## `tfh pushconfig`

Upload a Terraform config to a TFE workspace and begin a run

### Synopsis

    tfh pushconfig [CONFIG_DIR] [OPTIONS]

### Description

Use `tfh pushconfig [CONFIG_DIR] [-org ORG] [-name WORKSPACE]` to begin a run in TFE. Either a configuration can be uploaded, or the current configuration can be run, or a destroy plan can be run.

### Positional parameters

* `CONFIG_DIR`

Path to the configuration that should be uploaded. Defaults to the current working directory.

### Options

* `-message MESSAGE=Queued via tfe-cli`

An optional message to associate with the run. Defaults to "Queued via tfe-cli".

* `-destroy`

Queue a destroy plan. Defaults to false.

* `-current-config BOOLEAN`

Do not push a local configuration. Instead, queue a plan with the latest configuration supplied.

* `-upload-modules=1`

If true (default), then the modules are locked at their current checkout and uploaded completely. This prevents modules from being retrieved with "terraform init". This does not lock provider versions; use the "version" parameter in provider blocks in the configuration to accomplish that.

* `-vcs=1`

If true (default), push will upload only files committed to your VCS, if detected. Currently supports git repositories.

* `-stream`

After staring a plan, stream the logs back to the console.

* `-poll SECONDS=0`

Number of seconds to wait between polling the submitted run for a non-active status. Defaults to 0 (no polling). If streaming logs, controls the seconds between updates.

### Extended description

If you've used `terraform push` with the legacy version of Terraform Enterprise,
here are the important differences to notice:

- `tfh pushconfig` does not read the remote configuration name from an `atlas`
  block in the configuration. It must be provided with the `-org` and `-name`
  options or with the `TFH_org` and `TFH_name` environment variables or with
  `TFH_org` and `TFH_name` in the configuration file.

- `tfh pushconfig` does not upload providers or pin provider versions.
  Terraform Enterprise always downloads providers during the run. Use
  Terraform's built-in support for [pinning provider versions][pin] by setting
  `version` in the provider configuration block. Custom providers will be
  uploaded and used if they are tracked by the VCS and placed in the directory
  where `terraform` will be executed.

[pin]: https://www.terraform.io/docs/configuration/providers.html#provider-versions


#### Example

Given the following repository layout:

```
infrastructure
├── env
│   ├── dev
│   │   └── dev.tf
│   └── prod
│       └── prod.tf
└── modules
    ├── mod1
    │   └── mod1.tf
    └── mod2
        └── mod2.tf
```

Run any of the following commands to push the `prod` configuration (note that
the workspace name must be specified on the command line with `-name` or using
`TFH_org` and `TFH_name`):

```
# If run from the root of the repository
[infrastructure]$ tfh pushconfig env/prog -org org_name -name workspace_name

# If run from the prod directory
[prod]$ tfh pushconfig -org org_name -name workspace_name

# If run from anywhere else on the filesystem
[anywhere]$ tfh pushconfig path/to/infrastructure/env/prod -org org_name -name workspace_name
```

In each of the above commands the contents of the `env/prod` directory
(`prod.tf`) that are tracked by the VCS (git) are archived and uploaded to the
Terraform Enterprise workspace. The files are located using effectively `cd
env/prod && git ls-files`.

If `-vcs 0` is specified then all files in `env/prod` are uploaded. If
`-upload-modules 0` is specified then the `.terraform/modules` directory
