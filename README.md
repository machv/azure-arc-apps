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

| Subscription deployment  | Management Group deployment |
| :---: | :---: |
| This option deploys Logic Apps to selected subscription with RBAC role needed to query Resource Graph would assigned on that subscription. | This option deploys Logic Apps to one subscription and RBAC role needed to query Resource Graph would be assigned at the management group level. |
| [![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fcors.mach.im%2Fhttps%3A%2F%2Fgithub.com%2Fmachv%2Fazure-arc-apps%2Freleases%2Flatest%2Fdownload%2Fmain-sub.json)  | [![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fcors.mach.im%2Fhttps%3A%2F%2Fgithub.com%2Fmachv%2Fazure-arc-apps%2Freleases%2Flatest%2Fdownload%2Fmain-mg.json) |




> [!TIP]
> Deploy to Azure using this button is also available in the description of each release in _Releases_ section of this repository.

### Azure CLI

Deployment can be made at subscription or management group level, resource group for Logic apps will be created if needed.

1. Run the deployment command from this folder:

#### Subscription level 
```bash
az deployment sub create --location swedencentral --template-file main-sub.bicep --parameters main-sub.bicepparam
```

#### Management group level

In this case you need to update `main-mg.bicepparam` with `subscriptionId` parameter where Logic Apps resource group should be created.

```bash
az deployment mg create --location swedencentral --template-file main-mg.bicep --parameters main-mg.bicepparam
```
