# ============================================================
#  04_visualizations.R
#  ggplot2 dashboard — 6 charts saved to outputs/
# ============================================================

if (!exists("forecast_df")) {
  source("R/01_load_clean.R")
  source("R/02_trend_analysis.R")
  source("R/03_forecasting.R")
}

pkgs <- c("ggplot2","dplyr","tidyr","scales","patchwork","ggrepel","lubridate")
new  <- pkgs[!pkgs %in% rownames(installed.packages())]
if (length(new)) install.packages(new, quiet = TRUE)
lapply(pkgs, library, character.only = TRUE)

if (!dir.exists("outputs")) dir.create("outputs")

# ── Palette ───────────────────────────────────────────────────
DISTRICT_COLORS <- c(
  "Accra Metro"  = "#1F497D",
  "Kumasi Metro" = "#70AD47",
  "Tamale Metro" = "#C00000"
)

THEME <- theme_minimal(base_family = "sans", base_size = 11) +
  theme(
    plot.title      = element_text(size = 12, face = "bold", color = "#1F497D"),
    plot.subtitle   = element_text(size = 9,  color = "#595959"),
    axis.title      = element_text(size = 9,  face = "bold"),
    axis.text.x     = element_text(angle = 45, hjust = 1, size = 7),
    panel.grid.minor = element_blank(),
    legend.position  = "bottom",
    legend.title     = element_blank(),
    strip.text       = element_text(face = "bold")
  )

# ── Plot 1: OPV3 Coverage with Trend + Forecast ───────────────
p1 <- ggplot(polio_df, aes(x = Date, y = OPV3_Coverage, color = District)) +
  # Forecast ribbon
  geom_ribbon(data = forecast_df,
              aes(y = Forecast, ymin = Lo95, ymax = Hi95, fill = District),
              alpha = 0.12, color = NA, show.legend = FALSE) +
  geom_ribbon(data = forecast_df,
              aes(y = Forecast, ymin = Lo80, ymax = Hi80, fill = District),
              alpha = 0.20, color = NA, show.legend = FALSE) +
  # Trend lines
  geom_line(aes(y = Coverage_Trend), linetype = "dashed", linewidth = 0.7, alpha = 0.7) +
  # Actual data
  geom_line(linewidth = 1.1) +
  geom_point(size = 2) +
  # Forecast lines
  geom_line(data = forecast_df, aes(y = Forecast), linetype = "dotdash", linewidth = 1) +
  geom_point(data = forecast_df, aes(y = Forecast), shape = 17, size = 2.5) +
  # 80% target line
  geom_hline(yintercept = 0.80, color = "grey40", linetype = "longdash", linewidth = 0.6) +
  annotate("text", x = as.Date("2018-01-01"), y = 0.815,
           label = "80% target", color = "grey40", size = 2.8, hjust = 0) +
  scale_color_manual(values = DISTRICT_COLORS) +
  scale_fill_manual(values  = DISTRICT_COLORS) +
  scale_y_continuous(labels = percent_format(accuracy = 1), limits = c(0.45, 1.0)) +
  scale_x_date(date_labels = "%YQ%q", date_breaks = "6 months",
               expand = expansion(mult = c(0.01, 0.08))) +
  labs(title    = "OPV3 Coverage Trend & Forecast (2018–2028)",
       subtitle  = "Dashed = linear trend | Triangles = ETS forecast | Bands = 80%/95% CI",
       x = NULL, y = "OPV3 Coverage Rate") +
  THEME

# ── Plot 2: AFP Cases Heatmap-style Bar ───────────────────────
p2 <- ggplot(polio_df, aes(x = Date, y = AFP_Cases, fill = District)) +
  geom_col(position = "dodge", width = 55, alpha = 0.85) +
  geom_line(aes(y = AFP_MA3, color = District), linewidth = 1, na.rm = TRUE) +
  scale_fill_manual(values  = DISTRICT_COLORS) +
  scale_color_manual(values = DISTRICT_COLORS) +
  scale_x_date(date_labels = "%YQ%q", date_breaks = "6 months") +
  labs(title    = "AFP Cases by District",
       subtitle  = "Bars = quarterly counts | Lines = 3-period moving average",
       x = NULL, y = "AFP Cases") +
  THEME

# ── Plot 3: Dropout Rate OPV1 → OPV3 ─────────────────────────
p3 <- ggplot(polio_df, aes(x = Date, y = Dropout_OPV1_OPV3, color = District)) +
  geom_area(aes(fill = District), alpha = 0.08, position = "identity") +
  geom_line(linewidth = 1.1) +
  geom_hline(yintercept = 0.10, color = "red", linetype = "dashed", linewidth = 0.7) +
  annotate("text", x = as.Date("2018-01-01"), y = 0.105,
           label = "10% alert", color = "red", size = 2.8, hjust = 0) +
  scale_color_manual(values = DISTRICT_COLORS) +
  scale_fill_manual(values  = DISTRICT_COLORS) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  scale_x_date(date_labels = "%YQ%q", date_breaks = "6 months") +
  labs(title    = "OPV1 → OPV3 Dropout Rate",
       subtitle  = "Children who started but did not complete the vaccine series",
       x = NULL, y = "Dropout Rate") +
  THEME

