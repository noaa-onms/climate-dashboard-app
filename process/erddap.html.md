---
title: "ERDDAP Data Extraction"
params:
  data_var: erddap_sss
  erddap_url: https://coastwatch.noaa.gov/erddap/griddap/noaacwSMOSsss3day.html
  erddap_variable: sss
  # data_var: erddap_sst
  # erddap_url: https://coastwatch.noaa.gov/erddap/griddap/noaacrwsstDaily.html
  # erddap_variable: analysed_sst
---




## Setup with `extractr`



::: {.cell}

```{.r .cell-code}
# dir_extractr = "/share/github/marinebon/extractr" # dir_extractr = "~/Github/marinebon/extractr"
# devtools::load_all(dir_extractr)
# devtools::install_local(dir_extractr, force = T)
# devtools::install_github("marinebon/extractr", force = T)
librarian::shelf(
  dplyr, DT, glue, here, logger, lubridate, mapview, purrr, readr, sf, stringr,
  terra,
  marinebon/extractr)
options(readr.show_col_types = F)

ply_sanctuaries <- readRDS(here("../climate-dashboard/data/sanctuaries.rds")) |> 
    filter(!nms %in% c("GRNMS","MNMS")) # DEBUG

# TODO: expand poly to get results
# ply_small <- ply_sanctuaries |> 
#   filter(nms %in% c("GRNMS","")) |> 
  # st_buffer()
  # filter(nms != "HIHWNMS")  # TODO: sort dateline sanctuary later

# mapView(sanctuaries)
# sanctuaries |>
#   st_drop_geometry() |>
#   datatable()

dir_out <- here(glue("data/{params$data_var}"))
dir.create(dir_out, showWarnings = F, recursive = T)
```
:::



## Dataset info



::: {.cell}

```{.r .cell-code}
(ed <- ed_info(params$erddap_url))
```

::: {.cell-output .cell-output-stdout}

```
<ERDDAP info> noaacrwsstDaily 
 Base URL: https://coastwatch.noaa.gov/erddap 
 Dataset Type: griddap 
 Dimensions (range):  
     time: (1985-01-01T12:00:00Z, 2025-05-15T12:00:00Z) 
     latitude: (-89.975, 89.975) 
     longitude: (-179.975, 179.975) 
 Variables:  
     analysed_sst: 
         Units: degree_C 
     sea_ice_fraction: 
         Units: 1 
```


:::

```{.r .cell-code}
times <- ed_dim(ed, "time")
(v <- params$erddap_variable)
```

::: {.cell-output .cell-output-stdout}

```
[1] "analysed_sst"
```


:::
:::



## Setup iteration: sanctuary years



::: {.cell}

```{.r .cell-code}
d_nms_yr_todo <- ply_sanctuaries |> 
  st_drop_geometry() |> 
  arrange(nms) |> 
  select(nms) |> 
  cross_join(
    tibble(
      year = year(min(times)):year(max(times)))) |> 
  mutate(
    d = map2(nms, year, \(nms, year) { # nms = "TBNMS"; year = 2025
      times_yr <- times[year(times) == year]
      csv <- glue("{dir_out}/{nms}/{year}.csv")
      
      # time[1] if missing csv
      if (!file.exists(csv))
        return(list(
          n_times  = length(times_yr),
          time_min = times_yr[1]))
      
      times_csv <- read_csv(csv) |> 
        pull(time)
      # NA if all times done
      if (all(times_yr %in% times_csv))
        return(list(
          n_times  = 0,
          time_min = NA)) 
      
      # earliest time missing otherwise
      i <- !times_yr %in% times_csv
      list(
          n_times  = sum(i),
          time_min = min(times_yr[i])) }),
    n_times  = map_int(d, pluck, "n_times"),
    time_min = map_dbl(d, pluck, "time_min") |> 
      as.POSIXct() ) |> 
  filter(n_times > 0) |> 
  select(-d) |> 
  mutate(
    i = 1:n()) |> 
  relocate(i)

d_nms_yr_todo |> 
  group_by(nms) |>
  summarize(
    n_times  = sum(n_times),
    time_min = min(time_min)) |>
  datatable(
    caption  = "Sanctuaries missing available ERDDAP times.",
    rownames = F,
    options  = list(
      pageLength = 5,
      lengthMenu = c(5, 50, nrow(d_nms_yr_todo))))
```

