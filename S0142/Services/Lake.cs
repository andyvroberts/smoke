using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using System.IO;
using Microsoft.Extensions.Logging;

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
        internal static async Task DownloadFileAsync(string apiKey, string folder, string fileName, ILogger log)
        {
            var uri = Constants.DownloadFile.Replace("<KEY>", apiKey);
            uri = uri.Replace("<FILE>", fileName);

            var basePath = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
            string downloadPath = Path.Combine(basePath, folder, fileName);

            var downloadFile = await client.GetAsync(uri);

            if (downloadFile != null)
            {
                using (var outStream = new FileStream(
                    downloadPath, FileMode.Create, FileAccess.Write))
                {
                    await downloadFile.Content.CopyToAsync(outStream);
                };

                log.LogInformation($"{fileName}");
            }
            else
            {
                log.LogWarning($"NO FILE: {fileName}");
            }
        }

    }
}