using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using System.IO;
using Microsoft.Extensions.Logging;
using Azure.Storage.Files.DataLake;
using S0142.Common;

namespace S0142.Services
{
    internal static class Lake
    {
        private static readonly HttpClient client = new HttpClient();

        /// <summary>
        /// Construct the URL for the Elexon Portal and make the HTTP request.
        /// Create a file stream to download the gzip source object into the data lake
        /// </summary>
        /// <param name="apiKey">the Elexon Portal api Key</param>
        /// <param name="folder">the local disk folder which is the target of the file stream</param>
        /// <param name="fileName">the download file name</param>
        /// <param name="log">used to log warnings if file URL is not found</param>
        /// <returns></returns>
        internal static async Task AddToLake(string apiKey, string lakeConnString, string settDate, string lakeContainer, string fileName,
            ILogger log)
        {
            var uri = Constants.DownloadFile.Replace("<KEY>", apiKey);
            uri = uri.Replace("<FILE>", fileName);

            // 20090823
            var year = settDate.Substring(0, 4);
            var month = settDate.Substring(4, 2);
            var lakeFileSystem = $"/{year}/{month}";

            // 
            try
            {
                DataLakeServiceClient svcClient = new DataLakeServiceClient(lakeConnString);

                DataLakeFileSystemClient fsClient = svcClient.GetFileSystemClient(lakeContainer);
                log.LogInformation($"Lake Container = {fsClient.Uri}");

                DataLakeDirectoryClient dirClient = fsClient.GetDirectoryClient(lakeFileSystem);
                log.LogInformation($"Lake File System = {dirClient.Uri}");

                await fsClient.CreateIfNotExistsAsync();

                DataLakeFileClient fileclient = dirClient.GetFileClient(fileName);

                var downloadFile = await client.GetAsync(uri);

                if (downloadFile != null)
                {
                    // using (var outStream = new FileStream(
                    //     downloadPath, FileMode.Create, FileAccess.Write))
                    // {
                    //     await downloadFile.Content.CopyToAsync(outStream);
                    // };

                    var outStream = await downloadFile.Content.ReadAsStreamAsync();
                    await fileclient.UploadAsync(outStream);

                    log.LogInformation($"{fileName}");
                }
                else
                {
                    log.LogWarning($"NO FILE: {fileName}");
                }
            }
            catch (Exception e)
            {
                log.LogError($"DataLake Client ERROR - {e.Message}");
            }
        }

    }
}