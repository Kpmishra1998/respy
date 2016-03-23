
# standard library
import logging
import sys
import os

# Package structure
from robupy.estimate.estimate import estimate
from robupy.simulate.simulate import simulate

from robupy.process.process import process
from robupy.read.read import read

from robupy.estimate.estimate import estimate
from robupy.evaluate.evaluate import evaluate
from robupy.python.solve import solve

# Check for Python 3
if not (sys.version_info[0] == 3):
    raise AssertionError('Please use Python 3')


""" Testing functions
"""


def test():
    """ Run nose tester for the package.
    """
    base = os.getcwd()

    os.chdir(os.path.dirname(os.path.realpath(__file__)))

    os.chdir('tests')

    os.system('nosetests tests.py')

    os.chdir(base)


""" Set up logging.
"""

logging.captureWarnings(True)

