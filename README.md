# Azure Arc automation Logic Apps

This repository contains multiple Logic Apps aimed to help with management of onboarded Azure Arc machines.

## Scheduled

1. **Ensure Software Assurance benefits are enabled on eligible Windows Server machines** - Azure resource graph query for qualifying machines and enables the benefits
2. **Ensure Software Assurance benefits are enabled on eligble machines with SQL Server installed** - Azure resource graph query for qualifying machines and enables the benefits

## Triggered by Event Grid

1. **Enable Windows Server benefits as soon as machine is onboraded to Azure Arc** - Triggered by Event Grid system topic that subscribes to Resource Graphs events and listens for new Arc machine objects. 

## Deployment

Main Bicep script is `main.bicep` with parameters file `main.bicepparam` that needs to be updated at least with list of Azure subscription IDs where Event Grid should listen to Azure resource manager events. 

### Azure Portal

Deploy the latest version of this directly to Azure interactively

[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fcors.mach.im%2Fhttps%3A%2F%2Fgithub.com%2Fmachv%2Fazure-arc-apps%2Freleases%2Flatest%2Fdownload%2Fmain.json)

> [!TIP]
> Deploy to Azure using this button is also available in the description of each release in _Releases_ section of this repository.

### Azure CLI

Deployment is made at `subscription` level, resource group for Logic apps will be created if needed.

1. Run the deployment command from this folder:

```bash
az deployment sub create --location swedencentral --template-file main.bicep --parameters main.bicepparam
```
