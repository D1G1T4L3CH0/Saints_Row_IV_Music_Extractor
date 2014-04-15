@echo off
setlocal enabledelayedexpansion

:: Lets make for sure we are in the script's directory.
pushd "%~dp0"

:: Make sure the deps.txt file exists.
if not exist "deps.txt" (
	echo It appears the deps.txt file is missing! It should be located right next to this script. if you didn't download it, go and download that file too.
	echo Press any key to exit...
	pause>nul
	exit
)

:: Check to make sure the tools folder exists.
if not exist ".\tools\" (
	echo Please extract all the archives ^(zip,rar,7z^) files to a tools directory next to this script first. And please copy the "revorb.exe" file to the tools directory as well.
	echo.
	echo 1. Create a new folder right next to this script and name it "tools".
	echo 2. Extract the archives into the tools folder.
	echo 3. Copy "revorb.exe" into the tools folder.
	echo.
	echo Press any key to close this window...
	pause>nul
	exit
)
set "PATH=%PATH%;%~dp0tools"

:: Search for the files needed and add their paths to the PATH variable. The PATH variable is not permanently modified, it's local to this script only.
:: This allows the script to use them no matter their location in case when extracted they were put into subdirectories. Avoids extra hassle for the user.
for /r ".\tools\" %%x in (*) do (
	for /f "tokens=* delims=" %%a in (deps.txt) do (
		if "%%~nxx" == "%%a" if "%%~dpx" NEQ "%~dp0tools\" (
			set "PATH=!PATH!;%%~dpx"
		)
	)
)

call :setSourceDir "%ProgramFiles%\Steam\SteamApps\common\Saints Row IV\packfiles\pc\cache\sounds_common.vpp_pc"
call :setSourceDir "%ProgramFiles(x86)%\Steam\SteamApps\common\Saints Row IV\packfiles\pc\cache\sounds_common.vpp_pc"
:tryAgain
if "%src%" == "" (
	cls
	echo The script couldn't locate your game directory. Please enter it below or just drag and drop it on top of this window, and then press ENTER.
	echo.
	echo Example: "D:\Steam\SteamApps\common\Saints Row IV"
	set /p userInput=Game Directory: 
	call :setSourceDir userInput
	if %ERRORLEVEL% == 1 goto pathNotFound
)

:: Find packed_codebooks_aoTuV_603.bin and set a variable with it's path.
for /r ".\tools\" %%x in (*packed_codebooks_aoTuV_603.bin) do set ww2ogg_bin=%%x
if not exist "%ww2ogg_bin%" goto missing_ww2ogg_bin

if not exist ".\EXTRACTED" (
	echo Extracting...
	ThomasJepp.SaintsRow.ExtractPackfile.exe "%src%" ".\EXTRACTED">nul
)

:chooseAgain
:: Display the radio stations for the user to choose from.
cls
echo Please choose a radio station. Just type it as seen here and press ENTER.
echo.
pushd EXTRACTED
for %%x in (radio_*) do (
	set tmpvar=%%x
	if "!tmpvar:~-12!" == "media.bnk_pc" (
		echo - !tmpvar:~6,-13!
	)
)
set tmpvar=
echo.
set /p userInput=Radio Station: 
set "radioStation=radio_%userInput%_media.bnk_pc"
if not exist "%radioStation%" goto stationNotFound
popd

cls
echo Extracting the audio data from the chosen radio station...
echo Radio Station: %radioStation%
echo Tool: bnk_pc_extractor.exe
:: Extract the audio from the radio station.
bnk_pc_extractor.exe ".\EXTRACTED\%radioStation%" ".\bnk_extractor.log"

echo.
echo ________________________________________________________________________________
echo ________________________________________________________________________________
echo Converting the extracted audio files into ogg vorbis format...
echo Tool: ww2ogg.exe
:: Turn the wav files into ogg vorvis files.
if not exist ".\MUSIC" mkdir ".\MUSIC"
for %%x in (.\EXTRACTED\*.wav) do ww2ogg.exe ".\EXTRACTED\%%~nxx" -o ".\MUSIC\%%~nx.ogg" --pcb "%ww2ogg_bin%"

echo.
echo ________________________________________________________________________________
echo ________________________________________________________________________________
echo Removing the original extracted audio files...
:: Remove the wav files.
del ".\EXTRACTED\*.wav"

echo.
echo ________________________________________________________________________________
echo ________________________________________________________________________________
echo Fixing the ogg vorbis files...
echo Tool: revorb.exe
:: Recompute page granule positions in Ogg Vorbis files.
for %%x in (.\MUSIC\*.ogg) do (
	echo %%~nxx
	revorb.exe "%%x"
)

echo.
echo ________________________________________________________________________________
echo ________________________________________________________________________________
echo Done. You will find the extracted music in the MUSIC folder.
echo You may leave the EXTRACTED folder (optional) in case you want to extract more music later.
echo Press any key to close this window...
pause>nul

:: Set the directory back to wherever it was before.
popd
exit

:setSourceDir
	if exist "%~1" (
		set "src=%~1"
		exit /b 0
	) else (
		exit /b 1
	)
goto :EOF

:pathNotFound
	echo Sorry the the required file was not found at the path specified. Press any to to try again...
	pause>nul
	set userInput=
goto tryAgain

:stationNotFound
	echo Sorry the the station chosen was not found. Maybe you typed it wrong? Press any to to try again...
	pause>nul
	set userInput=
goto chooseAgain

:missing_ww2ogg_bin
	echo The script cannot find a file required to convert the audio files to ogg vorbis format. It must reside somewhere within the "tools" directory.
	echo File: packed_codebooks_aoTuV_603.bin
	echo.
	echo Press any key to close this window...
	pause>nul
goto :EOF
