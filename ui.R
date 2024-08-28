thematic_shiny(font = "auto")
page_sidebar(
  title = tagList(
    "Sanctuaries Climate Change App",
    input_switch(
      "dark_mode",
      bs_icon("moon-stars-fill"),
      TRUE)),
  theme = dark,

  # sidebar ----
  sidebar = sidebar(
    title = "Selection",

    selectInput(
      "sel_nms",
      "Sanctuary",
      c("Channel Islands" = "CINMS",
        "Florida Keys"    = "FKNMS"),
      selected = "FKNMS"),

    selectInput(
      "sel_variable",
      "Variable",
      c("Sea Surface Temperature (SST)")) ),

  # map ----
  card(
    full_screen = T,
    card_header(
      "Map of Then vs Now",

      popover(
        title = "Settings",
        placement = "right",
        bs_icon("gear", class = "ms-auto"),

        sliderInput(
          "sld_yrs_then",
          "Year(s), Then",
          min     = yrs_sst[1],
          value   = c(yrs_sst[1], yrs_sst[1]+20),
          max     = yrs_sst[2] - 1,
          step    = 1,
          animate = T,
          sep     = ""),

        sliderInput(
          "sld_yrs_now",
          "Year(s), Now",
          min     = yrs_sst[1] + 1,
          value   = c(yrs_sst[2], yrs_sst[2]),
          max     = yrs_sst[2],
          step    = 1,
          animate = T,
          sep     = "")) ),

    leafletOutput("map"),

    absolutePanel(
      id        = "pnl_md",
      bottom    = "2%", left = "8%", right = "8%",
      width     = "84%",

      sliderInput(
        "sld_md",
        "Month and day of year",
        min        = as.Date(glue("{year(now_sst)}-01-01")),
        value      = now_sst,
        max        = as.Date(glue("{year(now_sst)}-12-31")),
        timeFormat = "%b %d",
        animate    = T,
        width     = "100%") )),

  # plot ----
  card(
    full_screen = T,
    card_header(
      "Plot - Day of year for all years",

      popover(
        title = "Settings",
        bs_icon("gear", class = "ms-auto"),

        sliderInput(
          "sld_days_smooth",
          "# of days for smoothing average",
          min        = 0,
          value      = 7,
          max        = 90,
          animate    = T) ) ),

    plotlyOutput("plot_doy") )
)
