:: ####################################################################################
:: Flyandance Advanced 8-bit AVR compile and Upload Batch Program Universal 2.3 BLT
:: To Compile: avr8-gnu-toolchain-win is required; It includes compiler and library
:: To Upload:  driver installed for the interface and a copy of AVRdude binary
::                                      © 2024 Flyandance - All right reserved
:: ####################################################################################
@echo OFF 
:: ************************************************************************************
:: ====================================================================================
::                    Flyandance IDE-less batch program configurations:  
:: ====================================================================================
:: ************************************************************************************
:: Define Path -- AVR toolchain bin folder location(space supported)
set "Compiler_Path=C:\AVR\avr8-gnu-toolchain-win32_x86\bin\"

:: Define Path -- The location of AVRDude(space supported)
set "Uploader=C:\AVR\avrdude\"

::#####################################################################################
:: ###-More Compile Option: -v -fno-jump-tables -w -Wall -Wno-uninitialized -Wno-unused-value 
:: -std=<std>     standard:c90,c99,c11,c17,gnu90,gnu99,gnu11,gnu17
:: -x lang        Specify source language:c,c++,assembler-with-cpp || Optimization: -Os -O1 -O3
set "CompileOptions= -Os -Wall "

:: -I "dir-include-path"  || Directory Search: -iquote dir -isystem dir -idirafter dir
set "IncludePath= "

:: ###-More Linkage Option: -nostartfiles || -l LIBNAME  ||  -L "dir-library-path"
set "LinkOptions= " 

::**************************************************************************************
:: yes or no -- FOR ##compiling## .s source files 
set "compileAssembly=yes"
:: yes or no -- FOR ##linking## external .o object files 
set "linkEXTobject=yes"

:: ######## --MCU Pick-- comment out to disable override ########
:: atmega8 atmega88 atmega328p attiny13 atmega16 Atmega32 atmega128 Atmega169p
   set "TargetMCU=atmega8"

::**************************************************************************************
:: yes or no -- choose to **upload** or not after compilation
	set "AUTOupload=no"

:: Programmer ID: butterfly USBasp avr910 -- Upload routine based on picked Upload_PRO
set "Upload_PRO=USBasp"
set "Upload_PORT=COM3"
set "Upload_BAUD=1000000"
::======================================================================================

:: yes or no -- delete compiled object files in Output
set "deleteOBJ=yes"

:: yes or no -- FOR creating a LSS file
set "createLSSfile=yes"

::======================================================================================
:: 1k-bootloader for MCU with: 8k 16k 32k 128k bytes memory
set "Enable_1k_BL_MCU_SIZE=8k"
::############################################################################
:: .text should at address 0 for normal application code
:: Bootloader size is in words, but should be defined here in byte 
if %Enable_1k_BL_MCU_SIZE% NEQ no (
	if %Enable_1k_BL_MCU_SIZE% EQU 8k ( set "codeSection=-Wl,--section-start=.text=0x1C00" )
	if %Enable_1k_BL_MCU_SIZE% EQU 16k ( set "codeSection=-Wl,--section-start=.text=0x3C00" )
	if %Enable_1k_BL_MCU_SIZE% EQU 32k ( set "codeSection=-Wl,--section-start=.text=0x7C00" )
	if %Enable_1k_BL_MCU_SIZE% EQU 128k ( set "codeSection=-Wl,--section-start=.text=0x1FC00" )
	set "writeLockFuse=yes"
) 

::  void dummy (void) __attribute__((section ("FD_app")));
:: User defined section, if function not set, have no effect
set FD_app=0x0

set "LinkOptions=%LinkOptions% %codeSection% -Wl,--section-start=FD_app=%FD_app%"

::####################################################################################

::************************************************************************************
::************************************************************************************
::####################################################################################
::  Target MCU picking Stage
::####################################################################################

:BEGIN
title Advanced 8-bit AVR Compile and Upload Universal 2.3 BLT
echo ===============================================================
echo   Flyandance Advanced 8-bit AVR Compile and Upload UNI 2.3 BLT:
echo ===============================================================
:: ### MCU pick Override by TargetMCU ###
if defined TargetMCU ( GOTO %TargetMCU% )
echo.
echo   1,Atmega8     4,Attiny13    7,Atmega128   
echo   2,Atmega88    5,Atmega16    8,Atmega169p         
echo   3,Atmega328p  6,Atmega32    9,Other  
echo.

::auto select default to n -- Comment out below line to make it prompt for choice
::set "autoSelect=/D 1 /T 0"

CHOICE /N /C:123456789 %autoSelect% /M "Select a MCU (#):"%1
IF ERRORLEVEL ==9 GOTO self_Defined
IF ERRORLEVEL ==8 GOTO atmega169p
IF ERRORLEVEL ==7 GOTO atmega128
IF ERRORLEVEL ==6 GOTO atmega32
IF ERRORLEVEL ==5 GOTO atmega16
IF ERRORLEVEL ==4 GOTO attiny13
IF ERRORLEVEL ==3 GOTO atmega328p
IF ERRORLEVEL ==2 GOTO atmega88
IF ERRORLEVEL ==1 GOTO atmega8
GOTO END

:self_Defined
set Picked_MCU=attiny85
set Upload_MCU=t85
GOTO SOURCE_ASSEMBLY

:atmega169p
set Picked_MCU=atmega169p
set Upload_MCU=m169
GOTO SOURCE_ASSEMBLY

:atmega128
set Picked_MCU=atmega128
set Upload_MCU=m128
GOTO SOURCE_ASSEMBLY

:atmega32
set Picked_MCU=atmega32
set Upload_MCU=m32
GOTO SOURCE_ASSEMBLY

