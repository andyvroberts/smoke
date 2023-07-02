# Smoke
Acquisition of energy industry balancing and settlement calculation data, into a data lake

![Build Status](https://github.com/avroberts-azure/smoke/actions/workflows/build-deploy.yml/badge.svg)

# S0142 Data
This dataset is produced by a BSC (Balancing & Settlement Code) system called the SAA (Settlement Administration Agent) at the end of each settlement run and it contains inputs and outputs for Central Settlement calculations.  The data is available from Elexon via their portal.  You must register and obtain an API key.

## Scan for Files
This is the API to scan for S0142 files names.  
```
https://downloads.elexonportal.co.uk/p114/list?key=<API_KEY>&date=2018-01-17&filter=s0142
```
The date used in the URL filter is that of the balancing and settlement calculations calculation (run), not the energy Settlement Date.  

The response from the URL is a JSON-like expression with each file name and its associated settlement date, usually there is one file for each settlement run type (see the list below).  

In order to obtain one of those files, this URL must be used, which allows retrieval of each individual file.  
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

<br>

## Montly Costs Tracker

| Month | Data Lake (Accumulated) | Function App | Total |
|:-------------|:--------------|:-------|:------------|
| 2023-06 | (27gb / 3,990 files) £0.52 | £0.15 | £0.68 |
| 2023-05 | (25gb / 3,800 files) £0.51 | £0.15 | £0.67 |
| 2023-04 | (24gb / 3,700 files) £0.49 | £0.27 | £0.76 |
| 2023-03 | (21gb / 3,200 files) £0.26 | n/a  | £0.26 |

<br>

# Design
## Acquisition Process
Create an Azure function that runs on a timer (once per day) which will scan for only one of the settlement run types.  Duplicate the scanner for each of the run types required.  

Considerations for duplicate functions:  
- Function time-out of 5 minutes
- SAA executions are not daily.  Some days will produce multiple back-dated files

## Data Lake Partitions
The data lake is created in an Azure storage account with the Hierarchical Namespace option.  This mimics an HDFS-like file system with navigable folders where varying permissions and access policies can be applied.  
Create a hierarchy structure with these components:  
```
<Container>/<File System>/<Files>
```
Where:
1. Container = 'bsc'
2. File system organised by data source and month = /saa/year/month
3. Files are the original (unaltered) downloaded files from Elexon

<br>

# Tech Start
Configure an Azure storage account with Hierarchical Namespaces and a minimum durability/availability of ZRS. 

## Function App Creation
Create a c# dotnet function app.  
https://learn.microsoft.com/en-us/azure/azure-functions/create-first-function-cli-csharp?tabs=azure-cli%2Cin-process

```
func init S0142 --dotnet
cd S0142
func new --name ScannerR1 --template "timer trigger" --authlevel "function"
```

Add the csproj references needed for Azure storage types  
```
dotnet add package Microsoft.Azure.WebJobs.Extensions.Tables --prerelease  
dotnet add package Microsoft.Azure.WebJobs.Extensions.Storage
dotnet add package Azure.Storage.Files.DataLake
```

To restrict locally running functions during testing, add this clause to the "host.json" file to include only those functions you wish to execute:  
```
{
    "functions": [ "funcname1", "funcname2" ]
}
```
