python setup.py clean
#find ./pfnet -name \*.so -delete
find ./pfnet -name \*.pyc -delete
rm ./pfnet/cpfnet.c
rm ./pfnet/cpfnet.h
rm -rf build
rm -rf dist
rm -rf PFNET.egg-info
