@echo on
setlocal enabledelayedexpansion

cd src
echo FC=%FC%
echo F77=%F77%
echo F90=%F90%
echo CC=%CC%
echo CXX=%CXX%
echo MAKE=%MAKE%
echo BUILD_PREFIX=%BUILD_PREFIX%
echo PREFIX=%PREFIX%
echo CONDA_PREFIX=%CONDA_PREFIX%
@REM set PATH=%BUILD_PREFIX%\Library\bin;%BUILD_PREFIX%\bin;%SYSTEMROOT%\System32;%SYSTEMROOT%;%SYSTEMROOT%\System32\Wbem;%PATH%
@REM for /f "delims=" %%F in ('where objdump 2^>NUL') do set OBJDUMP=%%F
@REM where f2py
@REM echo PATH=%PATH%
@REM where x86_64-w64-mingw32-gfortran.exe
@REM where libgfortran-*.dll
@REM where libgcc_s_seh-1.dll
@REM where libwinpthread-1.dll
echo PATH=%PATH%
echo BUILD_PREFIX=%BUILD_PREFIX%
echo PREFIX=%PREFIX%
dir /b "%PREFIX%\Library\bin\libgfortran*.dll" 2>NUL
dir /b "%PREFIX%\Library\bin\libgcc_s_seh-1.dll" 2>NUL
dir /b "%PREFIX%\Library\bin\libwinpthread-1.dll" 2>NUL
dir /b "%PREFIX%\Library\bin\libquadmath-0.dll" 2>NUL
dir /b "%BUILD_PREFIX%\Library\bin\libgfortran*.dll" 2>NUL
dir /b "%BUILD_PREFIX%\Library\bin\libgcc_s_seh-1.dll" 2>NUL
dir /b "%BUILD_PREFIX%\Library\bin\libwinpthread-1.dll" 2>NUL
dir /b "%BUILD_PREFIX%\Library\bin\libquadmath-0.dll" 2>NUL
if not "x%OBJDUMP%"=="x" %OBJDUMP% -p "%BUILD_PREFIX%\Library\bin\libgfortran-5.dll" | findstr DLL
%PYTHON% -m numpy.f2py -h >NUL 2>&1

if exist "..\MANIFEST.in" (
  powershell -Command "$p='..\MANIFEST.in'; $c=Get-Content $p; if ($c -notmatch '\.pyd') { Add-Content $p 'recursive-include mokit *.pyd' }"
)

set F90=%FC%
set F77=%FC%
@REM set MESON_CROSS_DIR=%USERPROFILE%\.local\share\meson\cross
@REM set MESON_CROSS_FILE=%MESON_CROSS_DIR%\skip_sanity.ini
@REM if not exist "%MESON_CROSS_DIR%" mkdir "%MESON_CROSS_DIR%"
@REM (
@REM   echo [properties]
@REM   echo skip_sanity_check = true
@REM ) > "%MESON_CROSS_FILE%"
@REM set MESON_CROSS_FILE=%MESON_CROSS_FILE%
copy /Y "%RECIPE_DIR%\Makefile.gnu_openblas_conda.win" Makefile.gnu_openblas_conda.win
powershell -Command "$content = Get-Content Makefile.main; $content = $content -replace '\$\(F90\) -shared \$\(FFLAGS\) \$\(MKL_FLAGS\) -o librest2fch\.so \$\(OBJ_py2fch\)', '\$(F90) -shared \$(FFLAGS) -o librest2fch.so \$(OBJ_py2fch) \$(MKL_FLAGS)'; $content = $content -replace 'librest2fch\.so', 'librest2fch.dll'; $content = $content -replace '\.so', '.pyd'; $content = $content -replace '@mv ', '@move '; Set-Content Makefile.main $content"

make exe -f Makefile.gnu_openblas_conda.win
for /f "delims=" %%F in ('dir /s /b "%SRC_DIR%\src\f2pytmp\bbdir\meson-private\sanitycheckf.exe" 2^>NUL') do (
  echo --- %%F
  if not "x%OBJDUMP%"=="x" %OBJDUMP% -p "%%F" | findstr DLL
)
set BUILD_ERROR=%ERRORLEVEL%
if not %BUILD_ERROR%==0 (
  echo Make failed with %BUILD_ERROR%
  echo Searching for meson logs
  for /f "delims=" %%F in ('dir /s /b "%SRC_DIR%\src\f2pytmp\bbdir\meson-logs\meson-log.txt" 2^>NUL') do (
    echo --- %%F
    type "%%F"
  )
  exit /b %BUILD_ERROR%
)
dir /b *.pyd *.so 2>NUL

cd ..
%PYTHON% -m pip install -v --prefix=%PREFIX% .
if errorlevel 1 exit /b %errorlevel%

if exist bin (
  if not exist %PREFIX%\bin mkdir %PREFIX%\bin
  for %%F in (bin\*) do move %%F %PREFIX%\bin
)

endlocal
