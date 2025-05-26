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
  ~var            ,  ~variable_id, ~provider   , ~label                         , ~lbl,
  "erddap_sst"    ,  NA          , "NOAA"      , "Sea surface temperature (SST)", "SST (°C)",
  "erddap_sss"    ,  NA          , "NOAA"      , "Sea surface salinity (SSS)"   , "SSS (g/kg)",
  "copernicus_phy",  "mlotst"    , "Copernicus", "Mixed layer thickness (MLT)"  , "MLT (m)",
  "copernicus_phy",  "thetao"    , "Copernicus", "Sea surface temperature (SST)", "SST (°C)",
  "copernicus_phy",  "bottomT"   , "Copernicus", "Sea bottom temperature (SST)" , "SBT (°C)",
  "copernicus_phy",  "so"        , "Copernicus", "Sea surface salinity (SSS)"   , "SSS (g/kg)")

# TODO: add color gradient
var_label   <- select(d_vars, var, label) |> deframe()
var_lbl     <- select(d_vars, var, lbl)   |> deframe()
# choices_var <- select(d_vars, label, var) |> deframe()
choices_var <- d_vars |>
  select(provider, label, var) |>
  nest(.by = provider) |>
  mutate(
    data = map(data, deframe)) |>
  deframe()

selected_nms = "FKNMS"
# selected_var = "erddap_sst"
selected_var = "copernicus_phy_bottomT"

# DEBUG
# selected_nms = "CBNMS"
# selected_var = "erddap_sst"
#
# read_csv("data/erddap_sst/HIHWNMS/2025.csv") |>
#   arrange(time) |>
#   tail(1)
# 2025-04-28 12:00:00

