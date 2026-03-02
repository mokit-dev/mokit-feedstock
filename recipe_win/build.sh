#!/usr/bin/env bash
set -euo pipefail

# This recipe is built on Windows runners, but we keep the build
# logic in bash so it can run under Git Bash/MSYS2.

cd src

echo "FC=${FC:-}"
echo "F77=${F77:-}"
echo "F90=${F90:-}"
echo "CC=${CC:-}"
echo "CXX=${CXX:-}"
echo "MAKE=${MAKE:-}"
echo "BUILD_PREFIX=${BUILD_PREFIX:-}"
echo "PREFIX=${PREFIX:-}"
echo "CONDA_PREFIX=${CONDA_PREFIX:-}"
echo "PATH=${PATH}"

command -v f2py || true
command -v x86_64-w64-mingw32-gfortran.exe || true
command -v gfortran || true
command -v objdump || true

# MESON_NATIVE_FILE_WIN="${TEMP:-/tmp}/meson-native.ini"
# MESON_NATIVE_FILE="${MESON_NATIVE_FILE_WIN//\\//}"
# export MESON_NATIVE_FILE

# cat >"$MESON_NATIVE_FILE_WIN" <<'EOF'
# [properties]
# skip_sanity_check = true
# EOF

# Ensure MANIFEST.in includes pyd files
# if [[ -f "../MANIFEST.in" ]]; then
#   if ! grep -qE '^[[:space:]]*recursive-include[[:space:]]+mokit[[:space:]]+\*\.pyd([[:space:]]|$)' "../MANIFEST.in"; then
#     printf '\nrecursive-include mokit *.pyd\n' >>"../MANIFEST.in"
#   fi
# fi

export F90="${FC:-${F90:-}}"
export F77="${FC:-${F77:-}}"

cp -f "${RECIPE_DIR}/Makefile.gnu_openblas_conda.win" Makefile.gnu_openblas_conda.win

# Patch Makefile.main: build Windows outputs
sed -i.bak \
  -e 's/librest2fch\.so/librest2fch.dll/g' \
  -e 's/\.so/\.pyd/g' \
  Makefile.main

make all -f Makefile.gnu_openblas_conda.win

cd ..

"${PYTHON}" -m pip install -v --prefix="${PREFIX}" .

if [[ -d bin ]]; then
  mkdir -p "${PREFIX}/bin"
  mv -f bin/* "${PREFIX}/bin" || true
fi
