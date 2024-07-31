using Microsoft.Extensions.Logging;
using Azure.Storage.Files.DataLake;

namespace S0142.Services
{
    using S0142.Common;

    internal static class Lake
    {
        private static readonly HttpClient client = new();

        /// <summary>
        /// Construct the URL for the Elexon Portal and make the HTTP request.
        /// Create a file stream to download the gzip source object into the data lake
        /// </summary>
        internal static async Task AddToLake(
            string apiKey, 
            string lakeConnString, 
            string settDate, 
            string lakeContainer,
            string fileName, 
            ILogger log)
        {
            var uri = Constants.DownloadFile.Replace("<KEY>", apiKey);
            uri = uri.Replace("<FILE>", fileName);

            // 20090823
            var year = settDate[..4];
            var month = settDate.Substring(4, 2);
            var lakeFileSystem = $"/saa/{year}/{month}";

            try
            {
                DataLakeServiceClient svcClient = new DataLakeServiceClient(lakeConnString);

                DataLakeFileSystemClient fsClient = svcClient.GetFileSystemClient(lakeContainer);

                DataLakeDirectoryClient dirClient = fsClient.GetDirectoryClient(lakeFileSystem);

                //await fsClient.CreateIfNotExistsAsync();
                DataLakeFileClient fileClient = dirClient.GetFileClient(fileName);

                var downloadFile = await client.GetAsync(uri);

                if (downloadFile != null)
                {
                    var outStream = await downloadFile.Content.ReadAsStreamAsync();
                    await fileClient.UploadAsync(outStream, true);

                    log.LogInformation($"Lake File Created = {fileClient.Uri}");
                }
                else
                {
                    log.LogWarning($"NO FILE: {fileName}");
                }
            }
            catch (Exception e)
            {
                log.LogError($"DataLake Client for [File = {fileName}] - [SettDate = {settDate}] had ERROR: {e.Message}");
                throw;
            }
        }

    }
}