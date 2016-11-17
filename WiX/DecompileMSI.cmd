CLS
@ECHO OFF
echo .

ECHO Get help to see command line options
Echo "C:\Program Files (x86)\WiX Toolset v3.10\bin\dark.exe" -?
echo .
pause > nul
"C:\Program Files (x86)\WiX Toolset v3.10\bin\dark.exe" -?
echo .
echo .
pause > nul
 
echo   -nologo    skip printing dark logo information
echo   -o[ut]     specify output file (default: write .wxs to current directory)
echo   -sct       suppress decompiling custom tables
echo   -sras      suppress relative action sequencing 
echo                (use explicit sequence numbers)
echo   -sui       suppress decompiling UI-related tables
echo   -v         verbose output
echo   "-x <path>  export binaries from cabinets and embedded binaries to <path>"

echo .
echo .
pause > nul



Set MSI=".\WixBasics\WiXBasicsSample\bin\Release\AwesomeSoftware.msi"

echo "C:\Program Files (x86)\WiX Toolset v3.10\bin\dark.exe" %MSI% -nologo -v -sct -sui -x temp -out "AwesomeSoftware.wxs"
"C:\Program Files (x86)\WiX Toolset v3.10\bin\dark.exe" %MSI% -nologo -v -sct -sui -x temp -out "AwesomeSoftware.wxs"
echo .
echo .
pause > nul

REM For compiling back
REM 
REM & "C:\Program Files (x86)\WiX Toolset v3.10\bin\candle.exe"  .\AwesomeSoftware.wxs
REM & "C:\Program Files (x86)\WiX Toolset v3.10\bin\light.exe" .\AwesomeSoftware.wixobj
REM Need to add extension to compile UI
REM & "C:\Program Files (x86)\WiX Toolset v3.10\bin\light.exe" .\AwesomeSoftware.wixobj -ext "C:\Program Files (x86)\WiX Toolset v3.10\bin\WixUIExtension.dll"
REM 




