function(input, output, session) {

  # theme ----
  observe(session$setCurrentTheme(
    if (isTRUE(input$dark_mode)) dark else light ))

  # Reactive values for slider ranges
  rx <- reactiveValues(
    nms      = NULL,
    var      = NULL,
    lbl      = NULL,
    label    = NULL,
    yrs_then = NULL,
    yrs_now  = NULL,
    md       = NULL)

  # get_d_var() ----
  get_d_var <- reactive({
    req(rx$nms, rx$var)

    get_d(rx$var, rx$nms)
  })

  # get_r_var() ----
  get_r_var <- reactive({

    browser()

    var  <- rx$var
    nms  <- rx$nms

    dir_var_nms <- glue(here("data/{var}/{nms}"))
    list.files(dir_var_nms, ".tif$", full.names = T) |>
      map(rast) |>
      rast() |>
      project(leaflet:::epsg3857)
  })

  # update sliders, selects & reactives ----
  observe({

    var <- input$sel_var
    nms <- input$sel_nms

    # update nms choices, especially when var changes and potentially missing
    if (!is.null(rx$var) && var != rx$var){
      nms_with_var     <- dir(here(glue("data/{var}")))
      choices_nms_var  <- choices_nms[choices_nms %in% nms_with_var]
      nms <- ifelse(
        nms %in% choices_nms_var,
        nms,
        choices_nms_var[1])

      updateSelectInput(
        session,
        "sel_nms",
        choices  = choices_nms_var,
        selected = nms)
    }
    # TODO: update var choices, esp. when var unavailable for selected nms

    d_var    <- get_d(var, nms)
    if (is.null(d_var))
      return() # allow input$sel_nms to catch up

    yrs_var  <- range(year(d_var$date))
    now_var  <- max(d_var$date)
    yrs_now  <- c(yrs_var[2], yrs_var[2])
    yrs_then <- c(yrs_var[1], min(yrs_var[1]+20, yrs_var[2]-1))

    updateSliderInput(
      session,
      "sld_yrs_then",
      value = yrs_then,
      min   = yrs_var[1],
      max   = yrs_var[2] - 1)

    updateSliderInput(
      session,
      "sld_yrs_now",
      value = yrs_now,
      min   = yrs_var[1] + 1,
      max   = yrs_var[2])

    updateSliderInput(
      session,
      "sld_md",
      value = now_var,
      min   = as.Date(glue("{year(now_var)}-01-01")),
      max   = as.Date(glue("{year(now_var)}-12-31")),
      timeFormat = "%b %d")

    rx$var      = var
    rx$nms      = nms
    rx$yrs_then = yrs_then
    rx$yrs_now  = yrs_now
    rx$md       = now_var
    rx$label    = var_label[var]
    rx$lbl      = var_lbl[var]
  })

  # map ----
  output$map <- renderLeaflet({
    req(rx$var, rx$nms, input$sld_yrs_then, input$sld_yrs_now, input$sld_md)

    var          <- rx$var
    nms          <- rx$nms
    sld_yrs_then <- input$sld_yrs_then
    sld_yrs_now  <- input$sld_yrs_now
    sld_md       <- input$sld_md
    d_var        <- get_d_var()
    r_var        <- get_r_var()

    yrs_var      <- range(year(d_var$date))
    now_var      <- max(d_var$date)

    d_var_r   <- tibble(
      lyr = names(r_var)) |>
      separate(lyr, c("var", "date"), sep = "\\|", remove = F) |>
      mutate(
        var  = case_match(var, "analysed_sst" ~ "CRW_SST"),  # override OLD analysed_sst
        date = as.Date(date))

    md_0  = format(sld_md, "%m-%d")
    if (as.Date(glue("{sld_yrs_now[2]}-{md_0}")) > now_var){
      yrs_now = sld_yrs_now[1]:sld_yrs_now[2] - 1
    } else {
      yrs_now = sld_yrs_now[1]:sld_yrs_now[2]
    }
    # find nearest date
    ymd <- as.Date(glue("{sld_yrs_now[2]}-{md_0}"))
    md_date <- d_var |>
      mutate(date_dif = abs(date - ymd)) |>
      arrange(date_dif) |>
      head(1) |>
      pull(date)
    md <- format(md_date, "%m-%d")
    yrs_then   = sld_yrs_then[1]:sld_yrs_then[2]

    dates_now  = as.Date(glue("{yrs_now}-{md}"))
    dates_then = as.Date(glue("{yrs_then}-{md}"))

    yrs_now_rng  <- year(dates_now)
    yrs_then_rng <- year(dates_then)
    if (length(yrs_now_rng) > 2)
      yrs_now_rng <- range(yrs_now_rng)
    if (length(yrs_then_rng) > 2)
      yrs_then_rng <- range(yrs_then_rng)

    # browser()
    r_now  <- get_r(r_var, d_var_r, dates_now)
    r_then <- get_r(r_var, d_var_r, dates_then)

    lgnd_now <- glue(
      "<b>Now</b><br>
          {format(md_date, '%b %d')},
          {paste(yrs_now_rng, collapse = ' to ')}")
    lgnd_then <- glue(
      "<b>Then</b><br>
           {format(md_date, '%b %d')},
           {paste(yrs_then_rng, collapse = ' to ')}")

    # map bounding box
    b <- sanctuaries |>
      filter(nms == !!nms) |>
      st_bbox() |>
      as.numeric()

    map_then_now(
      r_then,
      r_now,
      lgnd_then,
      lgnd_now,
      rx$label,
      dark_mode = isTRUE(input$dark_mode),
      bbox = b,
      lyrs_ctrl = F,
      attr_ctrl = F)
  })

  # plot_doy ----
  output$plot_doy <- renderPlotly({

    get_d_var() |>
      select(time, val = mean) |>
      plot_doy(
        days_smooth = input$sld_days_smooth,
        y_lab       = rx$lbl)
  })

}
