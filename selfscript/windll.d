module selfscript.windll;

enum winDllDefFileContent = " 
LIBRARY         MYDLL
DESCRIPTION     'MyDll demonstration DLL'
EXETYPE	        NT
CODE            PRELOAD DISCARDABLE
DATA            PRELOAD MULTIPLE
";

enum winDllFileContent = "
// copied and modified from http://wiki.dlang.org/Win32_DLLs_in_D
module dllmainbody;

import core.runtime;
import core.stdc.stdio;
import core.stdc.stdlib;
import std.string;
import core.sys.windows.windows;

HINSTANCE g_hInst;

extern (C)
{
    void gc_setProxy(void* p);
    void gc_clrProxy();
}

    extern (Windows) BOOL DllMain(HINSTANCE hInstance, ULONG ulReason, LPVOID pvReserved)
    {
        // disable auto fpclose actions. should be taken care of by the parent process
        import std.stdio;
        _fcloseallp = null;
        switch (ulReason)
        {
        case DLL_PROCESS_ATTACH:
        Runtime.initialize();
        break;

        case DLL_PROCESS_DETACH:
        Runtime.terminate();
        break;

        case DLL_THREAD_ATTACH:
        return false;

        case DLL_THREAD_DETACH:
        return false;
        default:
        }
        g_hInst = hInstance;
        return true;
}

    extern (C) {
        export void dllInitialize(void* gc)
    {
        gc_setProxy(gc);
}

    export void dllTerminate()
    {
        gc_clrProxy();
}
}
";