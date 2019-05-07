## `tfh curl-config`

Show and modify the curl configuration

### Synopsis

    tfe curl-config [TOKEN] [-tfrc]

### Description

View or create a curlrc file for use with TFE. With no arguments, the curlrc file is displayed. If arguments are supplied a curlrc will be recreated.
 
### Options

* `-tfrc`

Recreate the curlrc file using the token in the .terraformrc file. 

* `-curltoken TOKEN`

Recreate the curlrc file with the given token.
