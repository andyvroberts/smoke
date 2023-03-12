using System;
using System.Threading.Tasks;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using Azure.Data.Tables;
using Azure;
using System.Linq;

namespace S0142
{
    using S0142.Common;
    using S0142.Models;
    using S0142.Services;

    public static class ScannerR1
    {
        [FunctionName("S0142-R1-Scanner")]
        public static async Task Scan([TimerTrigger("*/3 * * * *", RunOnStartup = true)] TimerInfo scanTimer,
        [Table("AcquisitionConfig", Constants.ConfigPK, Constants.ConfigFirstReconRK, Connection = "EnergyDataConfigStore")] ConfigTable cd,
        [Table("S0142Files", Connection = "EnergyDataConfigStore")] TableClient filesTab,
        ILogger log)
        {
            log.LogInformation("C# Timer trigger function processed a request.");
            var nextDate = cd.Latest.AddDays(1);

            if (nextDate.Date < DateTime.Now.Date)
            {
                string urlDate = $"{nextDate.Year}-{nextDate.Month:00}-{nextDate.Day:00}";
                log.LogInformation($"Run Date = {urlDate}");

                var fileEntities = await ListFiles.FilesForRunDate(Environment.GetEnvironmentVariable("BmrsApiKey"), urlDate);

                if (fileEntities.Any())
                {
                    foreach (var fileEntity in fileEntities)
                    {
                        if (fileEntity.RowKey == Constants.FirstReconciliation)
                        {
                            Pageable<FileListTable> qRes = filesTab.Query<FileListTable>(filter: $"PartitionKey eq '{fileEntity.PartitionKey}' and RowKey eq '{fileEntity.RowKey}'");

                            if (!qRes.Any())
                            {
                                await Lake.AddToLake(
                                    Environment.GetEnvironmentVariable("BmrsApiKey"),
                                    Environment.GetEnvironmentVariable("EnergyDataLake"),
                                    fileEntity.PartitionKey,
                                    Environment.GetEnvironmentVariable("Container"),
                                    fileEntity.FileName,
                                    log);
                                await filesTab.UpsertEntityAsync(fileEntity);
                            }
                            else
                            {
                                log.LogWarning($"File for {fileEntity.PartitionKey}-{fileEntity.RowKey} already exists in S0142 Files table.");
                                log.LogWarning($"Skipping download for {fileEntity.FileName}");
                            }
                        }
                    }
                }
                else
                {
                    log.LogWarning($"Empty file list for date {urlDate}.");
                }

                cd.Latest = nextDate;
                log.LogInformation($"Updated Binding Date for completion of = {nextDate}");
            }
            else
            {
                log.LogInformation($"No Execution - run date [{nextDate}] is greater than or equal to today [{DateTime.Now.Date}]");
            }
        }
    }
}
