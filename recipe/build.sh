set -x -e
cd src
echo `which f2py`
sed -i '' 's/-lgomp//g' Makefile.gnu_openblas_conda
make all -f Makefile.gnu_openblas_conda || exit 1
cd ..
pip install -v --prefix=$PREFIX .
ls $PREFIX/bin
mv bin/* $PREFIX/bin