# ── Plot 4: Zero-Dose Children ────────────────────────────────
p4 <- ggplot(polio_df, aes(x = Date, y = Zero_Dose_Children, color = District)) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 1.8) +
  geom_smooth(method = "lm", se = FALSE, linetype = "dashed",
              linewidth = 0.6, alpha = 0.5) +
  scale_color_manual(values = DISTRICT_COLORS) +
  scale_y_continuous(labels = comma) +
  scale_x_date(date_labels = "%YQ%q", date_breaks = "6 months") +
  labs(title    = "Zero-Dose Children per Quarter",
       subtitle  = "Children who received no OPV dose — priority for outreach",
       x = NULL, y = "Zero-Dose Children") +
  THEME

# ── Plot 5: Annual Coverage Facets ────────────────────────────
annual_cov <- polio_df %>%
  mutate(Year = factor(Year)) %>%
  group_by(District, Year) %>%
  summarise(Avg_Coverage = mean(OPV3_Coverage), .groups = "drop")

p5 <- ggplot(annual_cov, aes(x = Year, y = Avg_Coverage, fill = District)) +
  geom_col(position = "dodge", width = 0.7, alpha = 0.9) +
  geom_hline(yintercept = 0.80, color = "red", linetype = "dashed", linewidth = 0.7) +
  scale_fill_manual(values = DISTRICT_COLORS) +
  scale_y_continuous(labels = percent_format(accuracy = 1), limits = c(0, 1)) +
  labs(title    = "Annual Average OPV3 Coverage by Year",
       subtitle  = "Red dashed line = 80% target",
       x = "Year", y = "Avg OPV3 Coverage") +
  THEME

# ── Plot 6: Faceted STL Decomposition ────────────────────────
stl_long <- bind_rows(lapply(names(stl_results), function(dist) {
  comp <- stl_results[[dist]]$time.series
  sub  <- polio_df %>% filter(District == dist) %>% arrange(Date)
  data.frame(
    District  = dist,
    Date      = sub$Date,
    Observed  = sub$OPV3_Coverage,
    Trend     = as.numeric(comp[, "trend"]),
    Seasonal  = as.numeric(comp[, "seasonal"]),
    Remainder = as.numeric(comp[, "remainder"])
  )
})) %>%
  pivot_longer(Observed:Remainder, names_to = "Component", values_to = "Value") %>%
  mutate(Component = factor(Component,
                            levels = c("Observed","Trend","Seasonal","Remainder")))

p6 <- ggplot(stl_long, aes(x = Date, y = Value, color = District)) +
  geom_line(linewidth = 0.8) +
  facet_grid(Component ~ ., scales = "free_y") +
  scale_color_manual(values = DISTRICT_COLORS) +
  scale_x_date(date_labels = "%Y", date_breaks = "1 year") +
  labs(title    = "STL Decomposition — OPV3 Coverage",
       subtitle  = "Observed = Trend + Seasonal + Remainder",
       x = NULL, y = NULL) +
  THEME + theme(axis.text.x = element_text(angle = 0, hjust = 0.5))

# ── Save Individual Plots ─────────────────────────────────────
ggsave("outputs/p1_coverage_forecast.png", p1, width = 12, height = 6,  dpi = 150)
ggsave("outputs/p2_afp_cases.png",         p2, width = 12, height = 6,  dpi = 150)
ggsave("outputs/p3_dropout_rate.png",      p3, width = 12, height = 6,  dpi = 150)
ggsave("outputs/p4_zero_dose.png",         p4, width = 12, height = 6,  dpi = 150)
ggsave("outputs/p5_annual_coverage.png",   p5, width = 10, height = 6,  dpi = 150)
ggsave("outputs/p6_stl_decomposition.png", p6, width = 12, height = 10, dpi = 150)

# ── Combined Dashboard ────────────────────────────────────────
dashboard <- (p1 + p2) / (p3 + p4) / (p5 + p6) +
  plot_annotation(
    title    = "Ghana Polio Immunization Analysis Dashboard",
    subtitle = "Accra Metro · Kumasi Metro · Tamale Metro | 2018Q1 – 2024Q4 | Source: DHIS2",
    theme = theme(
      plot.title    = element_text(size = 16, face = "bold", color = "#1F497D"),
      plot.subtitle = element_text(size = 11, color = "#595959")
    )
  )

ggsave("outputs/dashboard_full.png", dashboard, width = 18, height = 20, dpi = 150)
message("✓ All plots saved to outputs/")
message("  → outputs/dashboard_full.png  (full dashboard)")
