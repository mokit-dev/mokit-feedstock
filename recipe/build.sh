set -x -e
cd src
echo `which f2py`
sed -i '' 's/-lgomp//g' Makefile.gnu_openblas_conda
sed -i '' 's/rest2fch.so/rest2fch.dylib/g' Makefile.main
sed -i '' 's/dll/dll *.dylib/g' ../MANIFEST.in
make all -f Makefile.gnu_openblas_conda
cd ..
pip install -v --prefix=$PREFIX .
ls $PREFIX/bin
mv bin/* $PREFIX/bin
