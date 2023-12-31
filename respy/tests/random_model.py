"""This module contains the functions for the generation of random requests."""
import collections
import copy

import numpy as np
import pandas as pd
from estimagic.utilities import cov_matrix_to_params
from estimagic.utilities import cov_matrix_to_sdcorr_params
from estimagic.utilities import number_of_triangular_elements_to_dimension

from respy.config import DEFAULT_OPTIONS
from respy.config import ROOT_DIR
from respy.pre_processing.model_processing import process_params_and_options
from respy.pre_processing.specification_helpers import csv_template
from respy.pre_processing.specification_helpers import (
    initial_and_max_experience_template,
)
from respy.pre_processing.specification_helpers import (
    lagged_choices_covariates_template,
)
from respy.pre_processing.specification_helpers import lagged_choices_probs_template
from respy.pre_processing.specification_helpers import observable_coeffs_template
from respy.pre_processing.specification_helpers import observable_prob_template
from respy.shared import generate_column_dtype_dict_for_estimation
from respy.shared import normalize_probabilities
from respy.simulate import _random_choice
from respy.simulate import get_simulate_func


_BASE_COVARIATES = {
    "not_any_exp_a": "exp_a == 0",
    "not_any_exp_b": "exp_b == 0",
    "any_exp_a": "exp_a > 0",
    "any_exp_b": "exp_b > 0",
    "hs_graduate": "exp_edu >= 12",
    "co_graduate": "exp_edu >= 16",
    "is_minor": "period < 2",
    "is_young_adult": "2 <= period <= 4",
    "is_adult": "5 <= period",
    "constant": "1",
    "exp_a_square": "exp_a ** 2 / 100",
    "exp_b_square": "exp_b ** 2 / 100",
    "up_to_nine_years_edu": "exp_edu <= 9",
    "at_least_ten_years_edu": "exp_edu >= 10",
}
"""dict: Dictionary containing specification of covariates.

.. deprecated:: x.x.x

    This variable must be removed if generate_random_model is rewritten such that
    functions for each replicable paper are written.

"""


