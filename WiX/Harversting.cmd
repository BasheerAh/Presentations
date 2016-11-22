CLS
@ECHO OFF
echo .

ECHO Get help to see command line options
Echo "C:\Program Files (x86)\WiX Toolset v3.10\bin\heat.exe" -?
echo .
pause > nul
"C:\Program Files (x86)\WiX Toolset v3.10\bin\heat.exe" -?
echo .
echo .
pause > nul

CLS
echo .
echo .
echo Most important for harvesting files or registry:
echo .
echo .
echo   -ag      autogenerate component guids at compile time
echo   -cg <ComponentGroupName>  component group name (cannot contain spaces e.g -cg MyComponentGroup)
echo   -directoryid  overridden directory id for generated directory elements
echo   -ke      keep empty directories
echo   -nologo  skip printing heat logo information
echo   -out     specify output file (default: write to current directory)
echo
echo   -scom    suppress COM elements
echo   -srd     suppress harvesting the root directory as an element
echo   -sreg    suppress registry harvesting
echo   -suid    suppress unique identifiers for files, components, & directories
echo   -svb6    suppress VB6 COM elements
echo   -t       transform harvested output with XSL file
echo   -v       verbose output
echo   -var <VariableName>  substitute File/@Source="SourceDir" with a preprocessor or a wix variable
echo   (e.g. -var var.MySource will become File/@Source="$(var.MySource)\myfile.txt" and
echo   -var wix.MySource will become File/@Source="!(wix.MySource)\myfile.txt"
pause > nul

CLS
echo Command line to harvest directory and all files inside
echo .
echo .
echo "C:\Program Files (x86)\WiX Toolset v3.10\bin\heat.exe" dir "C:\Program Files\Git\usr\bin" -cg BinaryFiles -ag -dr INSTALLDIR -ke -scom -srd -sreg -svb6 -var var.SourceDir -v -out harvested_files.wxs
pause > nul

"C:\Program Files (x86)\WiX Toolset v3.10\bin\heat.exe" dir "C:\Program Files\Git\usr\bin" -cg BinaryFiles -ag -dr INSTALLDIR -ke -scom -srd -sreg -svb6 -var var.SourceDir -v -out harvested_files.wxs
echo .
echo .
echo DONE. Open harvested_files.wxs
pause > nul

CLS
echo In case if we need meaningful IDs for files - use xslt transforms
echo .
echo .
echo "C:\Program Files (x86)\WiX Toolset v3.10\bin\heat.exe" dir "C:\Program Files\Git\usr\bin" -cg BinaryFiles -ag -dr INSTALLDIR -ke -scom -srd -sreg -svb6 -var var.SourceDir -v -t Transform.xslt -out harvested_files.wxs
pause > nul

"C:\Program Files (x86)\WiX Toolset v3.10\bin\heat.exe" dir "C:\Program Files\Git\usr\bin" -cg BinaryFiles -ag -dr INSTALLDIR -ke -scom -srd -sreg -svb6 -var var.SourceDir -v -t Transform.xslt -out harvested_files.wxs
echo .
echo .
echo DONE. Open harvested_files.wxs
pause > nul

CLS
echo In case if we need meaningful IDs for files - use xslt transforms
echo .
echo .
echo "C:\Program Files (x86)\WiX Toolset v3.10\bin\heat.exe"  reg sample.reg -cg SampleReg -ag -v -out harvested_registry.wxs
pause > nul

"C:\Program Files (x86)\WiX Toolset v3.10\bin\heat.exe"  reg sample.reg -cg SampleReg -ag -v -out harvested_registry.wxs
echo .
echo .
echo DONE. Open harvested_registry.wxs
pause > nul



   
   ::C:\Program Files\Git\bin
::"C:\Program Files\Git\usr\bin"