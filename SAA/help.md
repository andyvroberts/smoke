# Setup and Configure

## Function App
Create the project
```
mkdir SAA  
cd SAA
func init S0142 --worker-runtime dotnet-isolated
```
Add the first function  
```
cd S0142/
func new --template "TimerTrigger" --name ScannerII
```
Add the storage tables and data lake extensions  
```
dotnet add package Microsoft.Azure.Functions.Worker.Extensions.Tables --version 1.3.0
dotnet add package Azure.Storage.Files.DataLake --version 12.19.1
```

## Azure
Changed CLI login method as they no longer support automatic browser redirect.  
```
az login --use-device-code
```







