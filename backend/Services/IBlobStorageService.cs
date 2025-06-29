using System.IO;
using System.Threading.Tasks;

namespace PodcastHostingService.Services
{
    public interface IBlobStorageService
    {
        Task<string> UploadFileAsync(string containerName, string blobName, Stream content, string contentType);
        Task<Stream> DownloadFileAsync(string containerName, string blobName);
        Task DeleteFileAsync(string containerName, string blobName);
        Task<string> GetBlobUrlAsync(string containerName, string blobName);
        Task<bool> BlobExistsAsync(string containerName, string blobName);
        Task CreateContainerIfNotExistsAsync(string containerName);
    }
}
