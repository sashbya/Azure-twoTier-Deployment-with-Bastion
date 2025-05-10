@description('Azure deployment region')
@allowed(['japaneast', 'eastus','easteurope'])
param location string = 'japaneast'

@description('Name of the Virtual Network')
param vnetName string = 'bastion-vnet'

@description('Name of the web VM subnet')
param webSubnetName string = 'web-subnet'

@description('Name of the database subnet')
param dbSubnetName string = 'db-subnet'

@description('Name of the Bastion subnet')
param bastionSubnetName string = 'AzureBastionSubnet' //Name required by Microsoft for Bastion to function

@description('Name of the Bastion Public IP')
param bastionpip string = 'bastion-pip'

@description('Name of the Bastion Host')
param bastionhost string = 'bastion-host'

@description('Name of the Network Security Group(NSG)')
param nsgName string = 'bastion-vm-nsg'

@description('Globally unique DNS name')
param dnsNameLabel string = toLower('${bastionhost}-${uniqueString(resourceGroup().id)}')

@description('Name of the web VM nic')
param webNicName string = 'web-vm-nic'

@description('Name of the first VM (web)')
param webVmName string = 'web-vm'

@description('Name of the Network Interface for database VM')
param dbnicName string = 'db-vm-nic'

@description('Name of the second VM (database)')
param dbVmName string = 'db-vm'

@description('VM size for both VMs')
param vmSize string = 'Standard_B1s'

@description('Admin username for the VMs')
param adminUsername string = 'azureuser'

@secure()
@description('Admin password for the VMs')
param adminPassword string


resource nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-RDP'
        properties: {
          description: 'description'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName   
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.1.0.0/16'
      ]
    }
    subnets: [
      {
        name: webSubnetName
        properties: {
          addressPrefix: '10.1.1.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
      {
        name: dbSubnetName
        properties: {
          addressPrefix: '10.1.2.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
      {
        name: bastionSubnetName
        properties:{
          addressPrefix: '10.1.3.0/27'
        }
      }  
    
    ]
  }
}

resource networkInterface1 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: webNicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig2'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, webSubnetName) 
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}

resource webvm 'Microsoft.Compute/virtualMachines@2024-11-01' = {
  name: webVmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: webVmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
        name: '${webVmName}-osdisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface1.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      
      }
    }
  }
}

resource networkInterface2 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: dbnicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, dbSubnetName)
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}
resource dbvm 'Microsoft.Compute/virtualMachines@2024-11-01' = {
  name: dbVmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: dbVmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
        name: '${dbVmName}-osdisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface2.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
       }
    }
  }
}

resource bastionIP 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: bastionpip
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: dnsNameLabel
    }
  }
}

resource bastionHost 'Microsoft.Network/bastionHosts@2024-05-01' = {
  name: bastionhost
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'bastion-ipconfig'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, bastionSubnetName)
          }
          publicIPAddress: {
            id: bastionIP.id
          }
        }
      }
    ]
  }
  sku: {
    name: 'Basic'
  }
}
