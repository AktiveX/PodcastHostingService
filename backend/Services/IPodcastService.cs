using System.Collections.Generic;
using System.IO;
using System.Threading.Tasks;
using PodcastHostingService.Models;

namespace PodcastHostingService.Services
{
    public interface IPodcastService
    {
        Task<IEnumerable<Podcast>> GetAllPodcastsAsync(string userId);
        Task<Podcast> GetPodcastByIdAsync(string podcastId, string userId);
        Task<Podcast> CreatePodcastAsync(Podcast podcast, string userId);
        Task<Podcast> UpdatePodcastAsync(Podcast podcast, string userId);
        Task DeletePodcastAsync(string podcastId, string userId);
        
        Task<IEnumerable<Episode>> GetEpisodesAsync(string podcastId, string userId);
        Task<Episode> GetEpisodeByIdAsync(string podcastId, string episodeId, string userId);
        Task<Episode> CreateEpisodeAsync(string podcastId, Episode episode, Stream audioFile, string contentType, string userId);
        Task<Episode> UpdateEpisodeAsync(string podcastId, Episode episode, string userId);
        Task DeleteEpisodeAsync(string podcastId, string episodeId, string userId);
        
        Task<Stream> GetEpisodeAudioAsync(string podcastId, string episodeId, string userId);
        Task<string> GetEpisodeAudioUrlAsync(string podcastId, string episodeId, string userId);
        
        Task<PodcastStats> GetPodcastStatsAsync(string podcastId, string userId);
    }
}
