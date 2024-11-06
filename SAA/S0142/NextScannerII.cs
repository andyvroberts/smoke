using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Azure.Data.Tables;
using Azure;

namespace S0142
{
    using S0142.Models;
    using S0142.Common;
    using S0142.Services;

    public class NextScannerII
    {
        [Function("NextScannerII")]
        public static async Task Run(
            [TimerTrigger("0 25,35 4 * * *")] TimerInfo scanTimer,
            FunctionContext context)
        {
            var _logger = context.GetLogger(nameof(NextScannerII));

            var configTab = GetConfigTableClient("AcquisitionConfig");
            var confRow = configTab.GetEntity<ConfigTable>(Constants.ConfigPK, Constants.ConfigInterimInitRK).Value;
            confRow.Latest = confRow.Latest.AddDays(1);

            var nextDate = confRow.Latest;

            if (nextDate.Date < DateTime.Now.Date)
            {
                string urlDate = $"{nextDate.Year}-{nextDate.Month:00}-{nextDate.Day:00}";
                _logger.LogInformation("Run Date = {urlDate}", urlDate);

                var elexonApiKey = Environment.GetEnvironmentVariable("ElexonApiKey");

                if (elexonApiKey != null)
                {
                    var fileEntities = await ListFiles.FilesForRunDate(elexonApiKey, urlDate);

                    if (fileEntities.Any())
                    {
                        foreach (var fileEntity in fileEntities)
                        {
                            if (fileEntity.RowKey == Constants.InterimInitial)
                            {
                                var filesTab = GetConfigTableClient("S0142Files");
                                Pageable<FileListTable> qRes = filesTab.Query<FileListTable>(filter: $"PartitionKey eq '{fileEntity.PartitionKey}' and RowKey eq '{fileEntity.RowKey}'");

                                if (!qRes.Any())
                                {
                                    await Lake.AddToLake(
                                        elexonApiKey,
                                        Environment.GetEnvironmentVariable("EnergyDataLake")!,
                                        fileEntity.PartitionKey!,
                                        Environment.GetEnvironmentVariable("Container")!,
                                        fileEntity.FileName!,
                                        _logger);
                                    await filesTab.UpsertEntityAsync(fileEntity);
                                }
                                else
                                {
                                    _logger.LogWarning("File for {fileEntity.PartitionKey}-{fileEntity.RowKey} already exists in S0142 Files table.", fileEntity.PartitionKey, fileEntity.RowKey);
                                    _logger.LogWarning("Skipping download for {fileEntity.FileName}", fileEntity.FileName);
                                }
                            }
                        }
                    }
                    else
                    {
                        _logger.LogWarning("Empty file list for date {urlDate}.", urlDate);
                    }
                }
                else 
                {
                    _logger.LogError("Elexon API not found in Function App Env Variables.");
                }

                await configTab.UpdateEntityAsync<ConfigTable>(confRow, confRow.ETag);
            }
            else
            {
                _logger.LogWarning("No Execution - run date [{nextDate}] is greater than or equal to [2018-01-01]", nextDate);
            }
        }


        private static TableClient GetConfigTableClient(string tabName)
        {
            var connectionString = Environment.GetEnvironmentVariable("EnergyDataConfigStore");
            return new TableClient(connectionString, tabName);
        }
    }
}
