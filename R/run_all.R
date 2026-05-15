# ============================================================
#  run_all.R  —  Master script
#  Ghana Polio Analysis: Accra, Kumasi, Tamale (2018–2024)
#  Run this file to execute the full pipeline.
# ============================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("  🇬🇭 Ghana Polio DHIS2 Analysis Pipeline\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

# Ensure working directory is project root
if (!file.exists("data/Polio_DHIS2_Ghana_Districts.xlsx")) {
  stop("Run this script from the project root directory:\n",
       "  setwd('/path/to/ghana-polio-analysis')\n",
       "  source('R/run_all.R')")
}

# Install/load 'here' for path management
if (!"here" %in% rownames(installed.packages())) install.packages("here", quiet = TRUE)
library(here)

t_start <- Sys.time()

cat("\n[1/4] Loading and cleaning data...\n")
source(here("R", "01_load_clean.R"))

cat("\n[2/4] Running trend analysis...\n")
source(here("R", "02_trend_analysis.R"))

cat("\n[3/4] Forecasting next 4 quarters...\n")
source(here("R", "03_forecasting.R"))

cat("\n[4/4] Generating visualizations...\n")
source(here("R", "04_visualizations.R"))

t_end <- Sys.time()
elapsed <- round(difftime(t_end, t_start, units = "secs"), 1)

cat("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat(sprintf("  ✅ Pipeline complete in %s seconds\n", elapsed))
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\nOutputs:\n")
for (f in list.files("outputs", full.names = TRUE)) {
  cat(sprintf("  • %s\n", f))
}
