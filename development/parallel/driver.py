#!/usr/bin/env python

DEBUG_OPTIONS = ['-O2', '-Wall', '-Wline-truncation', '-Wcharacter-truncation']
DEBUG_OPTIONS += ['-Wsurprising', '-Waliasing', '-Wimplicit-interface']
DEBUG_OPTIONS += ['-Wunused-parameter', '-fwhole-file', '-fcheck=all']
DEBUG_OPTIONS += ['-fbacktrace', '-g', '-fmax-errors=1', '-ffpe-trap=invalid']


import os
import sys
import numpy as np


# WHAT WHEN number of procs larger than states, does zero work.
index_set = range(20)
num_procs = 4

disply = np.zeros(4)


total = len(index_set)


print(disply)

j = 0
for i in range(total):

    if j == num_procs:
        j = 0
    
    disply[j] += 1

    j = j + 1


#print(disply)


#sys.exit('prototyping')

os.system('git clean -d -f')

src = ['shared/shared_constants.f90', 'shared/shared_auxiliary.f90',
         'solve/solve_auxiliary.f90',
         'solve/solve_fortran.f90', 'evaluate/evaluate_auxiliary.f90',
         'evaluate/evaluate_fortran.f90', 'estimate/estimate_auxiliary.f90',
         'simulate/simulate_fortran.f90', 'resfort.f90']

# Compile all files.
#for file_ in src:
#    cmd = 'gfortran -c ' + file_
#    os.system(cmd)

# Link 
cmd = 'mpif90 ' + ' '.join(src) + ' -o resfort -llapack ' + ' '.join(DEBUG_OPTIONS)
print(cmd)
assert os.system(cmd) == 0



# Run executable
print('\n running\n')
os.system('git checkout .model.resfort.ini')
assert os.system('mpirun -np 2 ./resfort') == 0