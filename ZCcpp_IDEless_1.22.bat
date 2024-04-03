:: ####################################################################################
:: Flyandance C/C++ Compile and Run Batch Program 1.22
:: To Compile: A compiler toolchain is required; It includes compiler and STD library
::                                             © 2024 Flyandance - All right reserved
:: ####################################################################################
@echo OFF 
:: ************************************************************************************
:: ====================================================================================
::                    Flyandance IDE-less batch program configurations:  
:: ====================================================================================
:: ####################################################################################
:: Define Path -- Compiler toolchain bin folder location(space supported)
:: ####################################################################################
set "Compiler_Path=C:\AppSource\mingw64_x86_64-13.2.0-release-win32-seh-msvcrt-rt_v11-rev1\bin\"

::#####################################################################################
:: ###-More Compile Option: -v -fno-jump-tables -w -Wall -Wno-uninitialized -Wno-unused-value 
:: -std=<std>     standard:c90,c99,c11,c17,gnu90,gnu99,gnu11,gnu17
:: -x lang        Specify source language:c,c++,assembler-with-cpp
set "CompileOptions= -Wall "

:: -I "dir-include-path"  || Directory Search: -iquote dir -isystem dir -idirafter dir
set "IncludePath= "

:: ###-More Linkage Option: -nostartfiles || -l LIBNAME  ||  -L "dir-library-path"
:: -static -static-libgcc -static-libstdc++ -static-libgcc -lstdc++
set "LinkOptions= " 

::**************************************************************************************
:: yes or no -- FOR ##compiling## .s source files 
set "compileAssembly=yes"
:: yes or no -- FOR ##linking## external .o object files 
set "linkEXTobject=yes"

::**************************************************************************************

:: yes or no -- delete compiled object files in Output
set "deleteOBJ=yes"

:: yes or no -- FOR creating a LSS file
set "createLSSfile=no"

::======================================================================================
:: Other stage options passing via GCC frontend
:: -Wp,<options>  Pass comma-separated <options> to preprocessor.
:: -Wa,<options>  Pass comma-separated <options> to assembler.
:: -Wl,<options>  Pass comma-separated <options> to linker.
::======================================================================================
:: echo %CompileOptions%
:: echo %IncludePath%
::####################################################################################


::####################################################################################
::  C/C++ Compiler Starts here
::####################################################################################


:BEGIN
title Flyandance C/C++ Compile and Run Batch Program 1.22
echo ===============================================================
echo   Flyandance C/C++ Compile and Run Batch Program 1.22:
echo ===============================================================

::####################################################################################
::  Source Code Scanning Stage
::####################################################################################

:SOURCE_ASSEMBLY
:: working path is where this batch file is located 
set "Working_Path=%~dp0"
cd %Working_Path%

:: using Output folder to for all output object file and final hex file
if not exist "%Working_Path%Output" mkdir Output

:: Project_Name is project folder name
for %%I in (.) do set "Project_Name=%%~nI"
::echo %Project_Name%

:: Main_Folder is the main folder path without the last slash \
for %%J in (.) do set "Main_Folder=%%~dpnxJ"
::echo %Main_Folder%

:: This should come after path and path change
SetLocal EnableDelayedexpansion

::==============================================
::  check if this is a c or cpp project
::==============================================
set /a cSource=0
set /a cppSource=0
@FOR /f "delims=" %%f IN ('dir /b /s "*.c*"') DO (
    if %%~xf EQU .c set /a cSource+=1 
    if %%~xf EQU .cpp set /a cppSource+=1
)

:: if sourceTypecc is more than 1, then both .c and .cpp have been scanned - an error
if !cSource! GTR 0  set /a sourceTypecc+=1  
if !cppSource! GTR 0 set /a sourceTypecc+=1

:: projectSource is the type of project going to be compiled
if !cSource! GTR !cppSource! ( set "projectSource=c" )
if !cppSource! GTR !cSource! ( set "projectSource=cplus" ) 
if !cppSource! EQU 0 ( if !cSource! EQU 0 ( set "Message=Error: No Valid Source Found, boo^!"
goto BOOZZ
))
if !sourceTypecc! GTR 1 ( set "Message=Error: Have only .c or .cpp files inside working folder, NOT both, boo^!"
goto BOOZZ )

:: number of source files
set /a "Source_index=0"

::==============================================
:: This is a c project
::==============================================
if !projectSource! EQU c ( set "PickedCompiler=gcc.exe"
echo      ^>^>^> C Project: %Project_Name%
echo ---------------------------------------------------------------

FOR /f "delims=" %%f IN ('dir /b /s "*.c"') DO ( set "Obj_files=!Obj_files!"./Output/%%~nf.o" "
	set "source_files=!source_files!%%~nxf "
	
	set /a "Source_index+=1"
	set "temp=%%~dpf"
	set temp=!temp:%Main_Folder%=.!
	set "SourceFilePathName[!Source_index!]=!temp!%%~nxf"
	set "SourceFileOnlyName[!Source_index!]=%%~nf"
  )
  
echo Compiling !Source_index! source files:
echo !source_files!
)

