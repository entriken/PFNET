#***************************************************#
# This file is part of PFNET.                       #
#                                                   #
# Copyright (c) 2015-2016, Tomas Tinoco De Rubira.  #
#                                                   #
# PFNET is released under the BSD 2-clause license. #
#***************************************************#

import sys
from Cython.Build import cythonize
from distutils.core import setup, Extension
import numpy as np
import os

libraries = ['pfnet']
# raw parser
if '--no_raw_parser' in sys.argv:
    sys.argv.remove('--no_raw_parser')
else:
    libraries.append('raw_parser')
    
# graphviz
if '--no_graphviz' in sys.argv:
    sys.argv.remove('--no_graphviz')
else:
    libraries.append('gvc')


setup(name='PFNET',
      version='1.3',
      license='BSD 2-clause license',
      description='Power Flow Network Library',
      author='Tomas Tinoco De Rubira',
      author_email='ttinoco5687@gmail.com',
      packages=['pfnet',
                'pfnet.parser'],
      ext_modules=cythonize([Extension("pfnet.cpfnet", 
                                       [os.path.join("pfnet", 'cpfnet.pyx')],
                                       libraries=libraries,
                                       library_dirs=["../lib"],
                                       include_dirs=["../include", np.get_include()])]))
      
