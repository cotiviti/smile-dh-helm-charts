# Example Helm Values File Snippets

This directory contains a number of Helm Values file snippets that can be used with the Smile CDR Helm Chart.

They are here to demonstrate how you would configure the chart to enable certain features of Smile CDR.

>**Note:** These are examples to be used as a basis for your configurations. They should not be used as-is without analyzing them and updating them to better suit your requirements.

## Import of data
The following examples can be used to configure Smile CDR for importing data in various ways

### `smileutil-upload-terminology.yaml`
Configures Smile CDR with increased memory and ephemeral volume sizes to allow use of the `smileutil upload-terminology` command.
Requires additional configuration to enable S3 file copying.
