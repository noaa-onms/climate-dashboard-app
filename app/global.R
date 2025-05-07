# TODO:
# - [ ] Overview cards with [plot_hist](https://github.com/tbep-tech/climate-change-indicators/blob/ab36910dd002bd2b0dfc29abf6c18dbb043880a7/app/functions.R#L301-L411)

librarian::shelf(
  bsicons, bslib, dplyr, glue, here, htmltools, leaflet, leaflet.extras2,
  lubridate, markdown, plotly, purrr,
  readr, scales, sf, shiny, slider,
  terra, thematic, tibble, tidyr)
source(here("app/functions.R"))
options(readr.show_col_types = F)

# themes ----
sldr_css <- "
  .irs-grid-text {
    font-size: 12px !important; }  /* default: 9px */
  .irs-from, .irs-to, .irs-single {
    font-size: 16px !important;    /* default: 11px  */
    line-height:  1 !important; }  /* default: 1.333 */
  .irs-min, .irs-max {
    font-size: 14px !important;    /* default: 10px  */
    line-height:  1 !important;}   /* default: 1.333 */"
font_scale <- 1.3
light <- bs_theme(
  preset     = "flatly",
  font_scale = font_scale) |>
  bs_add_rules(sldr_css)
dark  <- bs_theme(
  preset     = "darkly",
  font_scale = font_scale) |>
  bs_add_rules(sldr_css)

sanctuaries <- readRDS(here("../climate-dashboard/data/sanctuaries.rds"))

choices_nms <- sanctuaries |>
  st_drop_geometry() |>
  arrange(sanctuary) |>
  deframe()

d_vars <- tribble(
  ~var      ,  ~label,                          ~lbl,
  # "erddap_DHW",  "Sea Surface Temperature (SST)", "SST (°C)",
  "erddap_sst",  "Sea Surface Temperature (SST)", "SST (°C)",
  # "erddap_SMOS", "Sea Surface Salinity (SSS)",    "SSS (PSU)",
  "erddap_sss",  "Sea Surface Salinity (SSS)",    "SSS (PSU)")
var_label   <- select(d_vars, var, label) |> deframe()
var_lbl     <- select(d_vars, var, lbl)   |> deframe()
choices_var <- select(d_vars, label, var) |> deframe()

selected_nms = "FKNMS"
selected_var = "erddap_sst"
# DEBUG
# selected_nms = "CBNMS"
# selected_var = "erddap_sst"

# read_csv("data/erddap_sst/FKNMS/2025.csv") |>
#   arrange(time) |>
#   tail(1)
# 2025-04-28 12:00:00

