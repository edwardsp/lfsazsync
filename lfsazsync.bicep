targetScope = 'resourceGroup'

param location string = resourceGroup().location
param subnet_id string
param vmsku string = 'Standard_D32ds_v4'
param admin_user string
param ssh_key string
param lustre_mgs string
param storage_account_name string
param storage_container_name string
param storage_sas_key string
param ssh_port int = 8822
param download_url string
@allowed([
  'ubuntu2004'
  'almalinux87'
])
param os string = 'almalinux87'

// substitute the args for install.sh:
// - '$1' -> lustre_mgs
// - '$2' -> storage_account_name
// - '$3' -> storage_sas_key
// - '$4' -> storage_container_name
// - '$5' -> ssh_port
// - '$6' -> download_site
var install_script = replace(replace(replace(replace(replace(replace(replace(loadTextContent('install.sh'), 'lustre_mgs="$1"', 'lustre_mgs="${lustre_mgs}"'), 'storage_account="$2"', 'storage_account="${storage_account_name}"'), 'storage_sas="$3"', 'storage_sas="${storage_sas_key}"'), 'storage_container="$4"', 'storage_container="${storage_container_name}"'), 'ssh_port="$5"', 'ssh_port="${ssh_port}"'), 'download_url="$6"', 'download_url="${download_url}"'), 'os_version="$7"', 'os_version="${os}"')

resource lfsazsyncnic 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: 'lfsazsync-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'lfsazsync-ipconfig'
        properties: {
          subnet: {
            id: subnet_id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

var imageRef = {
  ubuntu2004: {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-server-focal'
    sku: '20_04-lts-gen2'
    version: 'latest'
  }
  almalinux87: {
    publisher: 'almalinux'
    offer: 'almalinux'
    sku: '8-gen2'
    version: '8.7.2022122801'
  }
}

var imagePlans = {
  ubuntu2004: {}
  almalinux87: {
    publisher: 'almalinux'
    product: 'almalinux'
    name: '8-gen2'
  }
}

resource lfsazsyncvm 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: 'lfsazsync-vm'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  plan: imagePlans[os]
  properties: {
    hardwareProfile: {
      vmSize: vmsku
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        caching: 'ReadWrite'
        diskSizeGB: 64
      }
      imageReference: imageRef[os]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: lfsazsyncnic.id
        }
      ]
    }
    osProfile: {
      computerName: 'lfsazsync'
      adminUsername: admin_user
      customData: base64(install_script)
    
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${admin_user}/.ssh/authorized_keys'
              keyData: ssh_key
            }
          ]
        }
      }
    }
  }
}
