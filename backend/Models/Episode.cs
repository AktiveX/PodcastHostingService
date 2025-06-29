using System;
using System.Text.Json.Serialization;

namespace PodcastHostingService.Models
{
    public class Episode
    {
        [JsonPropertyName("id")]
        public string Id { get; set; } = Guid.NewGuid().ToString();
        
        [JsonPropertyName("podcastId")]
        public string PodcastId { get; set; } = string.Empty;
        
        [JsonPropertyName("title")]
        public string Title { get; set; } = string.Empty;
        
        [JsonPropertyName("description")]
        public string Description { get; set; } = string.Empty;
        
        [JsonPropertyName("audioUrl")]
        public string AudioUrl { get; set; } = string.Empty;
        
        [JsonPropertyName("audioFileName")]
        public string AudioFileName { get; set; } = string.Empty;
        
        [JsonPropertyName("duration")]
        public TimeSpan Duration { get; set; } = TimeSpan.Zero;
        
        [JsonPropertyName("fileSize")]
        public long FileSize { get; set; } = 0;
        
        [JsonPropertyName("mimeType")]
        public string MimeType { get; set; } = "audio/mpeg";
        
        [JsonPropertyName("season")]
        public int? Season { get; set; }
        
        [JsonPropertyName("episode")]
        public int? EpisodeNumber { get; set; }
        
        [JsonPropertyName("publishDate")]
        public DateTime PublishDate { get; set; } = DateTime.UtcNow;
        
        [JsonPropertyName("createdAt")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        [JsonPropertyName("updatedAt")]
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
        
        [JsonPropertyName("explicit")]
        public bool Explicit { get; set; } = false;
        
        [JsonPropertyName("imageUrl")]
        public string ImageUrl { get; set; } = string.Empty;
        
        [JsonPropertyName("downloadCount")]
        public int DownloadCount { get; set; } = 0;
    }
}
