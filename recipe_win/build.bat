@echo on
setlocal enabledelayedexpansion

cd src

REM Merge win-conda branch from jeanwsr fork
git config user.email "conda@build.local"
git config user.name "Conda Build"
git remote add jeanwsr https://gitlab.com/jeanwsr/mokit.git
git fetch jeanwsr win-conda
git merge jeanwsr/win-conda --no-edit

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

set "MESON_NATIVE_FILE_WIN=%TEMP%\meson-native.ini"
set "MESON_NATIVE_FILE=%MESON_NATIVE_FILE_WIN:\=/%"
(
  echo [properties]
  echo skip_sanity_check = true
) > "%MESON_NATIVE_FILE_WIN%"

python "%RECIPE_DIR%\patch_numpy_f2py.py"
python -m numpy.f2py --help | findstr /I native-file
python -m numpy.f2py -h >NUL 2>&1

if exist "..\MANIFEST.in" (
  powershell -Command "$p='..\MANIFEST.in'; $c=Get-Content $p; if ($c -notmatch '\.pyd') { Add-Content $p 'recursive-include mokit *.pyd' }"
)

set F90=%FC%
set F77=%FC%
copy /Y "%RECIPE_DIR%\Makefile.gnu_openblas_conda.win" Makefile.gnu_openblas_conda.win
powershell -Command "$content = Get-Content Makefile.main; $content = $content -replace 'librest2fch\.so', 'librest2fch.dll'; $content = $content -replace '\.so', '.pyd'; Set-Content Makefile.main $content"

make all -f Makefile.gnu_openblas_conda.win
if errorlevel 1 exit /b %errorlevel%
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
