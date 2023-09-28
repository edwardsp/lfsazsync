targetScope = 'resourceGroup'

param fsname string = 'amlfs'
param location string = resourceGroup().location
param vnet_name string = 'vnet'
param vnet_cidr string = '10.242.0.0/23'
param vnet_main string = 'main'
param vnet_main_cidr string = '10.242.0.0/24'
param vnet_amlfs string = 'amlfs'
param vnet_amlfs_cidr string = '10.242.1.0/24'
param storage_name string = 'storage${uniqueString(resourceGroup().id)}'

resource commonNsg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: 'nsg-common'
  location: location
  properties: {
    securityRules: [
    ]
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: vnet_name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnet_cidr
      ]
    }
    subnets: [
      {
        name: vnet_main
        properties: {
          addressPrefix: vnet_main_cidr
          networkSecurityGroup: {
            id: commonNsg.id
          }
        }
      }
      {
        name: vnet_amlfs
        properties: {
          addressPrefix: vnet_amlfs_cidr
          networkSecurityGroup: {
            id: commonNsg.id
          }
        }
      }
    ]
  }
}

resource amlfsSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-05-01' existing = {
  parent: virtualNetwork
  name: vnet_amlfs
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: storage_name
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    minimumTlsVersion: 'TLS1_2'
  }
}

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2021-09-01' = {
  name: 'default'
  parent: storageAccount
}

resource lustreArchive 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-06-01' = {
  name: 'lustre'
  parent: blobServices
  properties: {
    publicAccess: 'None'
  }
}

resource fileSystem 'Microsoft.StorageCache/amlFileSystems@2021-11-01-preview' = {
  name: fsname
  location: location
  sku: {
    name: 'AMLFS-Durable-Premium-250'
  }
  properties: {
    storageCapacityTiB: 8
    zones: [ 1 ]
    filesystemSubnet: amlfsSubnet.id
    maintenanceWindow: {
      dayOfWeek: 'Friday'
      timeOfDay: '21:00'
    }
  }
}

output location string = location
output subnet_id string = amlfsSubnet.id
output lustre_id string = fileSystem.id
output lustre_mgs string = fileSystem.properties.mgsAddress
output storage_account_name string = storageAccount.name
output container_name string = lustreArchive.name