::: {.cell-output-display}


```{=html}
<div class="datatables html-widget html-fill-item" id="htmlwidget-20bae86c5bfd4a5e94e3" style="width:100%;height:auto;"></div>
<script type="application/json" data-for="htmlwidget-20bae86c5bfd4a5e94e3">{"x":{"filter":"none","vertical":false,"caption":"<caption>Sanctuaries missing available ERDDAP times.<\/caption>","data":[["CBNMS","CINMS","CPNMS","FGBNMS","FKNMS","GFNMS","HIHWNMS","MBNMS","MBNMS-david","MBNMS-main","NMSAS","OCNMS","SBNMS","TBNMS"],[1,1,1,1,1,1,110,1,1,1,121,1,1,1],["2025-05-15T12:00:00Z","2025-05-15T12:00:00Z","2025-05-15T12:00:00Z","2025-05-15T12:00:00Z","2025-05-15T12:00:00Z","2025-05-15T12:00:00Z","2025-01-01T12:00:00Z","2025-05-15T12:00:00Z","2025-05-15T12:00:00Z","2025-05-15T12:00:00Z","2025-01-01T12:00:00Z","2025-05-15T12:00:00Z","2025-05-15T12:00:00Z","2025-05-15T12:00:00Z"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th>nms<\/th>\n      <th>n_times<\/th>\n      <th>time_min<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"pageLength":5,"lengthMenu":[5,50,14],"columnDefs":[{"className":"dt-right","targets":1},{"name":"nms","targets":0},{"name":"n_times","targets":1},{"name":"time_min","targets":2}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script>
```


:::
:::



## Iterate over sanctuary years



::: {.cell}

```{.r .cell-code}
# rerddap::cache_delete_all()

fxn <- function(i, nms, time_min, ...){
  #  nms = "GRNMS"; year = 2010 ; i = 97    # DEBUG

 err <- tryCatch({
    
    log_info("{sprintf('%03d', i)}: {nms}, {time_min}")

    yr       <- year(time_min)
    time_max <- max(times[year(times) == yr])
    
    ply <- ply_sanctuaries |>
      filter(nms == !!nms)
    # TODO: consider expanding by 10% and rounding 2 digits
    # bb <- st_bbox(ply) |> stars:::bb_shrink(-0.1) |> round(2)
    
    extractr::ed_extract(
      ed,
      var       = v,
      sf_zones  = ply,
      mask_tif  = T,
      rast_tif  = glue::glue("{dir_out}/{nms}/{yr}.tif"),
      zonal_fun = "mean",
      zonal_csv = glue::glue("{dir_out}/{nms}/{yr}.csv"),
      dir_nc    = glue::glue("{dir_out}/{nms}/{yr}_nc"),
      keep_nc   = F,
      n_max_vals_per_req = 1e+05,
      time_min  = time_min,
      time_max  = time_max)
    
    return(NA)
  }, error = function(e) {
    
    log_error(conditionMessage(e))
    return(conditionMessage(e))
  })
 
 err
} 

res <- d_nms_yr_todo |> 
  # slice(1:3) |>  # DEBUG
  mutate(
    error = pmap_chr(list(i, nms, time_min), fxn))
```
:::



### Successes



::: {.cell}

```{.r .cell-code}
res |> 
  mutate(
    success = is.na(error)) |> 
  group_by(success) |> 
  summarize(
    n = n()) |> 
  datatable()
```

::: {.cell-output-display}


```{=html}
<div class="datatables html-widget html-fill-item" id="htmlwidget-aa11caa799376e539acf" style="width:100%;height:auto;"></div>
<script type="application/json" data-for="htmlwidget-aa11caa799376e539acf">{"x":{"filter":"none","vertical":false,"data":[["1"],[true],[14]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>success<\/th>\n      <th>n<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":2},{"orderable":false,"targets":0},{"name":" ","targets":0},{"name":"success","targets":1},{"name":"n","targets":2}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script>
```


:::
:::



### Errors (if any)



::: {.cell}

