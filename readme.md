# Lustre to Azure BLOB Synchronisation

## Introduction

This document describes how to setup a Lustre to Azure BLOB synchronisation.  The synchronisation is achieved using the Lustre HSM (Hierarchical Storage Management) interface combined with the Robinhood policy engine and another tool which reads the Lustre changelog and synchronises metadata with the archived storage.  A Bicep template is provided to deploy and setup the a virtual machine for this purpose.

This setup uses a single virtual machine for all tasks.  The HSM daemon could be run on multiple virtual machine to increase transfer peformance.  The bandwidth for archiving and retrieval will be limited to approximately half the network bandwidth of the virtual machine as the same network will be used for accessing the Lustre filesystem and accessing Azure Storage.

## Prerequisites

The following is required before running the Bicep template:
* Virtual Network
* Azure BLOB Storage Account and container (HNS is not supported)
* Lustre filesystem

The Lustre filesystem requires the following configuration:

```
lctl --device "lustrefs-MDT0000" changelog_register
lctl --device "lustrefs-MDT0000" changelog_register
lctl set_param -P "mdd.lustrefs-MDT0000.changelog_mask"=all-ATIME-FLRW-GXATR-MARK-MIGRT-NOPEN-OPEN-RESYNC-XATTR-LYOUT
lctl set_param -P "mdt.lustrefs-MDT0000.hsm.max_hal_count"=3
lctl set_param -P "mdt.lustrefs-MDT0000.hsm.max_requests"=384
lctl set_param -P "mdt.lustrefs-MDT0000.hsm.active_request_timeout"=432000
```

## Deploying the Bicep template

The Bicep template has the following parameters:

| Parameter              | Description                                                       |
| ---------------------- | ----------------------------------------------------------------- |
| subnet_id              | The ID of the subnet to deploy the virtual machine to             |
| vm_sku                 | The SKU of the virtual machine to deploy                          | 
| admin_user             | The username of the administrator account                         |
| ssh_key                | The public key for the administrator account                      |
| lustre_mgs             | The IP address/hostname of the Lustre MGS                         |
| storage_account_name   | The name of the Azure storage account                             |
| storage_container_name | The container to use for synchonising the data                    |
| storage_account_key    | A SAS key for the storage account                                 |
| ssh_port               | The port used by sshd on the virtual machine                      |
| github_release         | Release tag where the robinhood and lemur will be downloaded from |
| os                     | The OS to use for the VM (options: ubuntu2004 or almalinux87)     |

```
# TODO: set the account name and container name below
account_name=
container_name=

start_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
expiry_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ" --date "next month")

az storage container generate-sas \
   --account-name $account_name \
   --name $container_name \
   --permissions rwld \
   --start $start_date \
   --expiry $expiry_date \
   -o tsv
```

The following Azure CLI command can be used to get the subnet ID:

```
# TODO: set the variable below
resource_group=
vnet_name=
subnet_name=

az network vnet subnet show --resource-group $resource_group --vnet-name $vnet_name --name $subnet_name --query id --output tsv
```

The following Azure CLI command can be used to deploy the Bicep template:

```
# TODO: set the variables below
resource_group=
subnet_id=
vmsku=Standard_D32ds_v4
admin_user=
ssh_key=
lustre_mgs=
storage_account_name=
storage_container_name=
storage_sas_key=
ssh_port=
github_release=
os=

az deployment group create \
    --resource-group $resource_group \
    --template-file lfsazsync.bicep \
    --parameters \
        subnet_id="$subnet_id" \
        vmsku=$vmsku \
        admin_user="$admin_user" \
        ssh_key="$ssh_key" \
        lustre_mgs=$lustre_mgs \
        storage_account_name=$storage_account_name \
        storage_container_name=$storage_container_name \
        storage_sas_key="$storage_sas_key" \
        ssh_port=$ssh_port \
        github_release=$github_release \
        os=$os
```

After this call completes the virtual machine will be deployed although it will take more time to install and import the metadata from Azure BLOB storage into the Lustre filesystem.  The progress can be monitored by looking at the `/var/log/cloud-init-output.log` file on the virtual machine.

## Monitoring

The install will set up three systemd services for lhsmd, robinhood and lustremetasync.  The log files are located here:

* 'lhsmd': /var/log/lhsmd.log
* 'robinhood': /var/log/robinhood*.log
* 'lustremetasync': /var/log/lustremetasync.log

