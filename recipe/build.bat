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
%PYTHON% -m numpy.f2py -h >NUL 2>&1

F90=%FC% make all -f Makefile.gnu_openblas_conda 

cd ..
%PYTHON% -m pip install -v --prefix=%PREFIX% .

if exist bin (
  if not exist %PREFIX%\bin mkdir %PREFIX%\bin
  for %%F in (bin\*) do move %%F %PREFIX%\bin
)

endlocal
