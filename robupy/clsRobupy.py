""" Module that contains the class that carries around information for the
    grmpy package
"""

# standard library
import pickle as pkl

# project library
from robupy.clsMeta import MetaCls

class RobupyCls(MetaCls):
    
    def __init__(self):
        
        self.attr = dict()

        self.attr['init_dict'] = None

        # Derived attributes
        self.attr['num_periods'] = None

        self.attr['num_agents'] = None

        self.attr['num_draws'] = None

        self.attr['edu_start'] = None

        self.attr['edu_max'] = None

        self.attr['delta'] = None

        self.attr['shocks'] = None

        self.attr['seed'] = None

        self.attr['debug'] = None

        # Results
        self.attr['emax'] = None

        self.attr['states_number_period'] = None

        self.attr['states_all'] = None

        self.attr['period_payoffs_ex_post'] = None

        self.attr['mapping_state_idx'] = None

        # The ex post realizations are only stored for
        # debugging purposes. In the special case of
        # no randomness, they have to be equal to the
        # ex ante version. The same is true for the
        # future payoffs
        self.attr['period_payoffs_ex_ante'] = None

        self.attr['future_payoffs'] = None

        # Status indicator
        self.is_locked = False

        self.is_first = True

    ''' Derived attributes
    '''
    def _derived_attributes(self):
        """ Calculate derived attributes.
        """

        # Distribute class attributes
        init_dict = self.attr['init_dict']

        is_first = self.is_first

        if is_first:

            self.attr['num_periods'] = init_dict['BASICS']['periods']

            self.attr['num_agents'] = init_dict['BASICS']['agents']

            self.attr['delta'] = init_dict['BASICS']['delta']

            self.attr['edu_start'] = init_dict['EDUCATION']['start']

            self.attr['edu_max'] = init_dict['EDUCATION']['max']

            self.attr['num_draws'] = init_dict['COMPUTATION']['draws']

            self.attr['debug'] = init_dict['COMPUTATION']['debug']

            self.attr['seed'] = init_dict['COMPUTATION']['seed']

            self.attr['shocks'] = init_dict['SHOCKS']

            self.is_first = False

    def _check_integrity(self):
        """ Check integrity of class instance.
        """

        # Debug status
        assert (self.attr['debug'] in [True, False])