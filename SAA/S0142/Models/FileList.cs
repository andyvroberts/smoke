using Azure;
using Azure.Data.Tables;

namespace S0142.Models
{
    internal class FileListJson
    {
        public string? FileName { get; set; }
        public string? RunDate { get; set; }
    }

    internal class FileListTable : ITableEntity
    {
        public string? PartitionKey { get; set; }        // Settlement Date
        public string? RowKey { get; set; }              // Settlement Run Type
        public DateTimeOffset? Timestamp { get; set; }
        public ETag ETag { get; set; }
        public string? FileName { get; set; }
        public string? RunDate { get; set; }
    }
}