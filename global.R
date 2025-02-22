# TODO:
# - [ ] Overview cards with [plot_hist](https://github.com/tbep-tech/climate-change-indicators/blob/ab36910dd002bd2b0dfc29abf6c18dbb043880a7/app/functions.R#L301-L411)

librarian::shelf(
  bsicons, bslib, dplyr, glue, here, htmltools, leaflet, leaflet.extras2,
  lubridate, markdown, plotly, purrr, readr, scales, sf, shiny, slider,
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


# TODO: load in all datasets here and include necessary data for server.R
#       like `var  = "CRW_SST"` and `var_lbl    = "SST (°C)"`
# sst ----
dir_sst <- here("data/NOAA_DHW")
dir_sss <- here("data/NOAA_SMOS")

d_sst <- tibble(
  csv = list.files(dir_sst, ".csv$", recursive = T, full.names = T)) |>
  mutate(
    nms  = basename(dirname(csv)),
    data = map(csv, \(x) read_csv(x) |> select(-any_of("nms")))) |> # TODO: sanctuary nms zone/sf_zone in exract_ed()?
  unnest(data) |>
  mutate(
    date = as.Date(time)) |>
  arrange(time) |>
  filter(year(time) >= 1987)

d_sss <- tibble(
  csv = list.files(dir_sss, ".csv$", recursive = T, full.names = T)) |>
  mutate(
    nms  = basename(dirname(csv)),
    data = map(csv, \(x) read_csv(x) |> select(-any_of("nms")))) |> # TODO: sanctuary nms zone/sf_zone in exract_ed()?
  unnest(data) |>
  mutate(
    date = as.Date(time)) |>
  arrange(time) |>
  filter(year(time) >= 1987)

# TODO: sanctuary nms   lyr     val var

# d_sst |>
#   mutate(
#     yr = year(time)) |>
#   group_by(nms, yr) |>
#   summarize(
#     n    = n(),
#     n_na = sum(is.na(mean)),
#     mean = mean(mean, na.rm = T)) |>
#   filter(n_na > 0)
# A tibble: 4 × 5
# Groups:   nms [2]
#   nms      yr     n  n_na  mean
#   <chr> <dbl> <int> <int> <dbl>
# 1 CINMS  1985   365   365   NaN
# 2 CINMS  1986   365   365   NaN
# 3 FKNMS  1985   365   365   NaN
# 4 FKNMS  1986   365   365   NaN

yrs_sst <- range(year(d_sst$date))
# now_sst <- max(d_sst$date)
# TODO: fix so gets max based on sanctuary
now_sst <- as.Date("2024-08-05")

sanctuaries <- readRDS(here("../climate-dashboard/data/sanctuaries.rds"))
