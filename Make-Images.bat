@echo off
REM 9 PNG images created via "View/Save Frame..." from Altirra.
REM The 672x480 pixels are combined as 3x3 matrix into 1 full PNG image of 1010x683 pixels.

@echo off
call Make-Settings.bat
IF ERRORLEVEL 1 goto :dir_error

set TEMP_PNG=%TEMP%\SillyPack.png
set RELEASE_FILE=%RELEASE%

if not exist images goto :dir_error

REM The first row has a smaller height of 200 pixels.
echo Placing all 9 images at the right position in the template.
%MAGICK% images\Template.png ^
  ( images\1.png -scale 336x240 -crop 336x200+0+17 +repage ) -geometry +0+0     -composite ^
  ( images\2.png -scale 336x240 -crop 336x200+0+20 +repage ) -geometry +337+0   -composite ^
  ( images\3.png -scale 336x240 -crop 336x200+0+25 +repage ) -geometry +674+0   -composite ^
  ( images\4.png -scale 336x240                    +repage ) -geometry +0+201   -composite ^
  ( images\5.png -scale 336x240                    +repage ) -geometry +337+201 -composite ^
  ( images\6.png -scale 336x240                    +repage ) -geometry +674+201 -composite ^
  ( images\7.png -scale 336x240                    +repage ) -geometry +0+442   -composite ^
  ( images\8.png -scale 336x240                    +repage ) -geometry +337+442 -composite ^
  ( images\9.png -scale 336x240                    +repage ) -geometry +674+442 -composite ^
  %TEMP_PNG%

echo Creating GIF of 336x226 pixels for the productions page preview (medium quality)
%MAGICK% %TEMP_PNG% -scale 336x226 %RELEASE_FILE%.gif

echo Creating PNG of 336x226 pixels for the download package (high quality)
%MAGICK% %TEMP_PNG% -scale 336x226 -strip %RELEASE_FILE%.png

echo Creating JPG of 400x270 pixels for Pouet (that is the maximum width allowed)
%MAGICK% %TEMP_PNG% -scale 400x270 %RELEASE_FILE%.jpg
goto :eof

:dir_error
echo ERROR: Invalid working directory.
pause
exit

:magick:error
echo ERROR: ImageMagick failed.
pause
exit
