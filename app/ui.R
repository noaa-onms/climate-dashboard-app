thematic_shiny(font = "auto")
page_sidebar(
  window_title = "Sanctuaries Climate Change App",
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
      choices_nms,
      selected_nms),

    selectInput(
      "sel_var",
      "Variable",
      choices_var,
      selected_var) ),

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
          min     = 1800,
          value   = c(1800, 1899),
          max     = 1899,
          step    = 1,
          animate = T,
          sep     = ""),

        sliderInput(
          "sld_yrs_now",
          "Year(s), Now",
          min     = 1801,
          value   = c(1801, 1900),
          max     = 1900,
          step    = 1,
          animate = T,
          sep     = "")) ),

    leafletOutput("map"),

    absolutePanel(
      id        = "pnl_md",
      bottom    = "2%", left = "10%", right = "10%",
      width     = "80%",

      sliderInput(
        "sld_md",
        "Month and day of year",
        min        = as.Date("1900-01-01"),
        value      = as.Date("1900-06-01"),
        max        = as.Date("1900-12-31"),
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