:atmega16
set Picked_MCU=atmega16
set Upload_MCU=m16
GOTO SOURCE_ASSEMBLY

:attiny13
set Picked_MCU=attiny13
set Upload_MCU=t13
GOTO SOURCE_ASSEMBLY

:atmega328p
set Picked_MCU=atmega328p
set Upload_MCU=m328p
GOTO SOURCE_ASSEMBLY

:atmega88
set Picked_MCU=atmega88
set Upload_MCU=m88
GOTO SOURCE_ASSEMBLY

:atmega8
set Picked_MCU=atmega8
set Upload_MCU=m8
GOTO SOURCE_ASSEMBLY


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
if !projectSource! EQU c ( set "PickedCompiler=avr-gcc.exe"
echo      ^<^< C Project:%Project_Name%   ^|^|   MCU:%Picked_MCU% ^>^>
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
if !projectSource! EQU cplus ( set "PickedCompiler=avr-g++.exe"
echo     ^<^< C++ Project:%Project_Name%   ^|^|   MCU:%Picked_MCU% ^>^>
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
 "!compiler!" %CompileOptions% -mmcu=%Picked_MCU% -c "!SourceFilePathName[%%i]!" -o "./Output/!SourceFileOnlyName[%%i]!.o" %IncludePath%
 if %errorlevel% NEQ  0 ( Echo Compile Error: Check your code or target MCU, boo^^!
 GOTO BOOZZ)
)

::==============================================XXX
:: linkage 
"!compiler!" -mmcu=%Picked_MCU% !Obj_files! -o "./Output/%Project_Name%.elf" %LinkOptions%
if %errorlevel% NEQ  0 ( Echo.
Echo Linking Error: Objects failed to link, boo^^!
GOTO BOOZZ)

::==============================================XXX
:: Convert elf file to hex file -- Hex file is the final file that we need
"%Compiler_Path%avr-objcopy.exe" -O ihex "./Output/%Project_Name%.elf" "./Output/%Project_Name%.hex"

::==============================================XXX
:: Convert elf file to lss file - For debug
if %createLSSfile% EQU yes (
"%Compiler_Path%avr-objdump.exe" -h -S "./Output/%Project_Name%.elf" > "./Output/%Project_Name%.lss.txt"
)

::==============================================XXX
:: Compiled Successfully - Clean up now
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
"%Compiler_Path%avr-size.exe" "%Project_Name%.elf"
del *.elf
echo    -------------------------------------------------------
echo    ^<%Project_Name%.hex^> can be found here: 
echo    %CD%\
echo.

if %AUTOupload% EQU no ( goto NO_Upload )
GOTO Prepare_UPLOAD

::####################################################################################
::  Upload Stage
::####################################################################################

::=============================
:Prepare_UPLOAD
::=============================

if %Upload_PRO% EQU avr910 GOTO PRO_avr910
if %Upload_PRO% EQU butterfly GOTO PRO_butterfly
if %Upload_PRO% EQU USBasp GOTO PRO_USBasp

:PRO_avr910
:: if this is avr910-FDxICSP, Use -x devcode=0x11; and turn Off auto-Reset-MCU BC it's a programmer
set "UploadOPTIONS=-c %Upload_PRO% -b %Upload_BAUD% -P %Upload_PORT% -x devcode=0x11"
set "autoResetMCU=no"
GOTO UPLOAD_NOW

:PRO_butterfly
:: if this is avr109-FDxBoot, turn ON auto-Reset-MCU BC it's Bootloader
set "UploadOPTIONS=-c %Upload_PRO% -b %Upload_BAUD% -P %Upload_PORT%"
set "autoResetMCU=yes"
GOTO UPLOAD_NOW

:PRO_USBasp
:: if this is USBasp, turn Off auto-Reset-MCU, and remove serial option; BC it's a USB programmer
set "UploadOPTIONS=-c %Upload_PRO%"
set "autoResetMCU=no"
GOTO UPLOAD_NOW

::=============================
:UPLOAD_NOW
::=============================

if !autoResetMCU! EQU yes (
::Engage Serial, thus resetting the MCU, and force it into bootloader mode
mode %Upload_PORT% baud=%Upload_BAUD% parity=n data=8 rts=on dtr=on 1>NUL
)

:: uploading - If successful, go to END; or retry in about 5 seconds
echo ***************************************************************
echo ^>^>^>^>^>^>^>^>           Upload Via %Upload_PRO%           ^>^>^>^>^>^>^>^>
echo ***************************************************************
"%Uploader%avrdude.exe" !UploadOPTIONS! -p %Upload_MCU% -U flash:w:"%Project_Name%.hex":i
if %errorlevel% GTR  0 ( GOTO RETRY_UPLOAD)

::Write Lock fuse for bootloader only 0x2f or 0xef is the same thing;
if defined writeLockFuse ( "%Uploader%avrdude.exe" !UploadOPTIONS! -p %Upload_MCU% -u -U lock:w:0xef:m ) 
GOTO WELL_DONE

:RETRY_UPLOAD
timeout 5
GOTO UPLOAD_NOW

::####################################################################################  !! 
::  Ending Stage
::####################################################################################  !!

:NO_Upload
:: No upload, Only compile and link
echo ***************************************************************
echo *****               Compilation Successful                *****
echo ***************************************************************
GOTO END

:WELL_DONE
:: It may not been uploaded; this only implies no error has been reported back
echo ***************************************************************
echo *****                 Upload Successfully                 *****
echo ***************************************************************
GOTO END

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
:: Done and Exit - 5 seconds timeout to Exit
::==============================================
:END
echo.
timeout 5
EXIT