def generate_random_model(
    point_constr=None,
    bound_constr=None,
    n_types=None,
    n_type_covariates=None,
    myopic=False,
):
    """Generate a random model specification.

    Parameters
    ----------
    point_constr : dict
        A full or partial options specification. Elements that are specified here are
        not drawn randomly.
    bound_constr : dict
        Upper bounds for some options to keep computation time reasonable. Can have the
        keys ["max_types", "max_periods", "max_edu_start", "max_agents", "max_draws"]
    n_types : int
        Number of unobserved types.
    n_type_covariates :
        Number of covariates to calculate type probabilities.
    myopic : bool
        Indicator for myopic agents meaning the discount factor is set to zero.

    """
    point_constr = {} if point_constr is None else copy.deepcopy(point_constr)
    bound_constr = {} if bound_constr is None else copy.deepcopy(bound_constr)

    for constr in point_constr, bound_constr:
        assert isinstance(constr, dict)

    bound_constr = _consolidate_bound_constraints(bound_constr)

    if n_types is None:
        n_types = np.random.randint(1, bound_constr["max_types"] + 1)
    if n_type_covariates is None:
        n_type_covariates = np.random.randint(2, 4)

    params = csv_template(
        n_types=n_types, n_type_covariates=n_type_covariates, initialize_coeffs=False
    )
    params["value"] = np.random.uniform(low=-0.05, high=0.05, size=len(params))

    params.loc["delta", "value"] = 1 - np.random.uniform() if myopic is False else 0

    n_shock_coeffs = len(params.loc["shocks_sdcorr"])
    dim = number_of_triangular_elements_to_dimension(n_shock_coeffs)
    helper = np.eye(dim) * 0.5
    helper[np.tril_indices(dim, k=-1)] = np.random.uniform(
        -0.05, 0.2, size=(n_shock_coeffs - dim)
    )
    cov = helper.dot(helper.T)
    params.loc["shocks_sdcorr", "value"] = cov_matrix_to_sdcorr_params(cov)

    params.loc["meas_error", "value"] = np.random.uniform(
        low=0.001, high=0.1, size=len(params.loc["meas_error"])
    )

    n_edu_start = np.random.randint(1, bound_constr["max_edu_start"] + 1)
    edu_starts = point_constr.get(
        "edu_start", np.random.choice(np.arange(1, 15), size=n_edu_start, replace=False)
    )
    edu_shares = point_constr.get("edu_share", _get_initial_shares(n_edu_start))
    edu_max = point_constr.get("edu_max", np.random.randint(max(edu_starts) + 1, 30))
    params = pd.concat(
        [params, initial_and_max_experience_template(edu_starts, edu_shares, edu_max)],
        axis=0,
        sort=False,
    )

    n_lagged_choices = point_constr.get("n_lagged_choices", np.random.choice(2))
    if n_lagged_choices:
        choices = ["a", "b", "edu", "home"]
        lc_probs_params = lagged_choices_probs_template(n_lagged_choices, choices)
        lc_params = pd.read_csv(
            ROOT_DIR / "pre_processing" / "lagged_choice_params.csv"
        )
        lc_params.set_index(["category", "name"], inplace=True)
        params = pd.concat([params, lc_probs_params, lc_params], axis=0, sort=False)
        lc_covariates = lagged_choices_covariates_template()
    else:
        lc_covariates = {}

    observables = point_constr.pop("observables", None)
    if observables is None:
        n_observables = np.random.randint(0, 3)
        # Do not sample observables with 1 level!
        observables = (
            np.random.randint(2, 4, size=n_observables) if n_observables else False
        )

    if observables is not False:
        to_concat = [
            params,
            observable_prob_template(observables),
            observable_coeffs_template(observables, params),
        ]
        params = pd.concat(to_concat, axis="rows", sort=False)

        indices = (
            params.index.get_level_values("category")
            .str.extract(r"observable_([a-z0-9_]+)", expand=False)
            .dropna()
            .unique()
        )
        observable_covs = {x: "{} == {}".format(*x.rsplit("_", 1)) for x in indices}
    else:
        observable_covs = {}

    options = {
        "simulation_agents": np.random.randint(3, bound_constr["max_agents"] + 1),
        "simulation_seed": np.random.randint(1, 1_000),
        "n_periods": np.random.randint(1, bound_constr["max_periods"]),
        "solution_draws": np.random.randint(1, bound_constr["max_draws"]),
        "solution_seed": np.random.randint(1, 10_000),
        "estimation_draws": np.random.randint(1, bound_constr["max_draws"]),
        "estimation_seed": np.random.randint(1, 10_000),
        "estimation_tau": np.random.uniform(100, 500),
        "interpolation_points": -1,
    }

    options = {
        **DEFAULT_OPTIONS,
        **options,
        "covariates": {**_BASE_COVARIATES, **lc_covariates, **observable_covs},
    }

    options = _update_nested_dictionary(options, point_constr)

    return params, options


def _consolidate_bound_constraints(bound_constr):
    constr = {
        "max_types": 3,
        "max_periods": 3,
        "max_edu_start": 3,
        "max_agents": 1000,
        "max_draws": 100,
    }
    constr.update(bound_constr)

    return constr


def _get_initial_shares(num_groups):
    """We simply need a valid request for the shares of types summing to one."""
    shares = np.random.uniform(size=num_groups)
    shares = normalize_probabilities(shares)

    return shares


def simulate_truncated_data(params, options, is_missings=True):
    """Simulate a (truncated) dataset.

    The data can have two more properties. First, truncated history, second, missing
    wages.

    """
    optim_paras, _ = process_params_and_options(params, options)

    simulate = get_simulate_func(params, options)
    df = simulate(params)

    np.random.seed(options["simulation_seed"])

    if is_missings:
        # Truncate the histories of agents. This mimics the effect of attrition.
        # Histories can be truncated after the first period or not at all. So, all
        # individuals have at least one observation.
        period_of_truncation = (  # noqa: F841
            df.reset_index()
            .groupby("Identifier")
            .Period.transform(lambda x: np.random.choice(x.max() + 1) + 1)
            .to_numpy()
        )
        data_subset = df.query("Period < @period_of_truncation").copy()

        # Add some missings to wage data.
        is_working = data_subset["Choice"].isin(optim_paras["choices_w_wage"])
        num_drop_wages = int(is_working.sum() * np.random.uniform(high=0.5))

        if num_drop_wages > 0:
            indices = data_subset["Wage"][is_working].index
            index_missing = np.random.choice(indices, num_drop_wages, replace=False)

            data_subset.loc[index_missing, "Wage"] = np.nan
        else:
            pass
    else:
        data_subset = df

    # We can restrict the information to observed entities only.
    col_dtype = generate_column_dtype_dict_for_estimation(optim_paras)
    data_subset = data_subset[list(col_dtype)[2:]]

    return data_subset


