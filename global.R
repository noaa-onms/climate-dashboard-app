# TODO:
# - [ ] Overview cards with [plot_hist](https://github.com/tbep-tech/climate-change-indicators/blob/ab36910dd002bd2b0dfc29abf6c18dbb043880a7/app/functions.R#L301-L411)

librarian::shelf(
  bsicons, bslib, dplyr, glue, here, htmltools, leaflet, leaflet.extras2,
  lubridate, markdown, plotly, purrr,
  readr, scales, sf, shiny, slider,
  terra, thematic, tibble, tidyr)
source(here("functions.R"))
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
selected_nms = "FKNMS"

choices_var <- c(
    "Sea Surface Temperature (SST)" = "NOAA_DHW",
    "Sea Surface Salinity (SSS)"    = "NOAA_SMOS")
selected_var = "NOAA_DHW"
