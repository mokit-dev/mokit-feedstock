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
make all -f Makefile.gnu_openblas_conda.win

cd ..
%PYTHON% -m pip install -v --prefix=%PREFIX% .

if exist bin (
  if not exist %PREFIX%\bin mkdir %PREFIX%\bin
  for %%F in (bin\*) do move %%F %PREFIX%\bin
)

endlocal
