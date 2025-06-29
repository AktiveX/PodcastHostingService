using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace PodcastHostingService.Models
{
    public class PodcastStats
    {
        [JsonPropertyName("podcastId")]
        public string PodcastId { get; set; } = string.Empty;
        
        [JsonPropertyName("totalDownloads")]
        public int TotalDownloads { get; set; } = 0;
        
        [JsonPropertyName("totalEpisodes")]
        public int TotalEpisodes { get; set; } = 0;
        
        [JsonPropertyName("totalStorage")]
        public long TotalStorageBytes { get; set; } = 0;
        
        [JsonPropertyName("totalStorageFormatted")]
        public string TotalStorageFormatted => FormatBytes(TotalStorageBytes);
        
        [JsonPropertyName("episodeStats")]
        public List<EpisodeStat> EpisodeStats { get; set; } = new List<EpisodeStat>();
        
        [JsonPropertyName("downloadsByMonth")]
        public Dictionary<string, int> DownloadsByMonth { get; set; } = new Dictionary<string, int>();
        
        [JsonPropertyName("lastUpdated")]
        public DateTime LastUpdated { get; set; } = DateTime.UtcNow;
        
        private string FormatBytes(long bytes)
        {
            string[] sizes = { "B", "KB", "MB", "GB", "TB" };
            double len = bytes;
            int order = 0;
            
            while (len >= 1024 && order < sizes.Length - 1)
            {
                order++;
                len = len / 1024;
            }
            
            return $"{len:0.##} {sizes[order]}";
        }
    }
    
    public class EpisodeStat
    {
        [JsonPropertyName("episodeId")]
        public string EpisodeId { get; set; } = string.Empty;
        
        [JsonPropertyName("title")]
        public string Title { get; set; } = string.Empty;
        
        [JsonPropertyName("downloads")]
        public int Downloads { get; set; } = 0;
        
        [JsonPropertyName("publishDate")]
        public DateTime PublishDate { get; set; }
    }
}
