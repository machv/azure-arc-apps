# Logic App - Arc trigger deployment

## How to deploy with Azure CLI
1. Ensure you are logged in and the resource group exists (name: `arc`).
2. Run the deployment command from this folder:

```bash
az deployment group create --resource-group arc  --template-file logicapp-arc-monitoring.bicep
```