def _update_nested_dictionary(dict_, other):
    """Update a nested dictionary with another dictionary.

    The basic ``.update()`` method of dictionaries adds non-existing keys or replaces
    existing keys which works fine for unnested dictionaries. For nested dictionaries,
    levels under the current level are not updated but overwritten. This function
    recursively loops over keys and values and inserts the value if it is not a
    dictionary. If it is a dictionary, it applies the same process again.

    """
    for key, value in other.items():
        if isinstance(value, collections.abc.Mapping):
            dict_[key] = _update_nested_dictionary(dict_.get(key, {}), value)
        else:
            dict_[key] = value
    return dict_


def add_noise_to_params(
    params,
    options,
    delta_low_high=(-0.2, 0.2),
    wages_percent_absolute=(0, 0.2),
    wages_low_high=None,
    wages_null_low_high=(-0.2, 0.2),
    nonpecs_percent_absolute=(0, 0.2),
    nonpecs_low_high=None,
    nonpecs_null_low_high=(-5000, 5000),
    cholesky_low_high=(-0.5, 0.5),
    meas_sd_low_high=(1e-6, 0.5),
    ic_probabilities_low_high=False,
    ic_logit_low_high=False,
    seed=None,
):
    """Add noise to parameters.

    The function allows to vary the noise based on the absolute value for non-zero
    parameters or to simply add noise in forms of bounded random variables.

    The function ensures that special parameters are valid:

    - Probabilities are between 0 and 1.
    - Correlations are between -1 and 1.
    - Diagonal elements of the Cholesky factor have 1e-6 as the lower bound.
    - The standard deviations of the measurement error have 1e-6 as the lower bound.

    Parameters
    ----------
    params : pandas.DataFrame
        The parameters in a DataFrame.
    options : dict
        The options of the model.
    delta_low_high : tuple[float]
        Lower and upper bound to shock to discount factor.
    wages_percent_absolute : float or tuple[float]
        The deviation in percentages of the absolute value of a non-zero parameter is
        either a constant percentage for all parameters or a random percentage between
        upper and lower bounds.
    wages_low_high : tuple[float]
        The deviation for a non-zero parameter value is between an lower and upper
        bound.
    wages_null_low_high : tuple[float]
        The deviation for a parameter with value zero is between the lower and upper
        bound.
    nonpecs_percent_absolute : float or tuple[float]
        The deviation in percentages of the absolute value of a non-zero parameter is
        either a constant percentage for all parameters or a random percentage between
        upper and lower bounds.
    nonpecs_low_high : tuple[float]
        The deviation for a non-zero parameter value is between an lower and upper
        bound.
    nonpecs_null_low_high : tuple[float]
        The deviation for a parameter with value zero is between the lower and upper
        bound.
    cholesky_low_high : tuple[float]
        Lower and upper bound for a shock applied to the Cholesky factor of the shock
        matrix. To ensure proper scaling, the shock is multiplied with the square root
        of the product of diagonal elements for this entry. The shock for the diagonal
        elements is between zero and the upper bound and the resulting diagonal element
        in the Cholesky factor has 1e-6 as the lower bound.
    meas_sd_low_high : tuple[float]
        Lower and upper bound for shock to measurement error standard deviations.
    ic_probabilities_low_high : tuple[float]
        Lower and upper bound for shocks to the probabilities in the initial conditions.
    ic_logit_low_high : tuple[float]
        Lower and upper bound for shocks to the logit coefficients in the initial
        conditions.
    seed : int or None
        Seed to replicate the perturbation.

    Returns
    -------
    params : pandas.DataFrame
        The new parameters.

    """
    if wages_percent_absolute is not None and wages_low_high is not None:
        raise ValueError(
            "Cannot use 'wages_percent_absolute' and 'wages_low_high' at the same "
            "time."
        )
    if nonpecs_percent_absolute is not None and nonpecs_low_high is not None:
        raise ValueError(
            "Cannot use 'nonpecs_percent_absolute' and 'nonpecs_low_high' at the same "
            "time."
        )

    optim_paras, options = process_params_and_options(params, options)

    np.random.seed(seed)

    # Change discount factor.
    delta = params.filter(like="delta", axis=0).copy()
    delta["value"] = np.clip(delta["value"] + np.random.uniform(*delta_low_high), 0, 1)

    # Change non-zero reward parameters.
    wages = params.filter(regex=r"wage_", axis=0).copy()
    nonpecs = params.filter(regex=r"nonpec_", axis=0).copy()
    for rewards, percent_absolute, low_high, null_low_high in zip(
        [wages, nonpecs],
        [wages_percent_absolute, nonpecs_percent_absolute],
        [wages_low_high, nonpecs_low_high],
        [wages_null_low_high, nonpecs_null_low_high],
    ):
        not_zero = ~rewards["value"].eq(0)
        if percent_absolute is not None:
            rewards = _add_percentage_of_absolute_value_as_shock(
                rewards, percent_absolute
            )

        elif low_high is not None:
            low, high = low_high
            rewards.loc[not_zero, "value"] += np.random.uniform(
                low, high, not_zero.sum()
            )

        # Change parameters with value zero.
        if null_low_high is not None:
            low, high = null_low_high
            rewards.loc[~not_zero, "value"] += np.random.uniform(
                low, high, (~not_zero).sum()
            )

    # Change the parameters of the shock matrix.
    shocks = params.filter(regex=r"shocks_(sdcorr|cov|chol)", axis=0).copy()
    if cholesky_low_high:
        low, high = cholesky_low_high
        # Add a random shock to the Cholesky factor of the shock matrix.
        chol = optim_paras["shocks_cholesky"]

        # Create matrix for scaling.
        diag = np.sqrt(np.diag(chol))
        scaling_factor = np.outer(diag, diag)

        # Add random shock to lower triangular.
        idx = np.tril_indices_from(chol, k=-1)
        chol[idx] += (
            np.random.uniform(low, high, size=len(idx[0])) * scaling_factor[idx]
        )

        # Add random shock to diagonal and ensure non-zero elements.
        idx = np.diag_indices_from(chol)
        chol[idx] += np.random.uniform(0, high, size=len(chol)) * scaling_factor[idx]
        chol[idx] = np.clip(chol[idx], 1e-6, None)

        if "shocks_sdcorr" in shocks.index:
            shocks["value"] = cov_matrix_to_sdcorr_params(chol.dot(chol.T))
        elif "shocks_cov" in shocks.index:
            shocks["value"] = cov_matrix_to_params(chol.dot(chol.T))
        elif "shocks_chol" in shocks.index:
            shocks["value"] = cov_matrix_to_params(chol)
        else:
            raise NotImplementedError

    # Change measurement errors.
    meas_sds = params.filter(regex=r"meas_error", axis=0).copy()
    if meas_sd_low_high:
        meas_sds["value"] += np.random.uniform(*meas_sd_low_high, size=len(meas_sds))
        meas_sds["value"] = np.clip(meas_sds["value"], 1e-6, None)

    # Change the parameters of the initial conditions.
    initial_conditions = params.loc[
        params.index.get_level_values("category").str.contains(
            r"initial_exp|lagged_choice|observable|type"
        )
    ].copy()
    is_prob = initial_conditions.index.get_level_values("name") == "probability"
    if ic_probabilities_low_high and bool(initial_conditions):
        initial_conditions.loc[is_prob, "value"] += np.random.uniform(
            *ic_probabilities_low_high, size=is_prob.sum()
        )

        # Correct probabilities.
        initial_conditions.loc[is_prob, "value"] = initial_conditions.loc[
            is_prob, "value"
        ].clip(0, 1)

    if ic_logit_low_high and bool(initial_conditions):
        initial_conditions.loc[~is_prob, "value"] += np.random.uniform(
            *ic_logit_low_high, size=(~is_prob).sum()
        )

    maximum_exps = params.query("category == 'maximum_exp'")

    params = pd.concat(
        [delta, wages, nonpecs, shocks, meas_sds, initial_conditions, maximum_exps]
    ).reindex(index=params.index)

    return params


def _add_percentage_of_absolute_value_as_shock(rewards, rewards_percent_absolute):
    """Add percentage of value as the shock to rewards."""
    not_zero = ~rewards["value"].eq(0)

    if isinstance(rewards_percent_absolute, tuple):
        low, high = rewards_percent_absolute
        rewards_percent_absolute = np.random.uniform(
            low=low, high=high, size=not_zero.sum()
        )
    possible_signs = np.tile(np.array([-1, 1]), (not_zero.sum(), 1))
    sign = _random_choice(possible_signs)

    rewards.loc[not_zero, "value"] += (
        sign * rewards_percent_absolute * rewards.loc[not_zero, "value"].abs()
    )

    return rewards
