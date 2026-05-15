# ============================================================
#  02_trend_analysis.R
#  Linear trends, STL decomposition, district comparisons
# ============================================================

if (!exists("polio_df")) source("R/01_load_clean.R")
library(dplyr); library(tidyr); library(scales); library(forecast)

cat("\n══════════════════════════════════════════════════\n")
cat("  GHANA POLIO TREND ANALYSIS — 2018–2024\n")
cat("══════════════════════════════════════════════════\n\n")

# ── 1. Annual Summary by District ─────────────────────────────
cat("── 1. Annual Summary ──────────────────────────────\n")
annual <- polio_df %>%
  group_by(District, Year) %>%
  summarise(
    OPV3_Doses       = sum(OPV3_Doses),
    Target_Children  = sum(Target_Children),
    Annual_Coverage  = OPV3_Doses / Target_Children,
    AFP_Cases        = sum(AFP_Cases),
    Zero_Dose        = sum(Zero_Dose_Children),
    Dropout_Rate     = mean(Dropout_OPV1_OPV3),
    .groups = "drop"
  )
print(annual, n = Inf)

# ── 2. Linear Trend Models per District ───────────────────────
cat("\n── 2. Linear Trend Models (OPV3 Coverage) ─────────\n")
trend_models <- polio_df %>%
  group_by(District) %>%
  do(model = lm(OPV3_Coverage ~ Time, data = .))

trend_summary <- trend_models %>%
  rowwise() %>%
  mutate(
    Intercept   = coef(model)[1],
    Slope       = coef(model)[2],
    R_squared   = summary(model)$r.squared,
    P_value     = summary(model)$coefficients[2, 4],
    Significant = ifelse(P_value < 0.05, "YES ***", "no"),
    Direction   = ifelse(Slope > 0, "↑ Improving", "↓ Declining"),
    Quarterly_Change_ppt = Slope * 100
  ) %>%
  select(District, Intercept, Slope, Quarterly_Change_ppt,
         R_squared, P_value, Significant, Direction)

print(as.data.frame(trend_summary))

# Store predicted trend values back in main df
polio_df <- polio_df %>%
  group_by(District) %>%
  mutate(
    Coverage_Trend = predict(
      lm(OPV3_Coverage ~ Time, data = cur_data()),
      cur_data()
    )
  ) %>%
  ungroup()

# ── 3. AFP Trend ───────────────────────────────────────────────
cat("\n── 3. AFP Case Trends ─────────────────────────────\n")
afp_trend <- polio_df %>%
  group_by(District) %>%
  do(model = lm(AFP_Cases ~ Time, data = .)) %>%
  rowwise() %>%
  mutate(
    Slope     = coef(model)[2],
    R_squared = summary(model)$r.squared,
    Direction = ifelse(Slope > 0, "↑ Increasing cases", "↓ Decreasing cases")
  ) %>%
  select(District, Slope, R_squared, Direction)
print(as.data.frame(afp_trend))

# ── 4. STL Seasonal Decomposition ─────────────────────────────
cat("\n── 4. STL Seasonal Decomposition ──────────────────\n")
stl_results <- list()
for (dist in levels(polio_df$District)) {
  sub <- polio_df %>% filter(District == dist) %>% arrange(Date)
  ts_cov <- ts(sub$OPV3_Coverage, frequency = 4,
               start = c(min(sub$Year), min(sub$Quarter)))
  stl_fit <- stl(ts_cov, s.window = "periodic")
  stl_results[[dist]] <- stl_fit
  seasonal_strength <- var(stl_fit$time.series[,"seasonal"]) /
    (var(stl_fit$time.series[,"seasonal"]) + var(stl_fit$time.series[,"remainder"]))
  cat(sprintf("  %s — Seasonal strength: %.3f\n", dist, seasonal_strength))
}

# ── 5. District Comparison Summary ────────────────────────────
cat("\n── 5. Overall District Comparison ─────────────────\n")
comparison <- polio_df %>%
  group_by(District) %>%
  summarise(
    Avg_OPV3_Coverage  = percent(mean(OPV3_Coverage), accuracy = 0.1),
    Latest_Coverage    = percent(last(OPV3_Coverage[order(Date)]), accuracy = 0.1),
    Avg_Dropout_Rate   = percent(mean(Dropout_OPV1_OPV3), accuracy = 0.1),
    Total_AFP_Cases    = sum(AFP_Cases),
    Total_Zero_Dose    = sum(Zero_Dose_Children),
    Avg_Zero_Dose_Rate = percent(mean(Zero_Dose_Rate), accuracy = 0.1)
  )
print(as.data.frame(comparison))

# ── 6. Save Trend Summary ─────────────────────────────────────
if (!dir.exists("outputs")) dir.create("outputs")
write.csv(annual,      "outputs/annual_summary.csv",  row.names = FALSE)
write.csv(comparison,  "outputs/district_comparison.csv", row.names = FALSE)

# Export enriched df for next scripts
assign("polio_df",      polio_df,      envir = .GlobalEnv)
assign("trend_summary", trend_summary, envir = .GlobalEnv)
assign("stl_results",   stl_results,   envir = .GlobalEnv)
message("\n✓ Trend analysis complete. Outputs saved to outputs/")
