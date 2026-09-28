using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using GrpcLibrary;
using PhotoColumnApp.Services;
using PhotoColumnApp.Helpers;
using CommunityToolkit.Maui.Core;

namespace PhotoColumnApp.ViewModels;

public partial class MonitoringViewModel : ObservableObject
{
    private readonly IDataService dataService;

    public MonitoringViewModel(IDataService dataService)
    {
        this.dataService = dataService;

        statusItems = new ObservableCollection<Item>();
    }

    [ObservableProperty]
    private ObservableCollection<Item> statusItems;

    [ObservableProperty]
    private string cpu;

    [ObservableProperty]
    private string memory;

    [ObservableProperty]
    private string cpu_count;

    [ObservableProperty]
    private string net_if_addrs;

    [ObservableProperty]
    private string net_io_counters;

    [ObservableProperty]
    private string boot_time;

    [RelayCommand]
    async Task GetKioskStatus()
    {
        this.StatusItems.Clear();
        await foreach (var message in dataService.GetKioskStatus())
        {
            this.StatusItems.Add(new Item
            {
                Description = message.Item1,
                Status = message.Item2 == "OK" ? FontAwesomeIcons.SquareCheck : FontAwesomeIcons.RectangleXmark,
                Color = message.Item2 == "OK" ? Colors.Green : Colors.Red
            });

            Console.WriteLine($"Received kiosk item: {message.Item1} {message.Item2}");
        }
    }

    [RelayCommand]
    async Task GetMonitoringUsages()
    {
        {
            try
            {
                await foreach (var message in dataService.OdroidUsage())
                {
                    if(Shell.Current.CurrentPage.Title != "Monitoring") {
                        break;
                    }

                    if (message.usageType == UsageType.Cpu)
                    {
                        Console.WriteLine($"Result from usage: CPU");
                        this.Cpu = $"CPU: {message.usage} %";
                    }

                    if (message.usageType == UsageType.Memory)
                    {
                        Console.WriteLine($"Result from usage: MEM");
                        this.Memory = $"Memory: {message.usage} %";

                    }

                    if (message.usageType == UsageType.CpuCount)
                    {
                        Console.WriteLine($"Result from usage: Cpu_count");
                        this.Cpu_count = $"CPU count: {message.usage}";
                    }

                    //if (message.usageType == UsageType.NetIfAddrs)
                    //{
                    //    Console.WriteLine($"Result from usage: Net_if_addrs");
                    //    this.Net_if_addrs = $"NW address: {message.usage}";
                    //}

                    if (message.usageType == UsageType.NetIoCounters)
                    {
                        Console.WriteLine($"Result from usage: Net_io_counters");
                        this.Net_io_counters = $"Bytes Received: {message.usage}";
                    }

                    if (message.usageType == UsageType.BootTime)
                    {
                        Console.WriteLine($"Result from usage: Boot_time");
                        this.Boot_time = $"Boot time: {message.usage}";
                    }
                }
            }
            catch (Grpc.Core.RpcException e)
            {
                Console.WriteLine($"Odroid Usage server error {e.Message}");
                ToastMessage.Show($"Odroid Usage server error {e.Message}", 18, ToastDuration.Long, null);
            }
        }
    }
}

public class Item
{
    public string Description { get; set; }
    public string Status { get; set; }
    public Color Color { get; set; }
}

