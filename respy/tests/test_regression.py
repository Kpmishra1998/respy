"""Run a few regression tests."""
import pickle

import numpy as np
import pytest

from respy.config import CHAOSPY_INSTALLED
from respy.config import TEST_RESOURCES_DIR
from respy.config import TOL_REGRESSION_TESTS
from respy.likelihood import get_log_like_func
from respy.tests.random_model import simulate_truncated_data


def compute_log_likelihood(params, options):
    df = simulate_truncated_data(params, options)
    log_like = get_log_like_func(params, options, df)
    crit_val = log_like(params)

    return crit_val


def load_regression_tests():
    """Load regression tests from disk."""
    with open(TEST_RESOURCES_DIR / "regression_vault.pickle", "rb") as p:
        tests = pickle.load(p)

    return tests


@pytest.fixture(scope="session")
def regression_vault():
    """Make regression vault available to tests."""
    return load_regression_tests()


@pytest.mark.end_to_end
@pytest.mark.parametrize("index", range(10))
def test_single_regression(regression_vault, index):
    """Run a single regression test."""
    params, options, exp_val = regression_vault[index]

    if CHAOSPY_INSTALLED or options["monte_carlo_sequence"] == "random":
        crit_val = compute_log_likelihood(params, options)

        assert np.isclose(
            crit_val, exp_val, rtol=TOL_REGRESSION_TESTS, atol=TOL_REGRESSION_TESTS
        )
