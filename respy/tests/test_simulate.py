"""Test the simulation routine."""
import numpy as np
import pandas as pd
import pytest
import yaml

import respy as rp
from respy.config import EXAMPLE_MODELS
from respy.config import TEST_DIR
from respy.likelihood import get_log_like_func
from respy.pre_processing.data_checking import check_simulated_data
from respy.pre_processing.model_processing import process_params_and_options
from respy.pre_processing.specification_helpers import generate_obs_labels
from respy.shared import apply_law_of_motion_for_core
from respy.tests.random_model import generate_random_model
from respy.tests.utils import process_model_or_seed


@pytest.mark.end_to_end
@pytest.mark.parametrize("model_or_seed", EXAMPLE_MODELS)
def test_simulated_data(model_or_seed):
    """Test simulated data with ``check_simulated_data``.

    Note that, ``check_estimation_data`` is also tested in this function as these tests
    focus on a subset of the data.

    """
    params, options = process_model_or_seed(model_or_seed)

    simulate = rp.get_simulate_func(params, options)
    df = simulate(params)

    optim_paras, _ = process_params_and_options(params, options)
    check_simulated_data(optim_paras, df)


@pytest.mark.end_to_end
@pytest.mark.parametrize("model", ["kw_97_basic", "kw_97_extended"])
def test_one_step_ahead_simulation(model):
    params, options, df = rp.get_example_model(model)
    options["n_periods"] = 11
    simulate = rp.get_simulate_func(params, options, "one_step_ahead", df)
    _ = simulate(params)


@pytest.mark.end_to_end
@pytest.mark.parametrize("model", ["kw_97_basic", "kw_97_extended"])
def test_n_step_ahead_simulation_with_data(model):
    params, options, df = rp.get_example_model(model)
    options["n_periods"] = 11
    simulate = rp.get_simulate_func(params, options, "n_step_ahead_with_data", df)
    _ = simulate(params)


@pytest.mark.end_to_end
@pytest.mark.edge_case
def test_equality_for_myopic_agents_and_tiny_delta():
    """Test equality of simulated data and likelihood with myopia and tiny delta."""
    # Get simulated data and likelihood for myopic model.
    params, options = generate_random_model(myopic=True)

    simulate = rp.get_simulate_func(params, options)
    df = simulate(params)

    log_like = get_log_like_func(params, options, df)
    likelihood = log_like(params)

    # Get simulated data and likelihood for model with tiny delta.
    params.loc["delta", "value"] = 1e-12

    df_ = simulate(params)

    log_like = rp.get_log_like_func(params, options, df_)
    likelihood_ = log_like(params)

    # The continuation values are different because for delta = 0 the backward induction
    # is completely skipped and all continuation values are set to zero whereas for a
    # tiny delta, the delta ensures that continuation have no impact.
    columns = df.filter(like="Continu").columns.tolist()
    pd.testing.assert_frame_equal(df.drop(columns=columns), df_.drop(columns=columns))

    np.testing.assert_almost_equal(likelihood, likelihood_, decimal=12)


@pytest.mark.end_to_end
@pytest.mark.edge_case
def test_equality_of_models_with_and_without_observables():
    """Test equality of models with and without observables.

    First, generate a model where the parameter values of observables is set to zero.
    The second model is obtained by assigning all observable indicators the value of the
    constant in the reward functions and set the constants to zero. The two models
    should be equivalent.

    """
    # Now specify a set of observables
    observables = [np.random.randint(2, 6)]
    point_constr = {"observables": observables}

    # Get simulated data and likelihood for myopic model.
    params, options = generate_random_model(myopic=True, point_constr=point_constr)

    # Get all reward values
    index_reward = [
        x for x in set(params.index.get_level_values(0)) if "nonpec" in x or "wage" in x
    ]

    # Get all indices that have
    obs_labels = generate_obs_labels(observables, index_reward)

    # Set these values to zero
    params.loc[obs_labels, "value"] = 0

    # Simulate the base model
    simulate = rp.get_simulate_func(params, options)
    df = simulate(params)

    # Put two new values into the eq
    for x in obs_labels:
        params.loc[x, "value"] = params.loc[(x[0], "constant"), "value"]

    for x in index_reward:
        params.loc[(x, "constant"), "value"] = 0

    # Simulate the new model
    df_ = simulate(params)

    # test for equality
    pd.testing.assert_frame_equal(df_, df)


@pytest.mark.end_to_end
@pytest.mark.precise
def test_distribution_of_observables():
    """Test that the distribution of observables matches the simulated distribution."""
    # Now specify a set of observables
    point_constr = {"observables": [np.random.randint(2, 6)], "simulation_agents": 1000}

    params, options = generate_random_model(point_constr=point_constr)

    simulate = rp.get_simulate_func(params, options)
    df = simulate(params)

    # Check observable probabilities
    probs = df["Observable_0"].value_counts(normalize=True, sort=False)

    # Check proportions
    n_levels = point_constr["observables"][0]
    for level in range(n_levels):
        # Some observables might be missing in the simulated data because of small
        # probabilities. Test for zero probability in this case.
        probability = probs.loc[level] if level in probs.index else 0

        params_probability = params.loc[
            (f"observable_observable_0_{level}", "probability"), "value"
        ]

        np.testing.assert_allclose(probability, params_probability, atol=0.05)


@pytest.mark.unit
@pytest.mark.precise
@pytest.mark.parametrize("i", range(1, 3))
def test_apply_law_of_motion(i):
    df = pd.read_csv(
        TEST_DIR / "test_simulate" / f"test_apply_law_of_motion_{i}_in.csv",
    )
    optim_paras = yaml.safe_load(
        TEST_DIR.joinpath(
            "test_simulate", f"test_apply_law_of_motion_{i}_optim_paras.yaml"
        ).read_text()
    )

    new_df = apply_law_of_motion_for_core(df, optim_paras).drop(columns="choice")

    expected = pd.read_csv(
        TEST_DIR / "test_simulate" / f"test_apply_law_of_motion_{i}_out.csv",
    )

    assert new_df.equals(expected)


@pytest.mark.parametrize("model", ["robinson_crusoe_basic", "kw_94_one"])
def test_data_variables(model):
    """Value function components in df add up to internally computed values."""
    _, _, df = rp.get_example_model(model)

    for choice in df.Choice.unique():
        choice = choice.capitalize()
        # Shocks in working choices are already included in the wage.
        df["Shock_Nonpec"] = np.where(
            df[f"Wage_{choice}"].isna(), df[f"Shock_Reward_{choice}"], 0
        )
        df[f"Flow_Utility_{choice}_"] = (
            df[f"Wage_{choice}"].fillna(0)
            + df[f"Nonpecuniary_Reward_{choice}"]
            + df["Shock_Nonpec"]
        )
        df[f"Value_Function_{choice}_"] = (
            df[f"Flow_Utility_{choice}_"]
            + df["Discount_Rate"] * df[f"Continuation_Value_{choice}"]
        )

        pd.testing.assert_series_equal(
            df[f"Flow_Utility_{choice}_"],
            df[f"Flow_Utility_{choice}"],
            check_names=False,
        )
        pd.testing.assert_series_equal(
            df[f"Value_Function_{choice}_"],
            df[f"Value_Function_{choice}"],
            check_names=False,
        )
