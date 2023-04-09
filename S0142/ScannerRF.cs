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

    public static class ScannerRF
    {
        [FunctionName("S0142-RF-Scanner")]
        public static async Task ScanRF([TimerTrigger("50 1,4 * * *")] TimerInfo scanTimer,
        [Table("AcquisitionConfig", Constants.ConfigPK, Constants.ConfigFinalReconRK, Connection = "EnergyDataConfigStore")] ConfigTable cd,
        [Table("S0142Files", Connection = "EnergyDataConfigStore")] TableClient filesTab,
        ILogger log)
        {
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
                        if (fileEntity.RowKey == Constants.FinalReconciliation)
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
            }
            else
            {
                log.LogWarning($"No Execution - run date [{nextDate}] is greater than or equal to today [{DateTime.Now.Date}]");
            }
        }
    }
}
