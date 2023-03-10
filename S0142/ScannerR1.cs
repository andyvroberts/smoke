using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Azure.Data.Tables;
using Azure.Storage.Blobs;
using Newtonsoft.Json;

namespace S0142
{
    using S0142.Common;
    using S0142.Models;
    using S0142.Services;

    public static class ScannerR1
    {
        [FunctionName("S0142-R1-Scanner")]
        public static async Task Scan([TimerTrigger("*/3 * * * *", RunOnStartup = true)] TimerInfo scanTimer,
        [Table("AcquisitionConfig", Constants.ConfigPK, Constants.ConfigFinalReconRK, Connection = "EnergyDataStorage")] ConfigTable cd,
        [Table("S0142Files", Connection = "EnergyDataConfigStore")] TableClient filesTab,
        [Blob("bsc/saa")] BlobContainerClient lakeContainer,
        ILogger log)
        {
            log.LogInformation("C# Timer trigger function processed a request.");
            var nextDate = cd.Latest.AddDays(1);

            if (nextDate.Date < DateTime.Now.Date)
            {
                string urlDate = $"{nextDate.Year}-{nextDate.Month:00}-{nextDate.Day:00}";
                string apiKey = Environment.GetEnvironmentVariable("BmrsApiKey");
                string localFolder = Environment.GetEnvironmentVariable("LocalDownloadFolder");
                log.LogInformation($"Run Date = {urlDate}");

                var fileEntities = await ListFiles.FilesForRunDate(apiKey, urlDate);

                if (fileEntities.Any())
                {
                    foreach (var fileEntity in fileEntities)
                    {
                        if (fileEntity.RowKey == Constants.FinalReconciliation)
                        {
                            await ListFiles.DownloadFileAsync(apiKey, localFolder, fileEntity.FileName, log);
                            await filesTab.UpsertEntityAsync(fileEntity);
                        }
                    }
                }
                else
                {
                    log.LogWarning($"Empty file list for date {urlDate}.");
                }
            }

            cd.Latest = nextDate;
            log.LogInformation($"Updated Binding Date for completion of = {nextDate}");
        }
    }
}
