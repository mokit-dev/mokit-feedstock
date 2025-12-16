set -x -e
cd src
echo `which f2py`
sed -i '' 's/-lgomp//g' Makefile.gnu_openblas_conda
sed -i '' '/-o librest2fch\.so/s/$/ $(MKL_FLAGS)/' Makefile.main
make all -f Makefile.gnu_openblas_conda
cd ..
pip install -v --prefix=$PREFIX .
#mkdir conda_build
ls $PREFIX/bin
mv bin/* $PREFIX/bin
