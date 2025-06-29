using System.Net;
using System.Threading.Tasks;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using PodcastHostingService.Models;
using PodcastHostingService.Services;

namespace PodcastHostingService
{
    public class PodcastFunctions
    {
        private readonly IPodcastService _podcastService;
        private readonly IBlobStorageService _blobStorageService;
        private readonly ILogger _logger;

        public PodcastFunctions(IPodcastService podcastService, IBlobStorageService blobStorageService, ILoggerFactory loggerFactory)
        {
            _podcastService = podcastService;
            _blobStorageService = blobStorageService;
            _logger = loggerFactory.CreateLogger<PodcastFunctions>();
        }

        [Function("CreatePodcast")]
        public async Task<HttpResponseData> CreatePodcast(
            [HttpTrigger(AuthorizationLevel.Function, "post", Route = "podcasts")] HttpRequestData req)
        {
            _logger.LogInformation("Processing CreatePodcast request.");

            var podcast = await req.ReadFromJsonAsync<Podcast>();
            if (podcast == null)
            {
                var badResponse = req.CreateResponse(HttpStatusCode.BadRequest);
                await badResponse.WriteStringAsync("Invalid podcast data.");
                return badResponse;
            }

            var createdPodcast = await _podcastService.CreatePodcastAsync(podcast);
            var response = req.CreateResponse(HttpStatusCode.Created);
            await response.WriteAsJsonAsync(createdPodcast);
            return response;
        }

        [Function("GetPodcast")]
        public async Task<HttpResponseData> GetPodcast(
            [HttpTrigger(AuthorizationLevel.Function, "get", Route = "podcasts/{id}")] HttpRequestData req, string id)
        {
            _logger.LogInformation($"Fetching podcast with id: {id}");

            var podcast = await _podcastService.GetPodcastAsync(id);
            if (podcast == null)
            {
                var notFoundResponse = req.CreateResponse(HttpStatusCode.NotFound);
                await notFoundResponse.WriteStringAsync("Podcast not found.");
                return notFoundResponse;
            }

            var response = req.CreateResponse(HttpStatusCode.OK);
            await response.WriteAsJsonAsync(podcast);
            return response;
        }

        [Function("CreateEpisode")]
        public async Task<HttpResponseData> CreateEpisode(
            [HttpTrigger(AuthorizationLevel.Function, "post", Route = "podcasts/{podcastId}/episodes")] HttpRequestData req,
            string podcastId)
        {
            _logger.LogInformation($"Processing CreateEpisode request for podcast id: {podcastId}.");

            var episode = await req.ReadFromJsonAsync<Episode>();
            if (episode == null)
            {
                var badResponse = req.CreateResponse(HttpStatusCode.BadRequest);
                await badResponse.WriteStringAsync("Invalid episode data.");
                return badResponse;
            }

            var createdEpisode = await _podcastService.CreateEpisodeAsync(podcastId, episode);
            var response = req.CreateResponse(HttpStatusCode.Created);
            await response.WriteAsJsonAsync(createdEpisode);
            return response;
        }

        [Function("GetEpisode")]
        public async Task<HttpResponseData> GetEpisode(
            [HttpTrigger(AuthorizationLevel.Function, "get", Route = "podcasts/{podcastId}/episodes/{episodeId}")] HttpRequestData req,
            string podcastId, string episodeId)
        {
            _logger.LogInformation($"Fetching episode {episodeId} for podcast id: {podcastId}");

            var episode = await _podcastService.GetEpisodeAsync(podcastId, episodeId);
            if (episode == null)
            {
                var notFoundResponse = req.CreateResponse(HttpStatusCode.NotFound);
                await notFoundResponse.WriteStringAsync("Episode not found.");
                return notFoundResponse;
            }

            var response = req.CreateResponse(HttpStatusCode.OK);
            await response.WriteAsJsonAsync(episode);
            return response;
        }

        [Function("UpdatePodcast")]
        public async Task<HttpResponseData> UpdatePodcast(
            [HttpTrigger(AuthorizationLevel.Function, "put", Route = "podcasts/{id}")] HttpRequestData req, string id)
        {
            _logger.LogInformation($"Updating podcast with id: {id}");

            var podcast = await req.ReadFromJsonAsync<Podcast>();
            if (podcast == null)
            {
                var badResponse = req.CreateResponse(HttpStatusCode.BadRequest);
                await badResponse.WriteStringAsync("Invalid podcast data.");
                return badResponse;
            }

            var updatedPodcast = await _podcastService.UpdatePodcastAsync(id, podcast);
            var response = req.CreateResponse(HttpStatusCode.OK);
            await response.WriteAsJsonAsync(updatedPodcast);
            return response;
        }

        [Function("DeletePodcast")]
        public async Task<HttpResponseData> DeletePodcast(
            [HttpTrigger(AuthorizationLevel.Function, "delete", Route = "podcasts/{id}")] HttpRequestData req, string id)
        {
            _logger.LogInformation($"Deleting podcast with id: {id}");

            await _podcastService.DeletePodcastAsync(id);
            var response = req.CreateResponse(HttpStatusCode.NoContent);
            return response;
        }

        [Function("UpdateEpisode")]
        public async Task<HttpResponseData> UpdateEpisode(
            [HttpTrigger(AuthorizationLevel.Function, "put", Route = "podcasts/{podcastId}/episodes/{episodeId}")] HttpRequestData req,
            string podcastId, string episodeId)
        {
            _logger.LogInformation($"Updating episode {episodeId} for podcast id: {podcastId}");

            var episode = await req.ReadFromJsonAsync<Episode>();
            if (episode == null)
            {
                var badResponse = req.CreateResponse(HttpStatusCode.BadRequest);
                await badResponse.WriteStringAsync("Invalid episode data.");
                return badResponse;
            }

            var updatedEpisode = await _podcastService.UpdateEpisodeAsync(podcastId, episodeId, episode);
            var response = req.CreateResponse(HttpStatusCode.OK);
            await response.WriteAsJsonAsync(updatedEpisode);
            return response;
        }

        [Function("DeleteEpisode")]
        public async Task<HttpResponseData> DeleteEpisode(
            [HttpTrigger(AuthorizationLevel.Function, "delete", Route = "podcasts/{podcastId}/episodes/{episodeId}")] HttpRequestData req,
            string podcastId, string episodeId)
        {
            _logger.LogInformation($"Deleting episode {episodeId} for podcast id: {podcastId}");

            await _podcastService.DeleteEpisodeAsync(podcastId, episodeId);
            var response = req.CreateResponse(HttpStatusCode.NoContent);
            return response;
        }
    }
}
