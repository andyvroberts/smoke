using Azure;
using Azure.Data.Tables;

namespace S0142.Models
{
    public class ConfigTable : BaseTable
    {
        public int Completed { get; set; }
        public DateTime Latest { get; set; }
    }

    public class BaseTable : ITableEntity
    {
        public string PartitionKey { get; set; }
        public string RowKey { get; set; }
        public DateTimeOffset? Timestamp { get; set; }
        public ETag ETag { get; set; }
    }

}