::==============================================
:: This is a cpp project
::==============================================
if !projectSource! EQU cplus ( set "PickedCompiler=g++.exe"
echo     ^>^>^> C++ Project: %Project_Name%                  ^>^>
echo ---------------------------------------------------------------
FOR /f "delims=" %%f IN ('dir /b /s "*.cpp"') DO ( set "Obj_files=!Obj_files!"./Output/%%~nf.o" "
	set "source_files=!source_files!%%~nxf "
	
	set /a "Source_index+=1"
	set "temp=%%~dpf"
	set temp=!temp:%Main_Folder%=.!
	set "SourceFilePathName[!Source_index!]=!temp!%%~nxf"
	set "SourceFileOnlyName[!Source_index!]=%%~nf"
  )

echo Compiling !Source_index! source files:
echo !source_files!
)

::==============================================
:: Scan for .s file and compile them to .o file 
::==============================================

if %compileAssembly% EQU yes (
:: number of source files
set /a "asmSourceCC=0"

FOR /f "delims=" %%f IN ('dir /b /s /a-d "*.s" 2^>nul') DO (
	set "Obj_files=!Obj_files!"./Output/%%~nf.o" "
	set "ASMsource_files=!ASMsource_files!%%~nxf "
	
	set /a "asmSourceCC+=1"
	set /a "Source_index+=1"
	set "temp=%%~dpf"
	set temp=!temp:%Main_Folder%=.!
	set "SourceFilePathName[!Source_index!]=!temp!%%~nxf"
	set "SourceFileOnlyName[!Source_index!]=%%~nf"
)
  
if !asmSourceCC! GTR 0 (
echo ---------------------------------------------------------------
echo Compiling !asmSourceCC! ASM files:
echo !ASMsource_files!
)
)

::=======================================================
:: Scan for external .o file and include them for linkage 
::=======================================================

if %linkEXTobject% EQU yes (

::First delete all object file from output folder first
if exist ".\Output\*.o" ( del ".\Output\*.o" )

:: number of source files
set /a "EXTojectCC=0"

FOR /f "delims=" %%f IN ('dir /b /s /a-d "*.o" 2^>nul') DO (
	set "temp=%%~dpnxf"
	set temp=!temp:%Main_Folder%=.!

	set "Obj_files=!Obj_files!"!temp!" "

	set /a "EXTojectCC+=1"
	set "EXToject_files=!EXToject_files!%%~nxf "
)

if !EXTojectCC! GTR 0 (
echo ---------------------------------------------------------------
echo Added !EXTojectCC! External Object files to linkage:
echo !EXToject_files!
)
)

::####################################################################################
::  Compiling Stage
::####################################################################################

:: NOTE: Obj_files are not compiled yet, but they should be in Output folder when compilation is done
::####################################################################################

echo ===============================================================
echo =====^>^>              Compiling and Linking              ^<^<=====
echo ===============================================================
set "compiler=%Compiler_Path%!PickedCompiler!" 

::==============================================XXX
:: Compile
for /L %%i in (1,1,%Source_index%) do (
 "!compiler!" %CompileOptions% -c "!SourceFilePathName[%%i]!" -o "./Output/!SourceFileOnlyName[%%i]!.o" %IncludePath%
 if %errorlevel% NEQ  0 ( Echo Compile Error: Check your code or target MCU, boo^^!
 GOTO BOOZZ)
)

::==============================================XXX
:: linkage 
"!compiler!" !Obj_files! -o "./Output/%Project_Name%" %LinkOptions%
if %errorlevel% NEQ  0 ( Echo.
Echo Linking Error: Objects failed to link, boo^^!
GOTO BOOZZ)

::==============================================XXX
:: Convert elf file to lss file
if %createLSSfile% EQU yes (
"%Compiler_Path%objdump.exe" -h -S "./Output/%Project_Name%.exe" > "./Output/%Project_Name%.lss.txt"
)

::==============================================XXX
:: Compiled Successfully - Clean up 
echo.
echo    ^<Project:%Project_Name%^> compiled Successfully^^! ^^:^)
echo    -------------------------------------------------------
cd Output

:: object files can be deleted if desired
if %deleteOBJ% EQU yes (
del *.o
)

::==============================================XXX
:: Display the size of the project 
"%Compiler_Path%size.exe" "%Project_Name%.exe"
echo    -------------------------------------------------------
echo    ^<%Project_Name%^> Executable can be found here: 
echo    %CD%\
echo.

echo ***************************************************************
echo *****                Compilation Successful               *****
echo ***************************************************************

::==============================================
::-------------- AutoRun or Not ----------------
::==============================================

echo.
echo ===============================================================
CHOICE /N /C:yn /D n /T 5 /M "=====>>>>> Run New Program Now? (y/n):"
echo ===============================================================
echo.
IF ERRORLEVEL ==2 GOTO END
IF ERRORLEVEL ==1 GOTO RUN


:RUN
cls 2^>nul
echo ===============================================================
echo ==========^>^>^>  New Program Runtime Message: %Project_Name% ^>^>^>
echo ---------------------------------------------------------------
%CD%\%Project_Name%.exe
echo.
echo.
echo ===============================================================
pause
GOTO END
EXIT

::==============================================
:: NOT Well Done, display a Message and Exit 
:: using pause so you can check out the error
::==============================================
:BOOZZ
IF DEFINED Message echo !Message!
echo.
echo xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
echo *****                 Compilation Failed                  *****
echo xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
echo.
pause
EXIT

::==============================================
:: END - DONE and Exit
::==============================================
:END
EXIT
