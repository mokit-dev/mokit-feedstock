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
set PATH=%BUILD_PREFIX%\Library\bin;%BUILD_PREFIX%\bin;%SYSTEMROOT%\System32;%SYSTEMROOT%;%SYSTEMROOT%\System32\Wbem;%PATH%
@REM for /f "delims=" %%F in ('where objdump 2^>NUL') do set OBJDUMP=%%F
@REM where f2py
@REM echo PATH=%PATH%
@REM where x86_64-w64-mingw32-gfortran.exe
@REM where libgfortran-*.dll
@REM where libgcc_s_seh-1.dll
@REM where libwinpthread-1.dll
@REM where libquadmath-0.dll
@REM where libgomp-1.dll
@REM dir /b "%PREFIX%\Library\bin\libgfortran*.dll" 2>NUL
@REM dir /b "%PREFIX%\Library\bin\libgcc_s_seh-1.dll" 2>NUL
@REM dir /b "%PREFIX%\Library\bin\libwinpthread-1.dll" 2>NUL
@REM dir /b "%BUILD_PREFIX%\Library\bin\libgfortran*.dll" 2>NUL
@REM dir /b "%BUILD_PREFIX%\Library\bin\libgcc_s_seh-1.dll" 2>NUL
@REM dir /b "%BUILD_PREFIX%\Library\bin\libwinpthread-1.dll" 2>NUL
@REM dir /b "%BUILD_PREFIX%\Library\bin\libquadmath-0.dll" 2>NUL
@REM dir /b "%BUILD_PREFIX%\Library\bin\libgomp-1.dll" 2>NUL
@REM if not "x%OBJDUMP%"=="x" %OBJDUMP% -p "%BUILD_PREFIX%\Library\bin\libgfortran-5.dll" | findstr DLL
%PYTHON% -m numpy.f2py -h >NUL 2>&1

if exist "..\MANIFEST.in" (
  powershell -Command "$p='..\MANIFEST.in'; $c=Get-Content $p; if ($c -notmatch '\.pyd') { Add-Content $p 'recursive-include mokit *.pyd' }"
)

set F90=%FC%
set F77=%FC%
set MESON_ARGS=--cross-file "%RECIPE_DIR%\meson.cross.ini"
copy /Y "%RECIPE_DIR%\Makefile.gnu_openblas_conda.win" Makefile.gnu_openblas_conda.win
powershell -Command "$content = Get-Content Makefile.main; $content = $content -replace '\$\(F90\) -shared \$\(FFLAGS\) \$\(MKL_FLAGS\) -o librest2fch\.so \$\(OBJ_py2fch\)', '\$(F90) -shared \$(FFLAGS) -o librest2fch.so \$(OBJ_py2fch) \$(MKL_FLAGS)'; $content = $content -replace 'librest2fch\.so', 'librest2fch.dll'; $content = $content -replace '\.so', '.pyd'; $content = $content -replace '@mv ', '@move '; Set-Content Makefile.main $content"

make all -f Makefile.gnu_openblas_conda.win
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
