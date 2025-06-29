using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace PodcastHostingService.Models
{
    public class Podcast
    {
        [JsonPropertyName("id")]
        public string Id { get; set; } = Guid.NewGuid().ToString();
        
        [JsonPropertyName("title")]
        public string Title { get; set; } = string.Empty;
        
        [JsonPropertyName("description")]
        public string Description { get; set; } = string.Empty;
        
        [JsonPropertyName("author")]
        public string Author { get; set; } = string.Empty;
        
        [JsonPropertyName("email")]
        public string Email { get; set; } = string.Empty;
        
        [JsonPropertyName("imageUrl")]
        public string ImageUrl { get; set; } = string.Empty;
        
        [JsonPropertyName("categories")]
        public List<string> Categories { get; set; } = new List<string>();
        
        [JsonPropertyName("websiteUrl")]
        public string WebsiteUrl { get; set; } = string.Empty;
        
        [JsonPropertyName("language")]
        public string Language { get; set; } = "en-us";
        
        [JsonPropertyName("explicit")]
        public bool Explicit { get; set; } = false;
        
        [JsonPropertyName("ownerId")]
        public string OwnerId { get; set; } = string.Empty;
        
        [JsonPropertyName("createdAt")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        [JsonPropertyName("updatedAt")]
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
        
        [JsonPropertyName("rssUrl")]
        public string RssUrl { get; set; } = string.Empty;
    }
}
