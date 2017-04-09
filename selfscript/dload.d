module selfscript.dload;

version (Windows) {
    import core.sys.windows.windows;
    import selfscript.windll;
}
import core.runtime;
import core.memory;

import std.stdio;
import std.process;
import f = std.file;
import std.algorithm;
import std.string;


// http://wiki.dlang.org/Win32_DLLs_in_D
// https://dlang.org/dll-linux.html


/// Holds a Script object
class ScriptObjectDShared {

    enum UserFunctionName = "dllFunc";

    /// Loads a compiled script object into memory. 
    this(string name) 
    {
        version (Windows) {
            string realName = name~".dll";
        } else {
            string realName = name~".so";
        }

        if(!load(realName)) {
            writeln("Cannot load compiled script '" ~ realName ~ "'!");
        }
    }

    /// Executes a compiled script object after loading
    void execute()
    {
        if(_loaded && !(func is null)) {
            (*func)();
        }
    }

    /// unloads Script Object
    bool unload()
    {
        if (_loaded) {
            version (Windows) {
                _loaded = !Runtime.unloadLibrary(dllHandle);
            }
            version (Posix) {
                dlclose(dllHandle);
                _loaded = false;
            }
        }

        return !_loaded;
    }

protected:

    /// loads the dll. name must be the path to the .dll/.so
    bool load(string name) 
    {
        version(Windows) {
            dllHandle = cast(HMODULE) Runtime.loadLibrary(name);
            if (dllHandle is null) {
                return false;
            }
            _loaded = true;
            dllUserFunction = GetProcAddress(dllHandle, UserFunctionName);
            if (dllUserFunction is null) {
                return false;
            }
            func = cast(UserFunctionType) dllUserFunction;
            return true;
        }
        version (Posix) {
            dllHandle = dlOpen(name,RTLD_LAZY);
            if (dllHandle is null) {
                return false;
            }
            _loaded = true;
            dllUserFunction = cast(UserFunctionType) dlsym(dllHandle,UserFunctionName);
            auto error = dlerror();
            if (error) {
                writef(stderr, "dlysm error: %s\n", error);
                return false;
            }
            func = cast(UserFunctionType) dllUserFunction;
            return true;
        }

        assert(0);
    }

private: 
    extern (C) {
        /// type of the user function in the dll
        alias UserFunctionType = void function();
        /// container for the converted user function
        UserFunctionType func;
    }
    version (Windows) {
        /// handle of the dll
        HMODULE dllHandle;
        /// pointer to the dll function
        FARPROC dllUserFunction;
    } else {
        /// handle of the dll
        void*   dllHandle;
        /// pointer to the dll function
        void*   dllUserFunction;
    }

    /// if the dll is loaded (its not relevant if the symbol was found!)
    bool _loaded = false;
}


