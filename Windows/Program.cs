using System;
using System.Threading;
using System.Windows.Forms;

namespace PCNoShitaNoChikaramochi;

internal static class Program
{
    private static Mutex? _singleInstanceMutex;

    [STAThread]
    static void Main()
    {
        // 多重起動防止
        _singleInstanceMutex = new Mutex(true, "PCNoShitaNoChikaramochi_SingleInstanceMutex", out var createdNew);
        if (!createdNew)
        {
            return;
        }

        ApplicationConfiguration.Initialize();
        Application.Run(new TrayAppContext());

        GC.KeepAlive(_singleInstanceMutex);
    }
}
