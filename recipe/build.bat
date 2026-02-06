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
%PYTHON% -m numpy.f2py -h >NUL 2>&1

set F90=%FC%
set F77=%FC%
copy /Y "%RECIPE_DIR%\Makefile.gnu_openblas_conda.win" Makefile.gnu_openblas_conda.win
powershell -Command "$content = Get-Content Makefile.main; $content = $content | ForEach-Object { if ($_ -match '^\s*@mv .*\.so') { $_ -replace '\.so', '.pyd' } else { $_ } }; Set-Content Makefile.main $content"
make all -f Makefile.gnu_openblas_conda.win
dir /b *.pyd *.so 2>NUL
if errorlevel 1 exit /b %errorlevel%

cd ..
%PYTHON% -m pip install -v --prefix=%PREFIX% .
if errorlevel 1 exit /b %errorlevel%

if exist bin (
  if not exist %PREFIX%\bin mkdir %PREFIX%\bin
  for %%F in (bin\*) do move %%F %PREFIX%\bin
)

endlocal
