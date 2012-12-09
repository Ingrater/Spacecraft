module dllmain;

import core.stdc.stdio;

import base.all;
import std.c.windows.windows;
import core.sys.windows.dll;
import core.runtime;
import thBase.plugin;
import thBase.asserthandler;

__gshared HINSTANCE g_hInst;
__gshared bool g_isPluginInititalized = false;

extern (Windows)
BOOL DllMain(HINSTANCE hInstance, ULONG ulReason, LPVOID pvReserved)
{
    final switch (ulReason)
    {
	case DLL_PROCESS_ATTACH:
      printf("DLL_PROCESS_ATTACH\n");
	    g_hInst = hInstance;
	    dll_fixTLS( hInstance );
	    break;

	case DLL_PROCESS_DETACH:
      printf("DLL_PROCESS_DETACH\n");
	    break;

	case DLL_THREAD_ATTACH:
      printf("DLL_THREAD_ATTACH\n");
      if(g_isPluginInititalized)
	      dll_thread_attach( true, true );
	    break;

	case DLL_THREAD_DETACH:
      printf("DLL_THREAD_DETACH\n");
      if(g_isPluginInititalized)
	      dll_thread_detach( true, true );
	    break;
    }
    return true;
}

extern(C) export bool InitPlugin(IPluginRegistry registry)
{
  printf("InitPlugin\n");
  g_pluginRegistry = registry;
  thBase.asserthandler.Init();
  InitPluginSystem();
  Runtime.initialize();
  g_isPluginInititalized = true;
  return dll_attachAllThreads();
}

extern(C) export void DeinitPlugin()
{
  dll_process_detach( g_hInst, true );
  g_isPluginInititalized = false;
  DeinitPluginSystem();
}

extern(C) export IPlugin GetPlugin()
{
  printf("GetPlugin\n");
  return g_Env.physicsPlugin;
}

