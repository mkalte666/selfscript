module selfscript.ext.selfhost;

public import selfscript.compile;

template GenSelfhostingMain()
{
    const char[] GenSelfhostingMain = "
    void main()
    {
        for(;;) {
            string file;
            foreach (line; stdin.byLine(KeepTerminator.yes)) {
                if (line == \"\n\") {
                    break;
                }
                file ~= line;    
            }

            eval(file);
        }
    }";
}