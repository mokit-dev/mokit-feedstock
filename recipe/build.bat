@echo on
setlocal enabledelayedexpansion

cd src
%PYTHON% -m numpy.f2py -h >NUL 2>&1

make -f Makefile.gnu_openblas_conda

cd ..
%PYTHON% -m pip install -v --prefix=%PREFIX% .

if exist bin (
  if not exist %PREFIX%\bin mkdir %PREFIX%\bin
  for %%F in (bin\*) do move %%F %PREFIX%\bin
)

endlocal
