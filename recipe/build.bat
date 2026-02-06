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
for /f "delims=" %%F in ('where objdump 2^>NUL') do set OBJDUMP=%%F
where f2py
echo PATH=%PATH%
where x86_64-w64-mingw32-gfortran.exe
where libgfortran-*.dll
where libgcc_s_seh-1.dll
where libwinpthread-1.dll
where libquadmath-0.dll
where libgomp-1.dll
dir /b "%PREFIX%\Library\bin\libgfortran*.dll" 2>NUL
dir /b "%PREFIX%\Library\bin\libgcc_s_seh-1.dll" 2>NUL
dir /b "%PREFIX%\Library\bin\libwinpthread-1.dll" 2>NUL
dir /b "%BUILD_PREFIX%\Library\bin\libgfortran*.dll" 2>NUL
dir /b "%BUILD_PREFIX%\Library\bin\libgcc_s_seh-1.dll" 2>NUL
dir /b "%BUILD_PREFIX%\Library\bin\libwinpthread-1.dll" 2>NUL
dir /b "%BUILD_PREFIX%\Library\bin\libquadmath-0.dll" 2>NUL
dir /b "%BUILD_PREFIX%\Library\bin\libgomp-1.dll" 2>NUL
if not "x%OBJDUMP%"=="x" %OBJDUMP% -p "%BUILD_PREFIX%\Library\bin\libgfortran-5.dll" | findstr DLL
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
    "%%F"
    echo sanitycheckf.exe exit=%%ERRORLEVEL%%
    if not "x%OBJDUMP%"=="x" %OBJDUMP% -p "%%F" | findstr DLL
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
