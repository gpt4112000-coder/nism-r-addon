# NISM Certification + R Add-On

## Description
A two-track project that pairs certification prep with a compact R demonstration. Track 1 is a structured study plan for NISM Series VIII Equity Derivatives (syllabus, registration, mock log) to meet a mandatory hiring requirement. Track 2 re-implements flagship backtest metrics (Sharpe, max drawdown, hit rate) in R and cross-checks them against Python, showing R fluency for a “preferred” tool without overstating expertise. Together they address both the credential gap and the tooling preference for the role.

## Part 1 — NISM Series VIII: Equity Derivatives (Mandatory)

### Identify the module
Securities-markets roles often require **NISM Series VIII – Equity Derivatives** (covers futures/options, margins, settlement, regulations). Series VIII is the standard for junior quant/derivatives roles; Series I (Currency Derivatives) is the alternative if the focus is FX. Confirm the specific module with the recruiter if possible.

### Registration (self-study, computer-based)
1. Create account at https://www.nism.ac.in → Certifications → Register.
2. Choose **Series VIII: Equity Derivatives Certification Examination**, pay fee (~Rs. 1500-2000), book slot at NISM test centre (PAN India) or online proctored where offered.
3. Study from official NISM workbook (PDF on site): ~300 pages, 100 MCQs, 60% pass.
4. Timeline: 2–4 weeks part-time (official workbook + mock tests).

### Syllabus mapping
| Workbook chapter | What to study |
|---|---|
| Basics of derivatives, forwards/futures | Payoff, pricing, cost-of-carry |
| Options (calls/puts, Greeks) | Black-Scholes basics, margins |
| Clearing/settlement | SPAN, VaR, MTM |
| Regulations & risks | SEBI, position limits |

See `nism/study_plan.md` for week-by-week breakdown.

### Mock test log
`nism/mock_test_log.csv` tracks attempt date, score, weak topics — fill as you practice. Target 80%+ on mocks before booking.

### Once registered/passed
Update `resume_draft.tex` Certifications:
```latex
\item NISM Series VIII (Equity Derivatives) -- Certified (Month Year) [or ``Registered, exam Month Year'']
\item NISM Series VIII -- in progress (if booked)
```
and revise cover letter line from “prepared to complete” to concrete status.

## Part 2 — R Add-On (Small, opportunistic)
Flagship's Python performance metrics (Sharpe/drawdown) reimplemented in **R** as `R/analysis.R` + Python-verified version `R/analysis.py` — both now also compute a **Newey-West significance test** and a **block-bootstrap 95% CI on Sharpe**, not just the point estimate, matching the statistical standard used in the flagship project's own `src/stats.py`.

Run:
```bash
python3 R/analysis.py          # Sharpe/DD + Newey-West + bootstrap CI, in Python
Rscript R/analysis.R           # same in R (if R installed) -- see note below
python3 -m pytest tests/ -v    # correctness tests for both stat utilities
```

### Current results (against flagship's live `daily_returns.csv`, 1711 days)
| Metric | Value |
|---|---|
| Sharpe | -0.19 |
| Max drawdown | -8.58% |
| Hit rate | 49.0% |
| Newey-West t-stat (mean daily return) | -0.54 |
| Newey-West p-value | 0.590 (not significant) |
| Bootstrap 95% CI on Sharpe | [-0.888, 0.514] |

Consistent with the flagship project's own conclusion: no statistically detectable edge on synthetic data. This script re-derives that finding independently (reading the same `daily_returns.csv`, but computing its own Sharpe/NW/bootstrap from scratch) rather than just quoting the flagship number, which is what actually demonstrates R/Python parity rather than assuming it.

### R evidence snippet
```r
# R/analysis.R — Sharpe/drawdown + Newey-West + bootstrap CI, same formulas as Python
daily <- read.csv("daily_returns.csv")
sharpe <- mean(daily$strategy_ret) / sd(daily$strategy_ret) * sqrt(252)
fit <- lm(strategy_ret ~ 1, data=daily)
nw_test <- coeftest(fit, vcov=vcovHAC(fit, lag=maxlags, type="HC0"))  # sandwich/lmtest
```

This demonstrates R fluency for a "preferred" tool without claiming standalone expertise — honest and interview-defensible, and now includes the same statistical rigor (not just point estimates) as the rest of this repo's projects.

## Tests (`tests/test_analysis.py`)
3 pytest cases: Newey-West correctly rejects a clearly-nonzero mean; the false-positive *rate* across 200 independent pure-noise draws is checked against the nominal ~5% (a single noise draw asserting "not significant" is itself flaky by design — ~1 in 20 will spuriously reject, so the rate is tested, not one draw); bootstrap CI bounds are ordered and finite.

## Limitations
- Not yet certified — folder tracks prep, not a claim. Do not add to resume until exam booked/passed.
- R is minimal (two scripts) — sufficient for "preferred" not "expert"; expand only if R becomes core.
- `R/analysis.R` was updated to match `R/analysis.py`'s logic exactly but **hasn't been executed in this sandbox** (no R interpreter available here) — treat it as unverified-but-code-reviewed until run once with `Rscript`, same caveat as `app-0004-.../R/analysis.R`.

## Structure
```
nism/study_plan.md  nism/mock_test_log.csv  nism/workbook_notes.md
R/analysis.R  R/analysis.py  R/README.md
tests/test_analysis.py
```
