# Azure Two Tier VM Deployment with Bastion (via Bicep)

## Overview
This project sets up a two-tier network architecture in Microsoft Azure utilizing bicep. It includes a **web tier**, a **database tier**, and a **Bastion host** for secure remote access—without exposing public IPs on the VMs.
**Azure Bastion** is a managed service that allows secure RDP (Remote Desktop Protocol) or SSH (Secure Shell) access to Azure VMs without exposing those VMs to the public internet.
In this project, A Bastion Host is deployed in a special subnet (AzureBastionSubnet) and is assigned a static public IP. VMs are connected to by opening the Azure Portal and using "Connect > Bastion", which:
- Establishes the RDP session over the Azure network, not the internet
- Eliminates the need for public IPs on your VMs
- Helps prevent brute-force attacks or port scanning
Security Advantage: Only the Bastion host has a public-facing IP, and no VM in this setup is directly exposed to the internet.

**Components:**
1. **Virtual Network** with 3 subnets
   - `web-subnet`: Hosts the web-tier VM
   - `db-subnet`: Hosts the database-tier VM
   - `AzureBastionSubnet`: Required for Bastion
2. **Web Tier**(`web-vm`)
   - This virtual machine (VM) represents the frontend or application layer, where users would typically access a website or service.
   - It is placed in its own subnet (`web-subnet`) to be isolated from other services.
3. **Database Tier**(`db-vm)
   - This VM represents the backend or data storage layer, where sensitive data is stored and processed.
   - Deployed in `db-subnet` with the same Network Security Group (NSG), but in a real-world scenario, this would often have stricter security controls (e.g., allow access only from the web tier).
4. **Network Security Group(NSG)**
   - Allows only RDP (port 3389)
5. **Bastion Host**
   - Enables secure RDP access without exposing VMs to the internet

## Deployment & Access

*Ensure Azure CLI is installed, you have a valid Azure subscription, and are logged in via `az login`*

Step 1: Create a resource group (if required)
    ```az group create --name test-rg --location japaneast```

Step 2: Upload the bicep file (if using Azure CLI online)/ensure you are in the correct directory

Step 3: Deploy the bicep template
    ```az deployment group create --name twoTierVMDeployment --resource-group test-rg --template-file web-server.bicep --parameters adminPassord = 'InsertApproriatePassword'```
    *Ensure `adminPassword` meets Azure's complexity standards*

Step 4: Access the VMs
 - Via the Azure Portal, navigate to `web-vm` or `db-vm`
 - Click **Connect > Bastion**
 - Use the credentials provided during deployment to start an RDP session.

## Notes
- The Bastion subnet must be named `AzureBastionSubnet`
- NSG only allows RDP (can be modified as seen fit)
- Both VMs are deployed with the same Windows Server image and VM size (Standard_B1s)

## Conclusion

Clean up resources used to avoid any unexpected charges
``` az group delete --name test-rg --yes --no-wait```
This project demonstrates a secure and modular deployment of a two-tier architecture in Azure using Bicep. By isolating application and database layers in separate subnets and leveraging Azure Bastion for secure VM access, it follows best practices for both security and scalability. This setup serves as a strong foundation for more advanced infrastructure deployments or real-world production scenarios.
