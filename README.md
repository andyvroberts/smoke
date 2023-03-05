# smoke
Acquisition of energy industry balancing and settlement calculation data, into a data lake

# S0142 Data
This dataset is produced at the end of each settlement run and it contains many outputs from the balancing calculations.  The data is available from Elexon via their portal.  You must register and obtain an API key.

## Scan for Files
This is the API to scan for S0142 files names.  
```
https://downloads.elexonportal.co.uk/p114/list?key=<API_KEY>&date=2018-01-17&filter=s0142
```
The date used in the URL filter is that of the balancing and settlement calculations (run), not the energy settlement date.  
The earliest available date of S0142 files seems to be 2018-01-02.

The response from the URL is a JSON-like expression with each file name and its associated settlement date, usually there is one file for each settlement run type (see the list below).  

In order to obtain one of those files, this URL must be used, which allows retrieval of a gzip file.  
```
https://downloads.elexonportal.co.uk/p114/download?key=<API_KEY>&filename=S0142_20171221_SF_20180117121653.gz
```

## Settlement Run Types

| Order | Code | Settlement Type |
|:-------------|:--------------|:-------|
| 1 | II | Interim Initial |
| 2 | SF | Final Initial Settlement |
| 3 | R1 | First Reconciliation |
| 4 | R2 | Second Reconciliation |
| 5 | R3 | Third Reconciliation |
| 6 | RF | Final Reconciliation |
|   | DR | Dispute |
| 7 | DF | Final Dispute |


# Tech Fast Start
Configure an Azure storage account with Hierarchical Namespaces turned on.  This will be the energy data lake.    

## Function App Creation
Create a c# dotnet function app.  
https://learn.microsoft.com/en-us/azure/azure-functions/create-first-function-cli-csharp?tabs=azure-cli%2Cin-process

```
func init S0142 --dotnet
cd S0142
func new --name ScannerR1 --template "HTTP trigger" --authlevel "function"
```

Add the csproj references needed for Azure storage tables  
```
dotnet add package Microsoft.Azure.WebJobs.Extensions.Tables --prerelease  
dotnet add package Microsoft.Azure.WebJobs.Extensions.Storage
```

