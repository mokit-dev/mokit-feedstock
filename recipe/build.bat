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
where f2py
set PATH=%BUILD_PREFIX%\Library\bin;%BUILD_PREFIX%\bin;%PATH%
echo PATH=%PATH%
where x86_64-w64-mingw32-gfortran.exe
where libgfortran-*.dll
where libgcc_s_seh-1.dll
where libwinpthread-1.dll
dir /b "%BUILD_PREFIX%\Library\bin\libgfortran*.dll" 2>NUL
dir /b "%BUILD_PREFIX%\Library\bin\libgcc_s_seh-1.dll" 2>NUL
dir /b "%BUILD_PREFIX%\Library\bin\libwinpthread-1.dll" 2>NUL
where dumpbin && set HAVE_DUMPBIN=1
where objdump && set HAVE_OBJDUMP=1
%PYTHON% -m numpy.f2py -h >NUL 2>&1

set F90=%FC%
set F77=%FC%
copy /Y "%RECIPE_DIR%\Makefile.gnu_openblas_conda.win" Makefile.gnu_openblas_conda.win
powershell -Command "$content = Get-Content Makefile.main; $content = $content | ForEach-Object { if ($_ -match '^\s*@mv .*\.so') { $_ -replace '\.so', '.pyd' } else { $_ } }; Set-Content Makefile.main $content"
make all -f Makefile.gnu_openblas_conda.win
set BUILD_ERROR=%ERRORLEVEL%
if not %BUILD_ERROR%==0 (
  echo Make failed with %BUILD_ERROR%
  echo Searching for meson logs in %TEMP%
  for /f "delims=" %%F in ('dir /s /b "%TEMP%\meson-log.txt" 2^>NUL') do (
    echo --- %%F
    type "%%F"
  )
  echo Searching for sanitycheckf.exe in %TEMP%
  for /f "delims=" %%F in ('dir /s /b "%TEMP%\sanitycheckf.exe" 2^>NUL') do (
    echo --- %%F
    if not "x%HAVE_DUMPBIN%"=="x" dumpbin /dependents "%%F"
    if "x%HAVE_DUMPBIN%"=="x" if not "x%HAVE_OBJDUMP%"=="x" objdump -p "%%F" | findstr DLL
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
