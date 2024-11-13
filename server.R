function(input, output, session) {

  # theme ----
  observe(session$setCurrentTheme(
    if (isTRUE(input$dark_mode)) dark else light ))

  # rx_r_sst() ----
  rx_r_sst <- reactive({

    nms         <- input$sel_nms
    dir_sst_nms <- glue("data/{input$sel_variable}/{nms}")

    list.files(dir_sst_nms, ".tif$", full.names = T) |>
      map(rast) |>
      rast() |>
      project(leaflet:::epsg3857)
  })

  # map ----
  output$map <- renderLeaflet({
    # TODO: select with input$sel_variable

    # DEBUG
    # input <- list(
    #   sld_md       = as.Date("2024-07-22"),
    #   sld_yrs_now  = c(2024, 2024),
    #   sld_yrs_then = c(1981, 2001))

    r_sst <- rx_r_sst()

    d_sst_r   <- tibble(
      lyr = names(r_sst)) |>
      separate(lyr, c("var", "date"), sep = "\\|", remove = F) |>
      mutate(
        var  = "CRW_SST", # override OLD analysed_sst
        date = as.Date(date))

    var_lbl    = "SST (°C)"
    md         = format(input$sld_md, "%m-%d")
    yrs_now    = input$sld_yrs_now[1]:input$sld_yrs_now[2]
    yrs_then   = input$sld_yrs_then[1]:input$sld_yrs_then[2]
    dates_now  = as.Date(glue("{yrs_now}-{md}"))
    dates_then = as.Date(glue("{yrs_then}-{md}"))

    if (any(dates_now > now_sst))
      dates_now[dates_now > now_sst] <- dates_now[dates_now > now_sst] - years(1)

    yrs_now_rng  <- year(dates_now)
    yrs_then_rng <- year(dates_then)
    if (length(yrs_now_rng) > 2)
      yrs_now_rng <- range(yrs_now_rng)
    if (length(yrs_then_rng) > 2)
      yrs_then_rng <- range(yrs_then_rng)

    r_now  <- get_sst_r(r_sst, d_sst_r, dates_now)
    r_then <- get_sst_r(r_sst, d_sst_r, dates_then)

    lgnd_now <- glue(
      "<b>Now</b><br>
          {format(input$sld_md, '%b %d')},
          {paste(yrs_now_rng, collapse = ' to ')}")
    lgnd_then <- glue(
      "<b>Then</b><br>
           {format(input$sld_md, '%b %d')},
           {paste(yrs_then_rng, collapse = ' to ')}")

    # map bounding box ----
    # input = list(sel_nms = "FKNMS")
    b <- sanctuaries |>
      filter(nms == input$sel_nms) |>
      st_bbox() |>
      as.numeric()

    map_then_now(
      r_then,
      r_now,
      lgnd_then,
      lgnd_now,
      var_lbl,
      dark_mode = isTRUE(input$dark_mode),
      bbox = b,
      lyrs_ctrl = F,
      attr_ctrl = F)
  })

  # plot_doy ----
  output$plot_doy <- renderPlotly({
    # TODO: select with input$sel_variable

    # input <- list(sel_nms = "FKNMS")
    d_sst |>
      filter(
        nms == input$sel_nms) |>
      # tail()
      select(time, val = mean) |>
      plot_doy(
        days_smooth = input$sld_days_smooth)
        # text_size   = 16)
  })

}
