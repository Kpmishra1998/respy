"""General configuration for respy."""
from pathlib import Path

import numpy as np

# Check if chaospy is installed.
try:
    import chaospy  # noqa
except ImportError:
    CHAOSPY_INSTALLED = False
else:
    CHAOSPY_INSTALLED = True

# Obtain the root directory of the package. Do not import respy which creates a circular
# import.
ROOT_DIR = Path(__file__).parent

# Directory with additional resources for the testing harness
TEST_DIR = ROOT_DIR / "tests"
TEST_RESOURCES_DIR = ROOT_DIR / "tests" / "resources"

# Set maximum numbers to 1e200 and log(1e200) = 460.
MAX_FLOAT = 1e200
MIN_FLOAT = -MAX_FLOAT
MAX_LOG_FLOAT = 460
MIN_LOG_FLOAT = -MAX_LOG_FLOAT

COVARIATES_DOT_PRODUCT_DTYPE = np.float64
"""numpy.dtype : Dtype of covariates before being used in a dot product.

If you convert a DataFrame with boolean variables and others to an NumPy array, the
resulting array will have an 'object' dtype. Having an 'object' dtype array causes a lot
of problems as functions like :func:`numpy.exp` will fail raising an uninformative error
message.

"""

DTYPE_STATES = np.uint8
INDEXER_DTYPE = np.int32
"""numpy.dtype : Data type for the entries in the state space indexer."""
INDEXER_INVALID_INDEX = np.iinfo(INDEXER_DTYPE).min
"""int : Identifier for invalid states.

Every valid state has a unique number which is stored in the state space indexer at the
correct position. Invalid entries in the indexer are filled with
:data:`INDEXER_INVALID_INDEX` which is the most negative value for
:data:`INDEXER_DTYPE`. Using the invalid value as an index likely raises an
:class:`IndexError` as negative indices cannot exceed the length of the indexed array
dimension.

"""

# Some assert functions take rtol instead of decimals
TOL_REGRESSION_TESTS = 1e-10

SEED_STARTUP_ITERATION_GAP = 1_000_000

DEFAULT_OPTIONS = {
    "estimation_draws": 200,
    "estimation_seed": 1,
    "estimation_tau": 500,
    "interpolation_points": -1,
    "simulation_agents": 1000,
    "simulation_seed": 2,
    "solution_draws": 200,
    "solution_seed": 3,
    "core_state_space_filters": [],
    "negative_choice_set": {},
    "monte_carlo_sequence": "random",
    "cache_compression": "snappy",
}

KEANE_WOLPIN_1994_MODELS = [f"kw_94_{suffix}" for suffix in ["one", "two", "three"]]
KEANE_WOLPIN_1997_MODELS = [
    "kw_97_basic",
    "kw_97_basic_respy",
    "kw_97_extended",
    "kw_97_extended_respy",
]
KEANE_WOLPIN_2000_MODELS = ["kw_2000"]
ROBINSON_CRUSOE_MODELS = [
    "robinson_crusoe_basic",
    "robinson_crusoe_extended",
    "robinson_crusoe_with_observed_characteristics",
]

EXAMPLE_MODELS = (
    KEANE_WOLPIN_1994_MODELS
    + KEANE_WOLPIN_1997_MODELS
    + KEANE_WOLPIN_2000_MODELS
    + ROBINSON_CRUSOE_MODELS
)
