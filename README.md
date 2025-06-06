# Smoke
Acquisition of energy industry balancing and settlement calculation data, into a data lake

[![Deploy S0142 Data Retrieval Func App](https://github.com/andyvroberts/smoke/actions/workflows/build-deploy-004.yml/badge.svg)](https://github.com/andyvroberts/smoke/actions/workflows/build-deploy-004.yml)

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

| Month | Data Lake (Tot size) | Function App | Total |
|:-------------|:--------------|:-------|:------------|
|2025-05 | (71gb / 10,600 files) £1.69 | £0 | £1.69 |
|2024-12 | (61gb / 9,200 files) £1.12 | £0.91 | £2.03 |
|2024-08 | (51gb / 7,390 files) £0.94 | £0.30 | £1.24 |
|2024-07 | (47gb / 6,700 files) £0.88 | £0.17 | £1.05 |
|2024-04 | (43gb / 6,100 files) £0.82 | £0.18 | £1.00 |
|2024-02 | (40gb / 5,800 files) £0.76 | £0.17 | £0.93 |
| 2024-01 | (39gb / 5,630 files) £0.73 | £0.18 | £0.91 |
| 2023-12 | (38gb / 5,310 files) £0.71 | £0.19 | £0.90 |
| 2023-11 | (36gb / 5,190 files) £0.71 | £0.19 | £0.90 |
| 2023-10 | (34gb / 4,920 files) £0.66 | £0.19 | £0.86 |
| 2023-09 | (32gb / 4,680 files) £0.60 | £0.18 | £0.78 |
| 2023-08 | (30gb / 4,400 files) £0.56 | £0.18 | £0.74 |
| 2023-07 | (28gb / 4,150 files) £0.53 | £0.16 | £0.69 |
| 2023-06 | (27gb / 3,990 files) £0.52 | £0.15 | £0.67 |
| 2023-05 | (25gb / 3,800 files) £0.51 | £0.15 | £0.66 |
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


