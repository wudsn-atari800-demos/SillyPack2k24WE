set BASE_DIR=%~dp0
set EXOMIZER=C:\jac\system\Windows\Tools\FIL\Exomizer\win32\exomizer.exe
set MADS=C:\jac\system\Atari800\Tools\ASM\MADS\mads.exe
set MAGICK="C:\Program Files\ImageMagick-7.1.0-Q16-HDRI\magick.exe"
set WINRAR=C:\jac\system\Windows\Tools\FIL\WinRAR\winrar.exe

set SITE_DIR=C:\jac\system\WWW\Sites\www.wudsn.com

for %%I in (%BASE_DIR%.) do set RELEASE=%%~nxI
set RELEASE_LOWERCASE=%RELEASE%
call :lower_case RELEASE_LOWERCASE
goto :eof

:lower_case
for %%a in ("A=a" "B=b" "C=c" "D=d" "E=e" "F=f" "G=g" "H=h" "I=i"
            "J=j" "K=k" "L=l" "M=m" "N=n" "O=o" "P=p" "Q=q" "R=r"
            "S=s" "T=t" "U=u" "V=v" "W=w" "X=x" "Y=y" "Z=z") do (
    call set %~1=%%%~1:%%~a%%
)
goto:eof