```{.r .cell-code}
res |> 
  filter(!is.na(error)) |> 
  group_by(nms) |> 
  summarize(
    n_years = n(),
    errors  = unique(error) |> paste(collapse = "\n\n----\n\n")) |> 
  datatable()
```

::: {.cell-output-display}


```{=html}
<div class="datatables html-widget html-fill-item" id="htmlwidget-b0c295c1cb6df6a000b4" style="width:100%;height:auto;"></div>
<script type="application/json" data-for="htmlwidget-b0c295c1cb6df6a000b4">{"x":{"filter":"none","vertical":false,"data":[[],[],[],[]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>nms<\/th>\n      <th>n_years<\/th>\n      <th>errors<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":2},{"orderable":false,"targets":0},{"name":" ","targets":0},{"name":"nms","targets":1},{"name":"n_years","targets":2},{"name":"errors","targets":3}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script>
```


:::
:::



## TODO

`ed_extract()`:

- [x] delete *_nc dir
- [x] differentiate existing done vs todo for given year
- [ ] allow irregular datasets, like `meta/irregular/*.yaml`: `ERROR: x cell sizes are not regular`
- [ ] break up into functions, not exported

`erddap.qmd`:

- [ ] make `ed_extract()` to single MBNMS with features for main vs david; add "ALL" option to `ed_extract()`
- [ ] add buffer to all (and redo)
- [ ] wrap retry with `ed_dim()` too



::: {.cell}

:::



## R package versions



::: {.cell}

```{.r .cell-code}
devtools::session_info()
```

::: {.cell-output .cell-output-stdout}

