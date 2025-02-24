function(input, output, session) {

  # theme ----
  observe(session$setCurrentTheme(
    if (isTRUE(input$dark_mode)) dark else light ))

  # rx_d_var() ----
  rx_d_var <- reactive({
    nms <- input$sel_nms
    var <- input$sel_variable

    # TODO: make generic variable inputs with labels
    case_match(
      var,
      "NOAA_DHW"  ~ "d_sst",
      "NOAA_SMOS" ~ "d_sss") |>
      get() |>
      filter(nms == !!nms)
  })

  # rx_yr_range() ----
  rx_yr_range <- reactive({
    d_var <- rx_d_var()
    yrs_var <- range(year(d_var$date))
    now_var <- max(d_var$date)

    list(
      yrs_var = yrs_var,
      now_var = now_var
    )
  })

  # Reactive values for slider ranges
  slider_ranges <- reactiveValues(
    yrs_then = NULL,
    yrs_now = NULL,
    md = NULL
  )

  # Update slider ranges when variable or nms changes
  observe({
    yr_range <- rx_yr_range()
    yrs_var <- yr_range$yrs_var
    now_var <- yr_range$now_var

    # Update reactive values first
    slider_ranges$yrs_then <- list(
      value = c(yrs_var[1], min(yrs_var[1]+20, yrs_var[2]-1)),
      min = yrs_var[1],
      max = yrs_var[2] - 1
    )
    
    slider_ranges$yrs_now <- list(
      value = c(yrs_var[2], yrs_var[2]),
      min = yrs_var[1] + 1,
      max = yrs_var[2]
    )
    
    slider_ranges$md <- list(
      value = now_var,
      min = as.Date(glue("{year(now_var)}-01-01")),
      max = as.Date(glue("{year(now_var)}-12-31"))
    )

    # Then update UI
    updateSliderInput(
      session = session,
      inputId = "sld_yrs_then",
      value   = slider_ranges$yrs_then$value,
      min     = slider_ranges$yrs_then$min,
      max     = slider_ranges$yrs_then$max,
      step    = 1)

    updateSliderInput(
      session,
      "sld_yrs_now",
      value   = slider_ranges$yrs_now$value,
      min     = slider_ranges$yrs_now$min,
      max     = slider_ranges$yrs_now$max)

    updateSliderInput(
      session,
      "sld_md",
      value      = slider_ranges$md$value,
      min        = slider_ranges$md$min,
      max        = slider_ranges$md$max,
      timeFormat = "%b %d")
  })


  # rx_r_var() ----
  rx_r_var <- reactive({

    nms  <- input$sel_nms
    var  <- isolate(input$sel_variable)

    dir_var_nms <- glue("data/{var}/{nms}")
    list.files(dir_var_nms, ".tif$", full.names = T) |>
      map(rast) |>
      rast() |>
      project(leaflet:::epsg3857)
  })

  # map ----
  output$map <- renderLeaflet({
    message(glue("output$map; input$sel_variable={input$sel_variable}; input$sld_yrs_then = {paste(input$sld_yrs_then, collapse=',')}"))

    # TODO: select with input$sel_variable

    # Ensure we have valid slider ranges before proceeding
    req(slider_ranges$yrs_then, slider_ranges$yrs_now, slider_ranges$md)
    
    var          <- input$sel_variable
    # Use reactive values for initial slider values if input hasn't been set yet
    sld_yrs_then <- if (!is.null(input$sld_yrs_then)) input$sld_yrs_then else slider_ranges$yrs_then$value
    sld_yrs_now  <- if (!is.null(input$sld_yrs_now)) input$sld_yrs_now else slider_ranges$yrs_now$value
    sld_md       <- if (!is.null(input$sld_md)) input$sld_md else slider_ranges$md$value
 input$sld_yrs_then: {paste(input$sld_yrs_then, collapse=',')}"))
    d_var        <- rx_d_var()
    yrs_var      <- range(year(d_var$date))
    now_var      <- max(d_var$date)
    # message(glue("{var} AFTER input$sld_yrs_now: {paste(input$sld_yrs_now, collapse=',')}; input$sld_yrs_then: {paste(input$sld_yrs_then, collapse=',')}"))
    sld_yrs_now  <- isolate(input$sld_yrs_now)
    sld_yrs_then <- isolate(input$sld_yrs_then)
    r_var        <- rx_r_var()

    d_var_r   <- tibble(
      lyr = names(r_var)) |>
      separate(lyr, c("var", "date"), sep = "\\|", remove = F) |>
      mutate(
        var  = case_match(var, "analysed_sst" ~ "CRW_SST"),  # override OLD analysed_sst
        date = as.Date(date))

    # TODO: make generic variable inputs with labels
    var_lbl    = case_match(
      var,
      "NOAA_DHW"  ~ "Surface Temperature (°C)",
      "NOAA_SMOS" ~ "Surface Salinity (PSU)")
    md_0         = format(input$sld_md, "%m-%d")
    # browser()
    if (as.Date(glue("{sld_yrs_now[2]}-{md_0}")) > now_var){
      yrs_now    = sld_yrs_now[1]:sld_yrs_now[2] - 1
    } else {
      yrs_now    = sld_yrs_now[1]:sld_yrs_now[2]
    }
    # find nearest date
    ymd <- as.Date(glue("{sld_yrs_now[2]}-{md_0}"))
    md <- d_var |>
      mutate(date_dif = abs(date - ymd)) |>
      arrange(date_dif) |>
      head(1) |>
      pull(date) |>
      format("%m-%d")
    yrs_then   = sld_yrs_then[1]:sld_yrs_then[2]
    # constrain yrs_now, yrs_then to range of

    dates_now  = as.Date(glue("{yrs_now}-{md}"))
    dates_then = as.Date(glue("{yrs_then}-{md}"))

    yrs_now_rng  <- year(dates_now)
    yrs_then_rng <- year(dates_then)
    if (length(yrs_now_rng) > 2)
      yrs_now_rng <- range(yrs_now_rng)
    if (length(yrs_then_rng) > 2)
      yrs_then_rng <- range(yrs_then_rng)

    if (var == "NOAA_SMOS")
      browser()
    # d_var |>
    #   filter(date %in% dates_now)
    # d_var |>
    #   filter(date %in% dates_then)
    # range(d_var$date)
    r_now  <- get_r(r_var, d_var_r, dates_now)
    r_then <- get_r(r_var, d_var_r, dates_then)

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
    rx_d_var() |>
      filter(
        nms == input$sel_nms) |>
      # tail()
      select(time, val = mean) |>
      plot_doy(
        days_smooth = input$sld_days_smooth)
        # text_size   = 16)
  })

}
