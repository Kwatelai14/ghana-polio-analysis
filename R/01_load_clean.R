# ============================================================
#  01_load_clean.R
#  Load DHIS2 export, clean and prepare data
#  Ghana Polio Analysis: Accra, Kumasi, Tamale (2018-2024)
# ============================================================

# ── Packages ──────────────────────────────────────────────────
pkgs <- c("readxl","dplyr","tidyr","lubridate","zoo","scales")
new  <- pkgs[!pkgs %in% rownames(installed.packages())]
if (length(new)) install.packages(new, quiet = TRUE)
lapply(pkgs, library, character.only = TRUE)

# ── Config ────────────────────────────────────────────────────
USE_API      <- FALSE   # Set TRUE to pull from DHIS2 API
DATA_FILE    <- here::here("data", "Polio_DHIS2_Ghana_Districts.xlsx")

DHIS2_BASE_URL <- "https://your-instance.dhis2.org"
DHIS2_USERNAME <- "your_username"
DHIS2_PASSWORD <- "your_password"

DISTRICTS <- c("Accra Metro", "Kumasi Metro", "Tamale Metro")

# ── Load ──────────────────────────────────────────────────────
if (USE_API) {
  library(httr)
  message("Pulling data from DHIS2 API...")
  resp <- GET(
    paste0(DHIS2_BASE_URL, "/api/analytics.json"),
    authenticate(DHIS2_USERNAME, DHIS2_PASSWORD),
    query = list(
      dimension = "dx:OPV0;OPV1;OPV2;OPV3;AFP;ZeroDose",
      dimension = "pe:2018Q1;2018Q2;2018Q3;2018Q4;2019Q1;2019Q2;2019Q3;2019Q4;2020Q1;2020Q2;2020Q3;2020Q4;2021Q1;2021Q2;2021Q3;2021Q4;2022Q1;2022Q2;2022Q3;2022Q4;2023Q1;2023Q2;2023Q3;2023Q4;2024Q1;2024Q2;2024Q3;2024Q4",
      dimension = "ou:AccraMetroUID;KumasiMetroUID;TamaleMetroUID",
      displayProperty = "NAME"
    )
  )
  stop_for_status(resp)
  raw <- content(resp, "parsed")
  df_raw <- as.data.frame(do.call(rbind, raw$rows))
  colnames(df_raw) <- unlist(raw$headers)[seq(1, length(unlist(raw$headers)), 2)]
} else {
  message("Loading from local Excel file: ", DATA_FILE)
  df_raw <- read_excel(DATA_FILE, sheet = "DHIS2_Raw_Data")
}

# ── Clean & Engineer Features ─────────────────────────────────
df <- df_raw %>%
  filter(District %in% DISTRICTS) %>%
  mutate(
    # Parse DHIS2 period
    Year    = as.integer(substr(Period, 1, 4)),
    Quarter = as.integer(substr(Period, 6, 6)),
    Date    = as.Date(paste0(Year, "-", sprintf("%02d", (Quarter - 1) * 3 + 1), "-01")),

    # Coverage rates
    OPV0_Coverage = OPV0_Doses / Target_Children,
    OPV1_Coverage = OPV1_Doses / Target_Children,
    OPV2_Coverage = OPV2_Doses / Target_Children,
    OPV3_Coverage = OPV3_Doses / Target_Children,

    # Dropout rates
    Dropout_OPV1_OPV3 = (OPV1_Doses - OPV3_Doses) / OPV1_Doses,
    Dropout_OPV1_OPV2 = (OPV1_Doses - OPV2_Doses) / OPV1_Doses,

    # Zero-dose rate
    Zero_Dose_Rate = Zero_Dose_Children / Target_Children,

    # District as ordered factor
    District = factor(District, levels = DISTRICTS)
  ) %>%
  arrange(District, Date) %>%
  group_by(District) %>%
  mutate(
    # Rolling 3-period moving averages
    AFP_MA3          = rollmean(AFP_Cases,        k = 3, fill = NA, align = "right"),
    OPV3_Coverage_MA = rollmean(OPV3_Coverage,    k = 3, fill = NA, align = "right"),
    ZeroDose_MA3     = rollmean(Zero_Dose_Children,k = 3, fill = NA, align = "right"),

    # Numeric time index per district (for regression)
    Time = row_number()
  ) %>%
  ungroup()

message(sprintf("✓ Loaded %d records | %d districts | %d periods",
                nrow(df), n_distinct(df$District), n_distinct(df$Period)))
message(sprintf("  Period range: %s to %s", min(df$Period), max(df$Period)))

# ── Quick Validation ──────────────────────────────────────────
stopifnot(all(df$OPV3_Coverage > 0 & df$OPV3_Coverage < 1))
stopifnot(all(df$Dropout_OPV1_OPV3 >= 0))

# Make available to subsequent scripts
assign("polio_df", df, envir = .GlobalEnv)
message("✓ Data ready in 'polio_df'")