```
─ Session info ───────────────────────────────────────────────────────────────
 setting  value
 version  R version 4.4.2 (2024-10-31)
 os       Ubuntu 24.04.1 LTS
 system   x86_64, linux-gnu
 ui       X11
 language (EN)
 collate  en_US.UTF-8
 ctype    en_US.UTF-8
 tz       Etc/UTC
 date     2025-05-17
 pandoc   3.5 @ /usr/bin/ (via rmarkdown)

─ Packages ───────────────────────────────────────────────────────────────────
 package         * version date (UTC) lib source
 base64enc         0.1-3   2015-07-28 [1] RSPM (R 4.4.0)
 bit               4.6.0   2025-03-06 [1] RSPM (R 4.4.0)
 bit64             4.6.0-1 2025-01-16 [1] RSPM (R 4.4.0)
 bslib             0.9.0   2025-01-30 [1] RSPM (R 4.4.0)
 cachem            1.1.0   2024-05-16 [1] RSPM (R 4.4.0)
 class             7.3-22  2023-05-03 [2] CRAN (R 4.4.2)
 classInt          0.4-11  2025-01-08 [1] RSPM (R 4.4.0)
 cli               3.6.5   2025-04-23 [1] RSPM (R 4.4.0)
 codetools         0.2-20  2024-03-31 [2] CRAN (R 4.4.2)
 colorspace        2.1-1   2024-07-26 [1] RSPM (R 4.4.0)
 crayon            1.5.3   2024-06-20 [1] RSPM (R 4.4.0)
 crosstalk         1.2.1   2023-11-23 [1] RSPM (R 4.4.0)
 crul              1.5.0   2024-07-19 [1] RSPM (R 4.4.0)
 curl              6.2.2   2025-03-24 [1] RSPM (R 4.4.0)
 data.table        1.17.0  2025-02-22 [1] RSPM (R 4.4.0)
 DBI               1.2.3   2024-06-02 [1] RSPM (R 4.4.0)
 deldir            2.0-4   2024-02-28 [1] RSPM (R 4.4.0)
 devtools          2.4.5   2022-10-11 [1] RSPM (R 4.4.0)
 dichromat         2.0-0.1 2022-05-02 [1] RSPM (R 4.4.0)
 digest            0.6.37  2024-08-19 [1] RSPM (R 4.4.0)
 dplyr           * 1.1.4   2023-11-17 [1] RSPM (R 4.4.0)
 DT              * 0.33    2024-04-04 [1] RSPM (R 4.4.0)
 dygraphs          1.1.1.6 2018-07-11 [1] RSPM (R 4.4.0)
 e1071             1.7-16  2024-09-16 [1] RSPM (R 4.4.0)
 ellipsis          0.3.2   2021-04-29 [1] RSPM (R 4.4.0)
 evaluate          1.0.3   2025-01-10 [1] RSPM (R 4.4.0)
 extractr        * 0.1.5   2025-05-06 [1] Github (marinebon/extractr@b01398a)
 farver            2.1.2   2024-05-13 [1] RSPM (R 4.4.0)
 fastmap           1.2.0   2024-05-15 [1] RSPM (R 4.4.0)
 fs                1.6.6   2025-04-12 [1] RSPM (R 4.4.0)
 generics          0.1.3   2022-07-05 [1] RSPM (R 4.4.0)
 glue            * 1.8.0   2024-09-30 [1] RSPM (R 4.4.0)
 here            * 1.0.1   2020-12-13 [1] RSPM (R 4.4.0)
 hms               1.1.3   2023-03-21 [1] RSPM (R 4.4.0)
 hoardr            0.5.5   2025-01-18 [1] RSPM (R 4.4.0)
 htmltools         0.5.8.1 2024-04-04 [1] RSPM (R 4.4.0)
 htmlwidgets       1.6.4   2023-12-06 [1] RSPM (R 4.4.0)
 httpcode          0.3.0   2020-04-10 [1] RSPM (R 4.4.0)
 httpuv            1.6.16  2025-04-16 [1] RSPM (R 4.4.0)
 jquerylib         0.1.4   2021-04-26 [1] RSPM (R 4.4.0)
 jsonlite          2.0.0   2025-03-27 [1] RSPM (R 4.4.0)
 KernSmooth        2.23-24 2024-05-17 [2] CRAN (R 4.4.2)
 knitr             1.50    2025-03-16 [1] RSPM (R 4.4.0)
 later             1.4.2   2025-04-08 [1] RSPM (R 4.4.0)
 lattice           0.22-6  2024-03-20 [2] CRAN (R 4.4.2)
 leafem            0.2.4   2025-05-01 [1] RSPM (R 4.4.0)
 leaflet           2.2.2   2024-03-26 [1] RSPM (R 4.4.0)
 librarian         1.8.1   2021-07-12 [1] RSPM (R 4.4.0)
 lifecycle         1.0.4   2023-11-07 [1] RSPM (R 4.4.0)
 logger          * 0.4.0   2024-10-22 [1] RSPM (R 4.4.0)
 lubridate       * 1.9.4   2024-12-08 [1] RSPM (R 4.4.0)
 magrittr          2.0.3   2022-03-30 [1] RSPM (R 4.4.0)
 mapview         * 2.11.2  2023-10-13 [1] RSPM (R 4.4.0)
 Matrix            1.7-1   2024-10-18 [2] CRAN (R 4.4.2)
 memoise           2.0.1   2021-11-26 [1] RSPM (R 4.4.0)
 mime              0.13    2025-03-17 [1] RSPM (R 4.4.0)
 miniUI            0.1.1.1 2018-05-18 [1] RSPM (R 4.4.0)
 ncdf4             1.24    2025-03-25 [1] RSPM (R 4.4.0)
 pillar            1.10.2  2025-04-05 [1] RSPM (R 4.4.0)
 pkgbuild          1.4.5   2024-10-28 [1] RSPM (R 4.4.0)
 pkgconfig         2.0.3   2019-09-22 [1] RSPM (R 4.4.0)
 pkgload           1.4.0   2024-06-28 [1] RSPM (R 4.4.0)
 png               0.1-8   2022-11-29 [1] RSPM (R 4.4.0)
 polyclip          1.10-7  2024-07-23 [1] RSPM (R 4.4.0)
 profvis           0.4.0   2024-09-20 [1] RSPM (R 4.4.0)
 promises          1.3.2   2024-11-28 [1] RSPM (R 4.4.0)
 proxy             0.4-27  2022-06-09 [1] RSPM (R 4.4.0)
 purrr           * 1.0.4   2025-02-05 [1] RSPM (R 4.4.0)
 R.methodsS3       1.8.2   2022-06-13 [1] RSPM (R 4.4.0)
 R.oo              1.27.1  2025-05-02 [1] RSPM (R 4.4.0)
 R.utils           2.13.0  2025-02-24 [1] RSPM (R 4.4.0)
 R6                2.6.1   2025-02-15 [1] RSPM (R 4.4.0)
 rappdirs          0.3.3   2021-01-31 [1] RSPM (R 4.4.0)
 raster            3.6-32  2025-03-28 [1] RSPM (R 4.4.0)
 RColorBrewer      1.1-3   2022-04-03 [1] RSPM (R 4.4.0)
 Rcpp              1.0.14  2025-01-12 [1] RSPM (R 4.4.0)
 readr           * 2.1.5   2024-01-10 [1] RSPM (R 4.4.0)
 remotes           2.5.0   2024-03-17 [1] RSPM (R 4.4.0)
 rerddap           1.2.1   2025-03-19 [1] RSPM (R 4.4.0)
 rlang             1.1.6   2025-04-11 [1] RSPM (R 4.4.0)
 rmarkdown         2.29    2024-11-04 [1] RSPM (R 4.4.0)
 rprojroot         2.0.4   2023-11-05 [1] RSPM (R 4.4.0)
 rstudioapi        0.17.1  2024-10-22 [1] RSPM (R 4.4.0)
 sass              0.4.10  2025-04-11 [1] RSPM (R 4.4.0)
 satellite         1.0.5   2024-02-10 [1] RSPM (R 4.4.0)
 scales            1.4.0   2025-04-24 [1] RSPM (R 4.4.0)
 sessioninfo       1.2.2   2021-12-06 [1] RSPM (R 4.4.0)
 sf              * 1.0-20  2025-03-24 [1] RSPM (R 4.4.0)
 shiny             1.9.1   2024-08-01 [1] RSPM (R 4.4.0)
 sp                2.2-0   2025-02-01 [1] RSPM (R 4.4.0)
 spatstat.data     3.1-6   2025-03-17 [1] RSPM (R 4.4.0)
 spatstat.geom     3.3-6   2025-03-18 [1] RSPM (R 4.4.0)
 spatstat.univar   3.1-2   2025-03-05 [1] RSPM (R 4.4.0)
 spatstat.utils    3.1-3   2025-03-15 [1] RSPM (R 4.4.0)
 stringi           1.8.7   2025-03-27 [1] RSPM (R 4.4.0)
 stringr         * 1.5.1   2023-11-14 [1] RSPM (R 4.4.0)
 tabularaster      0.7.2   2023-11-01 [1] RSPM (R 4.4.0)
 terra           * 1.8-42  2025-04-02 [1] RSPM (R 4.4.0)
 tibble            3.2.1   2023-03-20 [1] RSPM (R 4.4.0)
 tidyr             1.3.1   2024-01-24 [1] RSPM (R 4.4.0)
 tidyselect        1.2.1   2024-03-11 [1] RSPM (R 4.4.0)
 timechange        0.3.0   2024-01-18 [1] RSPM (R 4.4.0)
 triebeard         0.4.1   2023-03-04 [1] RSPM (R 4.4.0)
 tzdb              0.5.0   2025-03-15 [1] RSPM (R 4.4.0)
 units             0.8-7   2025-03-11 [1] RSPM (R 4.4.0)
 urlchecker        1.0.1   2021-11-30 [1] RSPM (R 4.4.0)
 urltools          1.7.3   2019-04-14 [1] RSPM (R 4.4.0)
 usethis           3.1.0   2024-11-26 [1] RSPM (R 4.4.0)
 vctrs             0.6.5   2023-12-01 [1] RSPM (R 4.4.0)
 vroom             1.6.5   2023-12-05 [1] RSPM (R 4.4.0)
 withr             3.0.2   2024-10-28 [1] RSPM (R 4.4.0)
 xfun              0.52    2025-04-02 [1] RSPM (R 4.4.0)
 xml2              1.3.8   2025-03-14 [1] RSPM (R 4.4.0)
 xtable            1.8-4   2019-04-21 [1] RSPM (R 4.4.0)
 xts               0.14.1  2024-10-15 [1] RSPM (R 4.4.0)
 yaml              2.3.10  2024-07-26 [1] RSPM (R 4.4.0)
 zoo               1.8-14  2025-04-10 [1] RSPM (R 4.4.0)

 [1] /usr/local/lib/R/site-library
 [2] /usr/local/lib/R/library

──────────────────────────────────────────────────────────────────────────────
```


:::
:::
