# ============================================================
#  03_forecasting.R
#  ETS forecasting — next 4 quarters per district
# ============================================================

if (!exists("polio_df")) { source("R/01_load_clean.R"); source("R/02_trend_analysis.R") }
library(forecast); library(dplyr); library(tidyr); library(scales)

FORECAST_HORIZON <- 4   # quarters ahead

cat("\n── OPV3 Coverage Forecasts (Next", FORECAST_HORIZON, "Quarters) ──────\n")

forecast_list <- list()

for (dist in levels(polio_df$District)) {
  sub <- polio_df %>% filter(District == dist) %>% arrange(Date)

  ts_cov <- ts(sub$OPV3_Coverage, frequency = 4,
               start = c(min(sub$Year), min(sub$Quarter)))

  # Fit ETS model
  ets_fit  <- ets(ts_cov)
  fc       <- forecast(ets_fit, h = FORECAST_HORIZON)

  # Build forecast dates
  last_date <- max(sub$Date)
  fc_dates  <- seq(last_date %m+% months(3),
                   by = "3 months",
                   length.out = FORECAST_HORIZON)

  fc_df <- data.frame(
    District    = dist,
    Date        = fc_dates,
    Period      = paste0(format(fc_dates, "%Y"), "Q",
                         ceiling(as.integer(format(fc_dates, "%m")) / 3)),
    Forecast    = as.numeric(fc$mean),
    Lo80        = as.numeric(fc$lower[, 1]),
    Hi80        = as.numeric(fc$upper[, 1]),
    Lo95        = as.numeric(fc$lower[, 2]),
    Hi95        = as.numeric(fc$upper[, 2]),
    Model       = as.character(ets_fit),
    stringsAsFactors = FALSE
  )

  forecast_list[[dist]] <- fc_df

  cat(sprintf("\n  %s [%s]\n", dist, as.character(ets_fit)))
  print(fc_df %>%
    mutate(across(Forecast:Hi95, ~ percent(.x, accuracy = 0.1))) %>%
    select(Period, Forecast, Lo80, Hi80))
}

forecast_df <- bind_rows(forecast_list)

# ── AFP Forecasts ─────────────────────────────────────────────
cat("\n── AFP Case Forecasts ──────────────────────────────\n")
afp_fc_list <- list()

for (dist in levels(polio_df$District)) {
  sub <- polio_df %>% filter(District == dist) %>% arrange(Date)
  ts_afp  <- ts(sub$AFP_Cases, frequency = 4,
                start = c(min(sub$Year), min(sub$Quarter)))
  afp_fit <- ets(ts_afp)
  afp_fc  <- forecast(afp_fit, h = FORECAST_HORIZON)
  last_date <- max(sub$Date)
  fc_dates  <- seq(last_date %m+% months(3), by = "3 months",
                   length.out = FORECAST_HORIZON)
  afp_fc_list[[dist]] <- data.frame(
    District = dist, Date = fc_dates,
    AFP_Forecast = pmax(0, round(as.numeric(afp_fc$mean))),
    AFP_Lo80     = pmax(0, round(as.numeric(afp_fc$lower[,1]))),
    AFP_Hi80     = pmax(0, round(as.numeric(afp_fc$upper[,1])))
  )
  cat(sprintf("  %s: next 4-quarter AFP forecast: %s\n",
              dist, paste(pmax(0, round(as.numeric(afp_fc$mean))), collapse = ", ")))
}

afp_forecast_df <- bind_rows(afp_fc_list)

# ── Save ──────────────────────────────────────────────────────
if (!dir.exists("outputs")) dir.create("outputs")
write.csv(forecast_df,     "outputs/coverage_forecasts.csv", row.names = FALSE)
write.csv(afp_forecast_df, "outputs/afp_forecasts.csv",      row.names = FALSE)

assign("forecast_df",     forecast_df,     envir = .GlobalEnv)
assign("afp_forecast_df", afp_forecast_df, envir = .GlobalEnv)
message("\n✓ Forecasting complete. CSVs saved to outputs/")
