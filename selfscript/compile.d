module selfscript.compile;

version (Windows) {
    import core.sys.windows.windows;
    import selfscript.windll;
}

import std.stdio;
import std.process;
import f = std.file;
import std.string;

import selfscript.dload;

// general path and extension
private enum buildCache = "buildcache/";
version (Windows) {
    private enum fileExtension = "dll";
} else {
    private enum fileExtension = "so";
}

// windows specific generated files
version (Windows) {
    private enum winDllDefFile = buildCache~"dllSharedGcBody.def";
    private enum winDllFile = buildCache~"dllSharedGcBody.d";
    private enum winBuildFiles = [winDllDefFile,winDllFile];
}

/// Creates the build cache folder
private void prepareBuilddir() 
{
    version (Windows) {
        alias exceptionType = f.WindowsException;
    } else {
        alias exceptionType = f.FileException;
    }
    try {
        f.mkdir(buildCache);
    }   
    catch (exceptionType e) {
        //ignore    
    }
    // on windows, create these two files we need
    version (Windows) {
        f.write(winDllDefFile,winDllDefFileContent);
        f.write(winDllFile,winDllFileContent);
    }
}

//void makeTempfile(in char[] line) {
//   prepareBuilddir();
//    f.write(tempDfile,"\n\n extern(C) export void dllFunc(){\n"~line~"\n}\n");
//}


/** Compiles a file into a Script object. 
*   Parameters:
filename = name of the file to compile
buildDebug = if the script should be build with debug settings 
Return: false on failure.
*/
bool compileScript(string filename, bool buildDebug = true, string[] compilerFlags = [])
{
    import std.path;

    prepareBuilddir();
    // build files
    auto dmdCommandline = ["dmd", filename];
    version (Windows) {
        dmdCommandline ~= winBuildFiles;
    }
    version (Posix) {
        dmdCommandline ~= ["-shared","-defaultlib="];
    }
    // dir and target
    dmdCommandline ~= ["-od"~buildCache, "-of"~buildCache~baseName(filename,".d")~"."~fileExtension];
    // additional flags, likely for libs n shit
    dmdCommandline ~= compilerFlags;
    // build settings 
    if (buildDebug) {
        dmdCommandline ~=  ["-g","-map"];
    } else {
        dmdCommandline ~= ["-O","-release", "-inline"];
    }

    // execute and pray
    if (wait(spawnProcess(dmdCommandline)) != 0) {
        return false;
    }

    return true;
}

/** Evals a string input. 
    includes creating the target file, compiling it, loading it, exectuing it and unloading it.
    Paramter: 
        input = the input to compile
        tmpname = name for the temp. script object
    Return: true on success, false on compiler or loading errors
*/
bool eval(string input, string tmpname="evaltmp", bool buildDebug = true, string[] compilerFlags=[])
{
    prepareBuilddir();
    auto fname = buildCache~tmpname~".d";
    f.write(fname,"\n\n extern(C) export void dllFunc(){\n"~input~"\n}\n");
    if (compileScript(fname,buildDebug,compilerFlags)) {
        auto s = new ScriptObjectDShared(buildCache~tmpname);
        s.execute();
        s.unload();

        return true;
    }

    return false;
}