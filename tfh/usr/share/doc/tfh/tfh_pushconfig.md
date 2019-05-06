## `tfh pushconfig`

Upload a Terraform config to a TFE workspace and begin a run

### Synopsis

    tfh pushconfig [OPTIONS] [CONFIG_DIR]

### Description

Upload a Terraform configuration to a Terraform Enterprise workspace and begin a run.

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
