# R Add-On: reimplement flagship Sharpe/drawdown in R
# Path is relative to project root; handles both run locations.

# Try to find daily returns from flagship or fallback
daily_paths <- c(
  "../../app-0001-nk-securities-quant-researcher/backtested-strategy-engine/results/daily_returns.csv",
  "../../app-0001-nk-securities-quant-researcher/project/results/daily_returns.csv",
  "../app-0001-nk-securities-quant-researcher/backtested-strategy-engine/results/daily_returns.csv",
  "../app-0001-nk-securities-quant-researcher/project/results/daily_returns.csv",
  "results_daily.csv"
)
found <- NA
for (p in daily_paths) {
  if (file.exists(p)) { found <- p; break }
}
# If not found, generate tiny synthetic daily series
if (is.na(found)) {
  cat("[R] No daily_returns.csv found, using synthetic\n")
  set.seed(42)
  daily <- data.frame(Date=seq(as.Date("2020-01-29"), by="day", length.out=500),
                      strategy_ret=rnorm(500, 0.0001, 0.01))
} else {
  cat(sprintf("[R] Using %s\n", found))
  daily <- read.csv(found)
  # column may be named strategy_ret or daily_ret; normalise
  if (!"strategy_ret" %in% names(daily)) {
    # take last numeric column
    numcols <- sapply(daily, is.numeric)
    if (sum(numcols) >= 1) daily$strategy_ret <- daily[, tail(which(numcols),1)]
  }
}

# Core metrics — same formulas as Python flagship
mean_ret <- mean(daily$strategy_ret, na.rm=TRUE)
vol <- sd(daily$strategy_ret, na.rm=TRUE)
sharpe <- mean_ret / vol * sqrt(252)
equity <- cumprod(1 + daily$strategy_ret)
running_max <- cummax(equity)
drawdown <- (equity - running_max) / running_max
max_dd <- min(drawdown, na.rm=TRUE)
hit_rate <- mean(daily$strategy_ret > 0, na.rm=TRUE)

cat(sprintf("Sharpe: %.4f (mean %.6f vol %.6f)\n", sharpe, mean_ret, vol))
cat(sprintf("Max DD: %.4f  Hit rate: %.3f  Days: %d\n", max_dd, hit_rate, nrow(daily)))
cat(sprintf("Equity start %.4f end %.4f total %.2f%%\n", equity[1], tail(equity,1), (tail(equity,1)-1)*100))

# Newey-West significance test on mean daily return, mirroring
# R/analysis.py::newey_west_mean_tstat -- a point-estimate Sharpe with no
# significance/uncertainty attached is easy to over-read.
if (!require("sandwich")) install.packages("sandwich", repos="https://cloud.r-project.org")
if (!require("lmtest")) install.packages("lmtest", repos="https://cloud.r-project.org")
library(sandwich); library(lmtest)
n <- length(na.omit(daily$strategy_ret))
maxlags <- floor(4 * (n/100)^(2/9))  # Newey-West (1994) rule of thumb, same as Python side
fit <- lm(strategy_ret ~ 1, data=daily)
nw_vcov <- vcovHAC(fit, lag=maxlags, type="HC0")
nw_test <- coeftest(fit, vcov=nw_vcov)
nw_t <- nw_test[1, "t value"]
nw_p <- nw_test[1, "Pr(>|t|)"]
cat(sprintf("Newey-West: t=%.3f p=%.3f significant=%s (maxlags=%d)\n", nw_t, nw_p, nw_p < 0.05, maxlags))

# Block bootstrap 95% CI on Sharpe, mirroring
# R/analysis.py::block_bootstrap_sharpe_ci
set.seed(42)
n_boot <- 2000
block_size <- 10
r <- na.omit(daily$strategy_ret)
n_blocks <- ceiling(length(r) / block_size)
boot_sharpes <- numeric(n_boot)
for (b in 1:n_boot) {
  starts <- sample(1:max(length(r) - block_size, 1), n_blocks, replace=TRUE)
  sample_r <- unlist(lapply(starts, function(s) r[s:min(s+block_size-1, length(r))]))[1:length(r)]
  mu <- mean(sample_r); sd_r <- sd(sample_r)
  boot_sharpes[b] <- if (sd_r > 0) (mu/sd_r) * sqrt(252) else 0
}
ci_low <- quantile(boot_sharpes, 0.025)
ci_high <- quantile(boot_sharpes, 0.975)
cat(sprintf("Bootstrap 95%% CI on Sharpe: [%.3f, %.3f]\n", ci_low, ci_high))

# Save
dir.create("results", showWarnings=FALSE)
res <- data.frame(metric=c("sharpe","max_drawdown","hit_rate","ann_return","ann_vol","days",
                            "nw_t_stat","nw_p_value","boot_ci_low","boot_ci_high"),
                  value=c(sharpe, max_dd, hit_rate, mean_ret*252, vol*sqrt(252), nrow(daily),
                          nw_t, nw_p, ci_low, ci_high))
write.csv(res, "results/R_metrics.csv", row.names=FALSE)
cat("[R] saved results/R_metrics.csv\n")

# Plot
png("results/R_equity.png", width=800, height=400)
par(mfrow=c(1,2))
plot(equity, type="l", col="steelblue", lwd=1, main=sprintf("Equity (Sharpe %.2f)", sharpe), xlab="Day", ylab="Equity")
plot(drawdown, type="l", col="red", lwd=1, main=sprintf("Drawdown (max %.1f%%)", max_dd*100), xlab="Day", ylab="DD")
dev.off()
cat("[R] saved results/R_equity.png\n")
