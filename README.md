# servicebus-functionapp

## getting started

```bash
az group create -n innerloop -l northeurope
az deployment group create -f .\bicep\main.bicep -g innerloop
```