module dllmain;

import std.c.windows.windows;
import core.sys.windows.dll;
import thBase.plugin;

__gshared HINSTANCE g_hInst;

extern (Windows)
BOOL DllMain(HINSTANCE hInstance, ULONG ulReason, LPVOID pvReserved)
{
    final switch (ulReason)
    {
	case DLL_PROCESS_ATTACH:
	    g_hInst = hInstance;
	    dll_fixTLS( hInstance );
	    break;

	case DLL_PROCESS_DETACH:
	    dll_process_detach( hInstance, true );
	    break;

	case DLL_THREAD_ATTACH:
	    dll_thread_attach( true, true );
	    break;

	case DLL_THREAD_DETACH:
	    dll_thread_detach( true, true );
	    break;
    }
    return true;
}

extern(C) export void InitPlugin(IPluginRegistry registry)
{
  g_pluginRegistry = registry;
}

