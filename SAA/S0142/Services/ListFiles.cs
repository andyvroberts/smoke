
namespace S0142.Services
{
    using S0142.Models;
    using S0142.Common;

    internal static class ListFiles
    {
        private static readonly HttpClient client = new HttpClient();

        /// <summary>
        /// The Elexon Portal allows users to obtain a list of available S0142 files for a batch processing day.
        /// The list is in dictionary format {"fileName": "runDate", "fileName": "runDate"}.  This needs to be retrieved 
        /// as a string and decoded into a dictionary as it is not valid Json.
        /// </summary>
        /// <param name="apiKey">the Elexon portal api key</param>
        /// <param name="runDate">the date of the balancing and settlement processing</param>
        /// <returns>A list of Azure table entities, which identifies each File</returns>
        internal static async Task<IEnumerable<FileListTable>> FilesForRunDate(string apiKey, string runDate)
        {
            List<FileListTable> files = [];
            var uri = Constants.DailyFileList.Replace("<KEY>", apiKey);
            uri = uri.Replace("<RUNDATE>", runDate);
            uri = uri.Replace("<FILETYPE>", Constants.ConfigRK.ToLower());

            var fileListResponse = await client.GetStringAsync(uri);

            //if (fileListResponse != null & fileListResponse != "[]")
            if (fileListResponse != null)
            {
                if (fileListResponse != "[]")
                {
                    var noQuotes = fileListResponse.Replace("\"", "");

                    // splitting on the colon ":" will also split the run date time parts
                    // but we can ignore this as they are at the end of the line and we will not use them.
                    if (noQuotes != null)
                    {
                        var filesDict = noQuotes.Trim('{', '}')
                            .Split(',')
                            .Select(s => s.Split(':'))
                            .ToDictionary(d => d[0], d => d[1]);

                        foreach (var f in filesDict)
                        {
                            var fileNameParts = f.Key.Split('_');

                            FileListTable aFile = new()
                            {
                                PartitionKey = fileNameParts[1],
                                RowKey = fileNameParts[2],
                                FileName = f.Key,
                                RunDate = f.Value[..10]
                            };

                            files.Add(aFile);
                        }
                    }
                }
            }

            return files;
        }

    }
}