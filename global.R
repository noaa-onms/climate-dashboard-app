# TODO:
# - [ ] Overview cards with [plot_hist](https://github.com/tbep-tech/climate-change-indicators/blob/ab36910dd002bd2b0dfc29abf6c18dbb043880a7/app/functions.R#L301-L411)

librarian::shelf(
  bsicons, bslib, dplyr, glue, here, htmltools, leaflet, leaflet.extras2,
  lubridate, markdown, plotly, purrr, readr, scales, sf, shiny, slider,
  terra, thematic, tibble, tidyr)
source(here("functions.R"))
options(readr.show_col_types = F)

# themes ----
light <- bs_theme(
  preset    = "flatly",
  base_font = font_google("Playwright+MX"))
dark  <- bs_theme(preset = "darkly")

# sst ----
dir_sst <- here("data/NOAA_DHW")

d_sst <- tibble(
  csv = list.files(dir_sst, ".csv$", recursive = T, full.names = T)) |>
  mutate(
    data = map(csv, read_csv)) |>
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
now_sst <- max(d_sst$date)

sanctuaries <- readRDS(here("../climate-dashboard/data/sanctuaries.rds"))
