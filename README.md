# NISM Certification + R Add-On

**For:** Junior Quantitative Analyst, iRage Capital (GIFT City) — mandatory NISM certificate + R evidence.

## Description
A two-track project that pairs certification prep with a compact R demonstration. Track 1 is a structured study plan for NISM Series VIII Equity Derivatives (syllabus, registration, mock log) to meet a mandatory hiring requirement. Track 2 re-implements flagship backtest metrics (Sharpe, max drawdown, hit rate) in R and cross-checks them against Python, showing R fluency for a “preferred” tool without overstating expertise. Together they address both the credential gap and the tooling preference for the role.

## Part 1 — NISM Series VIII: Equity Derivatives (Mandatory)

### Identify the module
iRage is a securities-markets HFT/prop firm; the posting's likely requirement is **NISM Series VIII – Equity Derivatives** (covers futures/options, margins, settlement, regulations) — confirm with recruiter if possible; Series VIII is the standard ask for junior quant/derivatives roles. Alternative: Series I (Currency Derivatives) if FX-heavy, but VIII is safest default.

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
Flagship’s Python performance metrics (Sharpe/drawdown) reimplemented in **R** as `R/analysis.R` + Python-verified version `R/analysis.py`.

Run:
```bash
python3 R/analysis.py          # computes Sharpe/drawdown in Python (verifies R logic)
Rscript R/analysis.R           # same in R (if R installed)
```
Outputs `R/results_metrics.json` + console table proving parity.

### R evidence snippet
```r
# R/analysis.R — Sharpe/drawdown from daily returns
daily <- read.csv("results_daily.csv")
sharpe <- mean(daily$ret) / sd(daily$ret) * sqrt(252)
running_max <- cummax(cumprod(1+daily$ret))
drawdown <- (cumprod(1+daily$ret) - running_max) / running_max
```

This satisfies iRage’s “R preferred” without claiming standalone expertise — honest, interview-defensible.

## Limitations
- Not yet certified — folder tracks prep, not a claim. Do not add to resume until exam booked/passed.
- R is minimal (one script) — sufficient for “preferred” not “expert”; expand only if R becomes core.

## Structure
```
nism/study_plan.md  nism/mock_test_log.csv  nism/workbook_notes.md
R/analysis.R  R/analysis.py  R/README.md
```
