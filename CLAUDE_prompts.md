## 2025-09-11 fix to read ncdf rasters and plot with ocean background

Fix the code in @ucar.qmd to properly read the netCDF rasters of different 
variables and interactively plot a given time slice with an ocean-themed background. Think hard

⏺ Fixed! The code now:

  1. Properly handles curvilinear grids using stars::read_ncdf() with curvilinear = c("TLONG", "TLAT")
  2. Solves memory issues by warping to regular grid and downsampling (configurable factor)
  3. Adds ocean basemap using Esri.OceanBasemap tiles
  4. Provides flexible plot_nc_variable() function that:
    - Plots any variable and time slice
    - Supports year selection or time index
    - Offers multiple color palettes (viridis, ocean, temperature)
    - Controls downsampling for performance
  5. Includes synchronized multi-panel comparisons using leafsync

  Key improvements:
  - No more memory errors
  - Cleaner variable extraction from filenames
  - Appropriate color schemes for different oceanographic variables
  - Interactive maps with proper ocean context
