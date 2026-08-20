# R Add-On: reimplement flagship Sharpe/drawdown in R
# Path is relative to project root; handles both run locations.

# Try to find daily returns from flagship or fallback
daily_paths <- c(
  "../../app-0001-nk-securities-quant-researcher/project-backtested-strategy-engine/results/daily_returns.csv",
  "../../app-0001-nk-securities-quant-researcher/project/results/daily_returns.csv",
  "../app-0001-nk-securities-quant-researcher/project-backtested-strategy-engine/results/daily_returns.csv",
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

# Save
dir.create("results", showWarnings=FALSE)
res <- data.frame(metric=c("sharpe","max_drawdown","hit_rate","ann_return","ann_vol","days"),
                  value=c(sharpe, max_dd, hit_rate, mean_ret*252, vol*sqrt(252), nrow(daily)))
write.csv(res, "results/R_metrics.csv", row.names=FALSE)
cat("[R] saved results/R_metrics.csv\n")

# Plot
png("results/R_equity.png", width=800, height=400)
par(mfrow=c(1,2))
plot(equity, type="l", col="steelblue", lwd=1, main=sprintf("Equity (Sharpe %.2f)", sharpe), xlab="Day", ylab="Equity")
plot(drawdown, type="l", col="red", lwd=1, main=sprintf("Drawdown (max %.1f%%)", max_dd*100), xlab="Day", ylab="DD")
dev.off()
cat("[R] saved results/R_equity.png\n")
