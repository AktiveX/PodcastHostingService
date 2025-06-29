using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using PodcastHostingService.Services;

var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureServices(services =>
    {
        services.AddSingleton<IBlobStorageService, BlobStorageService>();
        services.AddSingleton<IPodcastService, PodcastService>();
    })
    .Build();

host.Run();
