#!/usr/bin/env python

import numpy as np

from respy.python.shared.shared_constants import IS_PARALLELISM_MPI
from respy.python.shared.shared_constants import IS_PARALLELISM_OMP
from respy.python.shared.shared_auxiliary import print_init_dict

from codes.random_init import generate_random_dict
from codes.auxiliary import simulate_observed

from respy import estimate
from respy import RespyCls


count = 0
while True:
        print('COUNT', count)
        count += 1
        # Generate random initialization file
        constr = dict()
        constr['version'] = 'FORTRAN'
        constr['maxfun'] = np.random.randint(0, 50)
        init_dict = generate_random_dict(constr)

        # We fix an optimizer that is always valid.
        init_dict['ESTIMATION']['optimizer'] = 'FORT-BOBYQA'

        base = None
        for is_parallel in [True, False]:

            init_dict['PROGRAM']['threads'] = 1
            init_dict['PROGRAM']['procs'] = 1

            if is_parallel:
                if IS_PARALLELISM_OMP:
                    init_dict['PROGRAM']['threads'] = np.random.randint(2, 5)
                if IS_PARALLELISM_MPI:
                    init_dict['PROGRAM']['procs'] = np.random.randint(2, 5)

            print_init_dict(init_dict)

            respy_obj = RespyCls('test.respy.ini')
            respy_obj = simulate_observed(respy_obj)
            _, crit_val = estimate(respy_obj)

            if base is None:
                base = crit_val
            np.testing.assert_equal(base, crit_val)
