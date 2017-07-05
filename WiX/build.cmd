CLS

@REM SET CORRECT PATH TO MSBuild 
set msbuild.exe=
for /D %%D in (%SYSTEMROOT%\Microsoft.NET\Framework\v4*) do set msbuild.exe=%%D\MSBuild.exe

if not defined msbuild.exe echo error: can't find MSBuild.exe & goto :eof
if not exist "%msbuild.exe%" echo error: %msbuild.exe%: not found & goto :eof

@REM Simple BUILD 
%msbuild.exe% .\WiXBasics\WiXBasicsSample.sln /t:Rebuild /p:Configuration=Release

%msbuild.exe% .\WixAdvanced\WixAdvanced.sln /t:Rebuild /p:Configuration=Release /p:ProductVersion=4.0.0

:eof