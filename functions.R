get_r <- function(r, d, dates){  # dates = dates_then
  # r = r_var; d = d_var_r; dates = dates_now

  lyrs <- d |>
    filter(
      date %in% !!dates) |>
    pull(lyr)

  if (length(lyrs) == 0){
    # browser()
    stop("length(lyrs) == 0")
  }

  r |>
    subset(lyrs) |>
    mean() |>
    project(leaflet:::epsg3857)
}

get_d <- function(var, nms){
  dir <- here(glue("data/{var}/{nms}"))
  if (!dir.exists(dir))
    return(NULL)

  tibble(
    csv = list.files(dir, ".csv$", full.names = T)) |>
    mutate(
      data = map(csv, \(x) read_csv(x))) |>
    unnest(data) |>
    mutate(
      date = as.Date(time)) |>
    arrange(time)
}

map_then_now <- function(
    r_then,
    r_now,
    lgnd_then,
    lgnd_now,
    var_lbl,
    palette     = "Spectral",
    palette_rev = TRUE,
    bbox        = NULL,
    dark_mode   = T,
    lyrs_ctrl   = T,
    attr_ctrl   = T){

  tiles = ifelse(
    dark_mode,
    providers$CartoDB.DarkMatter,
    providers$CartoDB.Positron)

  color_tbsegshed = ifelse(
    dark_mode,
    "white",
    "black")

  vals <- c(values(r_now, na.rm=T), values(r_then, na.rm=T))
  pal  <- colorNumeric(
    palette, vals, reverse = palette_rev, na.color = "transparent")

  m <- leaflet(
    options = leafletOptions(
      attributionControl = attr_ctrl)) |>
    addMapPane("left",  zIndex = 0) |>
    addMapPane("right", zIndex = 0) |>
    addProviderTiles(
      tiles,
      options = pathOptions(pane = "left"),
      group   = "base",
      layerId = "base_l") |>
    addProviderTiles(
      tiles,
      options = pathOptions(pane = "right"),
      group   = "base",
      layerId = "base_r") |>
    addRasterImage(
      r_then, colors = pal, opacity = 0.8, project = F,
      options = leafletOptions(pane = "left"),
      group = "r_then") |>
    addRasterImage(
      r_now, colors = pal, opacity = 0.8, project = F,
      options = leafletOptions(pane = "right"),
      group = "r_now") |>
    addSidebyside(
      layerId = "sidecontrols",
      leftId  = "base_l",
      rightId = "base_r") |>
    addControl(
      HTML(lgnd_then),
      position = "topleft") |>
    addControl(
      HTML(lgnd_now),
      position = "topright") |>
    # addPolygons(
    #   data         = tbsegshed,
    #   label        = tbsegshed$long_name,
    #   labelOptions = labelOptions(
    #     interactive = T),
    #   color        = color_tbsegshed,
    #   weight       = 2,
    #   fillOpacity  = 0) |>
    addLegend(
      pal    = pal,
      values = vals,
      title  = var_lbl)

  if (lyrs_ctrl)
    m <- m |> addLayersControl(overlayGroups = c("r_then", "r_now"))

  if (!is.null(bbox))
    m <- m |>
      fitBounds(
        lng1 = bbox[1],
        lat1 = bbox[2],
        lng2 = bbox[3],
        lat2 = bbox[4])
  m
}


plot_doy <- function(
    df, # required columns: time, val
    days_smooth      = 7,
    color_thisyear   = "red",
    color_lastyear   = "orange",
    color_otheryears = "gray",
    size_thisyear    = 1.5,
    size_lastyear    = 1,
    size_otheryears  = 0.5,
    # text_size        = 11,
    interactive      = TRUE,
    y_lab            = "SST (ºC)"){
  # bay_segment = "BCB"
  # df = d_sst_z

  # check args ----
  stopifnot(c("time","val") %in% names(df))

  # days_smooth
  stopifnot(is.numeric(days_smooth) & days_smooth >= 0 & days_smooth <= 365)
  if (days_smooth == 0){
    days_sm_before <- 0
    days_sm_after  <- 0
  } else {
    h <- (days_smooth - 1)/2
    days_sm_before <- ceiling(h) |> as.integer()
    days_sm_after  <-   floor(h) |> as.integer()
  }

  yrs       <- range(year(df$time))
  yr_last   <- yrs[2] - 1
  yrs_other <- glue("{yrs[1]} to {yr_last}")
  yr_cols <- setNames(
    c(color_thisyear, color_lastyear, color_otheryears),
    c(        yrs[2],        yr_last,        yrs_other))
  yr_szs <- setNames(
    c( size_thisyear,  size_lastyear, size_otheryears),
    c(        yrs[2],        yr_last,       yrs_other))

  md_lims <- sprintf(
    "%d-%02d-%02d",
    year(today()), c(1,12), c(1,31) ) |>
    as.POSIXct()

  d <- df |>
    mutate(
      year  = year(time),
      doy   = sprintf(
        "%d-%02d-%02d",
        year(today()), month(time), day(time) ) |>
        as.Date() |>
        as.POSIXct(),
      yr_cat = case_when(
        year == yrs[2]  ~ yrs[2] |> as.character(),
        year == yr_last ~ yr_last |> as.character(),
        .default = yrs_other) |>
        factor()) |>
    select(time, year, doy, yr_cat, val) |>
    arrange(year, doy, val) |>
    group_by(year) |>
    mutate(
      val_sl = slider::slide_mean(
        val,
        before   = days_sm_before,
        after    = days_sm_after,
        step     = 1L,
        complete = F,
        na_rm    = T),
      date  = as.Date(time),
      value = round(val_sl, 2) ) |>
    select(-time) |>
    ungroup()

  g <- ggplot(
    d,
    aes(
      x     = doy,
      y     = val_sl,
      group = year,
      color = yr_cat,
      size  = yr_cat,
      date  = date,
      value = value)) +  # frame = yday
    geom_line(
      # aes(text  = text),
      alpha = 0.6) +
    scale_colour_manual(
      name   = "Year",
      values = yr_cols) +
    scale_size_manual(
      values = yr_szs, guide="none") +
    # theme(legend.position = "") +
    theme(
      legend.position.inside = c(0.5, 0.15)) +
      # text            = element_text(size = text_size)) +
    scale_x_datetime(
      labels = date_format("%b %d"),
      limits = md_lims,
      expand = c(0, 0)) +
    labs(
      x = "Day of year",
      y = y_lab)

  if (!interactive)
    return(g)

  ggplotly(g, tooltip=c("date","value")) |>
    # layout(legend = list(x = 0.5, y = 0.15))
    layout(legend = list(x = 0.5, y = 0.05))
}

