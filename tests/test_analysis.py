"""Correctness tests for the R/Python parity utilities."""
import sys
from pathlib import Path

import numpy as np
import pytest

sys.path.insert(0, str(Path(__file__).parent.parent / "R"))
from analysis import newey_west_mean_tstat, block_bootstrap_sharpe_ci


def test_newey_west_rejects_clear_positive_mean():
    rng = np.random.default_rng(0)
    r = rng.normal(0.003, 0.005, 400)  # strong, unambiguous positive mean
    result = newey_west_mean_tstat(r)
    assert result["significant_at_5pct"]
    assert result["mean_daily_return"] > 0


def test_newey_west_false_positive_rate_matches_nominal_alpha():
    """A single noise draw rejecting at p<0.05 is expected ~5% of the time
    by construction and is not itself a bug -- test the false-positive
    *rate* across many independent draws instead of asserting on one."""
    n_trials = 200
    rejections = 0
    for seed in range(n_trials):
        rng = np.random.default_rng(seed)
        r = rng.normal(0.0, 0.01, 400)
        result = newey_west_mean_tstat(r)
        rejections += result["significant_at_5pct"]
    false_positive_rate = rejections / n_trials
    assert false_positive_rate < 0.12  # nominal 5%, allow slack for finite-sample HAC approx


def test_bootstrap_ci_ordered_and_finite():
    rng = np.random.default_rng(2)
    r = rng.normal(0.0005, 0.01, 300)
    result = block_bootstrap_sharpe_ci(r, n_boot=200)
    assert result["ci_low"] <= result["ci_high"]
    assert np.isfinite(result["ci_low"]) and np.isfinite(result["ci_high"])


if __name__ == "__main__":
    sys.exit(pytest.main([__file__, "-v"]))
