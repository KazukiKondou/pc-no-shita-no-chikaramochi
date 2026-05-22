using System;
using System.Runtime.InteropServices;

namespace PCNoShitaNoChikaramochi;

/// <summary>
/// GlobalMemoryStatusEx でメモリ使用率を取得する。Win32 API 直叩きなので追加 NuGet 不要。
/// </summary>
public class MemoryMonitor
{
    public double UsagePercent { get; private set; }
    public ulong UsedBytes { get; private set; }
    public ulong TotalBytes { get; private set; }

    public void Sample()
    {
        var status = new MEMORYSTATUSEX { dwLength = (uint)Marshal.SizeOf<MEMORYSTATUSEX>() };
        if (!GlobalMemoryStatusEx(ref status))
        {
            return;
        }

        UsagePercent = status.dwMemoryLoad;
        TotalBytes = status.ullTotalPhys;
        UsedBytes = status.ullTotalPhys - status.ullAvailPhys;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
    private struct MEMORYSTATUSEX
    {
        public uint dwLength;
        public uint dwMemoryLoad;
        public ulong ullTotalPhys;
        public ulong ullAvailPhys;
        public ulong ullTotalPageFile;
        public ulong ullAvailPageFile;
        public ulong ullTotalVirtual;
        public ulong ullAvailVirtual;
        public ulong ullAvailExtendedVirtual;
    }

    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool GlobalMemoryStatusEx(ref MEMORYSTATUSEX lpBuffer);
}
