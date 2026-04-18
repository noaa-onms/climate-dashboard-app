## 2026-04-17 slide ideas

[Image #1] Generate a table and figure like [Image #1] across these three products (`@../eco-indicators`, `@../climate-dashboard-app`, `@../climate-dashboard`) using R code into summary.qmd to interrogate for the latest. Include spatial resolution and timespan, so orient with products (Dashboard, App, Indicators) in columns, and variables in rows. Note for eco-indicators, use `@./data/copernicus_variables_trim.csv`

Output to `@../climate-dashboard-app/summary.qmd`

I am interacting on my laptop for now, but  `@../climate-dashboard-app` probably needs to have `summary.qmd` run on the server to capture latest.

⏺ Updated plan                                                                
  ⎿  /plan to preview                                                         

 Ready to code?                                                               
                                                                              
 Here is Claude's plan:                                                       

 **Plan: `summary.qmd` — EOV coverage across three ONMS products**
                                                                              
 Context                                                

 The user maintains three parallel NOAA ONMS climate/eco products that each
 track a subset of Essential Ocean Variables (EOVs):

 - eco-indicators (this repo, Quarto notebooks) —
 data/copernicus_variables_trim.csv + data/erddap.csv
 - climate-dashboard-app (Shiny) — app/global.R defines a d_vars tibble;
 Copernicus metadata in meta/*.yml
 - climate-dashboard (flexdashboard) — data/datasets.csv

 The goal is a single summary notebook in eco-indicators that dynamically
 interrogates all three sources "for the latest", maps each product's
 variables onto a canonical EOV list, and renders both (a) a coverage tile
 figure like the mockup (proposal Table 1 EOVs × products, blue = live / grey
  = gap) and (b) a detail table (DT::datatable) that also carries spatial
 resolution and timespan per (EOV, product).

 This enables a quick visual audit of which EOVs each product covers, exposes
  gaps (e.g. Seascapes, CDOM), and surfaces spatial/temporal resolution
 differences across products — useful for the proposal Table 1 write-up and
 for planning future extraction work.

 Deliverable

 Single new file:
 /Users/bbest/Github/noaa-onms/climate-dashboard-app/summary.qmd

 Why climate-dashboard-app (not eco-indicators): the Shiny app holds live
 data connections (ERDDAP + Copernicus) that are only wired up on the server.
  For the summary to "interrogate for the latest", it must render where those
  connections exist — i.e. on the same host as the app. Eco-indicators and
 climate-dashboard are static-enough to read from sibling directories.

 No other files modified.

 Canonical EOV list (row order, top → bottom of figure)

 SST, CN-a, SSS, MLD, Bottom-T, Oxygen, pH / DIC, NPP,
 Nutrients (NO3/PO4/Si/Fe), Phytoplankton (PFTs), Zooplankton,
 Precipitation, Seascapes, SSH, CDOM / SPM / nFLH, CMIP6 / CESM2

 Product columns (left → right): Shiny app, flexdashboard, eco-indicators.

 Data sources & how to read them

 All paths below are relative to climate-dashboard-app/ (where summary.qmd
 lives):

 Product: eco-indicators
 File: `../eco-indicators/data/copernicus_variables_trim.csv`
 How to read: read_csv() — already has dataset_id, variable, time_min/max,
   depth, lon/lat bounds
 ────────────────────────────────────────
 Product: eco-indicators
 File: `../eco-indicators/data/erddap.csv`
 How to read: read_csv() — gives precipitation (dataset
   IMERG_monthly_global_precip)
 ────────────────────────────────────────
 Product: climate-dashboard-app
 File: `app/global.R`
 How to read: source(..., local = new.env()) into a sandbox env, then
   env$d_vars (tibble: var, provider, label, lbl). Augment with meta/*.yml
   (via yaml::read_yaml) for dataset_id + time/depth info where available.
   Running on the server is what makes the "live" connection data accessible
 ────────────────────────────────────────
 Product: climate-dashboard
 File: `../climate-dashboard/data/datasets.csv`
 How to read: read_csv() — columns: active, type, url, var, var_header,
   plot_label, yr_beg, yr_end, metadata_nc

 If sourcing global.R fails (side effects on package load), fall back to a
 regex extraction of the d_vars <- tribble(...) block — but try source() with
  a sandbox env first.

 Include a short note at the top of summary.qmd stating: "Render this on the
 host where climate-dashboard-app is deployed to capture the latest from live
  data connections. Sibling repos (../eco-indicators, ../climate-dashboard)
 must be checked out alongside at their latest commits."

 Variable → EOV mapping

 Define a single in-script lookup tibble eov_map that maps each raw variable
 identifier to one EOV category. Variables not in the map are dropped (or
 logged).

 eco-indicators (from copernicus_variables_trim.csv variable column +
 erddap):
 - thetao → SST · CHL → CN-a · so → SSS · mlotst → MLD · bottomT → Bottom-T
 - PP → NPP · zos → SSH · precipitation → Precipitation
 - DIATO, DINO, GREEN, HAPTO, MICRO, NANO, PICO, PROCHLO, PROKAR →
 Phytoplankton (PFTs)

 climate-dashboard-app (from d_vars$var):
 - erddap_sst, copernicus_phy.thetao → SST
 - copernicus_bgc-pft.chl → CN-a
 - erddap_sss, copernicus_phy.so → SSS
 - copernicus_phy.mlotst → MLD
 - copernicus_phy.bottomT → Bottom-T
 - copernicus_bgc-bio.o2 → Oxygen
 - copernicus_bgc-car.dissic, copernicus_bgc-car.ph, copernicus_bgc-co2.spco2
  → pH / DIC
 - copernicus_bgc-bio.nppv → NPP
 - copernicus_bgc-nut.no3, .po4, .si, .fe → Nutrients
 - copernicus_bgc-pft.phyc → Phytoplankton (PFTs)
 - copernicus_bgc-plankton.zooc → Zooplankton
 - erddap_precip → Precipitation

 climate-dashboard (from datasets.csv rows; CESM2 rows also set a CMIP6/CESM2
  flag):
 - jplMURSST41mday → SST · CESM2 SST → SST + CMIP6/CESM2
 - CoastWatch Chl + CESM2 Chl → CN-a (+ CMIP6/CESM2 for CESM2)
 - CESM2 SSS → SSS + CMIP6/CESM2
 - CESM2 MLD → MLD + CMIP6/CESM2
 - CESM2 pH → pH/DIC + CMIP6/CESM2
 - CESM2 NPP → NPP + CMIP6/CESM2

 Any CESM2 row contributes a row to the CMIP6 / CESM2 EOV for the
 flexdashboard column.

 Pipeline (pseudo)

 ```
 # 1. read per-product variable tables → 3 tidy tibbles with columns:
 #    product, variable, dataset, spatial_res, time_min, time_max, units
 # 2. left_join each to eov_map → assign EOV
 # 3. bind rows into `vars_all`
 # 4. coverage_long: distinct(product, eov) with live = TRUE
 #    × full grid(product × eov_levels) → fill missing as gap
 # 5. figure: ggplot tile (fill = live/gap), y axis rev(eov_levels)
 # 6. detail table: vars_all grouped by (eov, product) summarizing variable
 #    codes, spatial_res, and combined timespan; rendered with DT::datatable
 ```

 Figure

 ```r
 ggplot(coverage_long, aes(product, eov, fill = status)) +
   geom_tile(color = "white", linewidth = 0.6) +
   scale_fill_manual(values = c(live = "#1f77b4", gap = "#d9d9d9")) +
   scale_y_discrete(limits = rev(eov_levels)) +
   scale_x_discrete(limits = c("Shiny app", "flexdashboard",
 "eco-indicators")) +
   labs(
     title    = "EOV coverage across three products",
     subtitle = "Rows = proposal Table 1 variables · blue = live · grey =
 gap",
     x = NULL, y = NULL, fill = NULL) +
   theme_minimal(base_size = 12) +
   theme(panel.grid = element_blank(),
         legend.position = "bottom")
 ```

 Detail table (DT)

 Wide pivot: one row per EOV, columns per product containing variable codes
 (comma-separated); plus auxiliary columns: spatial_res_<product>,
 timespan_<product>. Rendered via datatable(..., options = list(scrollX =
 TRUE, pageLength = 20)).

 Also write the underlying long-form tibble to data/summary_eov_coverage.csv
 for reuse.

 File structure of `summary.qmd`

 1. YAML header matching copernicus.qmd (html, toc, embed-resources,
 code-fold, code-tools).
 2. setup chunk: librarian::shelf(dplyr, tidyr, readr, ggplot2, DT, glue,
 here, yaml, stringr, purrr, quiet = T).
 3. eov_levels vector + eov_map tibble.
 4. read_eco_indicators() — reads the two CSVs.
 5. read_dashboard_app() — sources global.R in sandbox env + reads
 meta/*.yml.
 6. read_dashboard() — reads datasets.csv, expands CESM2 rows to also tag
 CMIP6/CESM2.
 7. Combine → vars_all, write CSV.
 8. Build coverage grid → render figure.
 9. Build detail tibble → render datatable().

 Verification

 1. Laptop (current): quarto render summary.qmd from climate-dashboard-app/ —
  must render without error against the sibling-repo CSVs and the static
 app/global.R.
 2. Server: re-render after pulling latest on all three repos so live
 ERDDAP/Copernicus-backed variable lists are captured.
 3. Resulting figure should show blue tiles in the same cells as the mockup
 (modulo minor differences: mockup shows flexdashboard missing Precipitation
 — verify that matches datasets.csv; mockup shows Shiny app missing SSH —
 verify matches d_vars).
 4. Confirm Seascapes and CDOM/SPM/nFLH rows are entirely grey (no coverage
 anywhere) — known gaps.
 5. Confirm CMIP6/CESM2 row is live only for flexdashboard.
 6. Spot-check detail table: eco-indicators row for SST should show thetao,
 0.083° (~9.25 km), 1993-01 → 2026-02.

 Critical file paths

 - Write: /Users/bbest/Github/noaa-onms/climate-dashboard-app/summary.qmd
 - Read: /Users/bbest/Github/noaa-onms/climate-dashboard-app/app/global.R
 - Read: /Users/bbest/Github/noaa-onms/climate-dashboard-app/meta/*.yml
 - Read: /Users/bbest/Github/noaa-onms/eco-indicators/data/copernicus_variabl
 es_trim.csv
 - Read: /Users/bbest/Github/noaa-onms/eco-indicators/data/erddap.csv
 - Read: /Users/bbest/Github/noaa-onms/climate-dashboard/data/datasets.csv
 - Write (side effect): /Users/bbest/Github/noaa-onms/climate-dashboard-app/d
 ata/summary_eov_coverage.csv

⏺ Created climate-dashboard-app/summary.qmd. Coverage matches the mockup:
                                                                              
  ┌─────────────────────────────────┬────────────────┬──────┬─────────┐       
  │               EOV               │     Shiny      │ flex │ eco-ind │
  ├─────────────────────────────────┼────────────────┼──────┼─────────┤       
  │ SST, CN-a, SSS, MLD, NPP        │ ✓              │ ✓    │ ✓       │
  ├─────────────────────────────────┼────────────────┼──────┼─────────┤       
  │ Bottom-T, Precip, Phytoplankton │ ✓              │ —    │ ✓       │       
  ├─────────────────────────────────┼────────────────┼──────┼─────────┤       
  │ Oxygen, Nutrients, Zooplankton  │ ✓              │ —    │ —       │       
  ├─────────────────────────────────┼────────────────┼──────┼─────────┤       
  │ pH/DIC                          │ ✓              │ ✓    │ —       │
  ├─────────────────────────────────┼────────────────┼──────┼─────────┤       
  │ SSH                             │ —              │ —    │ ✓       │
  ├─────────────────────────────────┼────────────────┼──────┼─────────┤       
  │ CMIP6/CESM2                     │ —              │ ✓    │ —       │
  ├─────────────────────────────────┼────────────────┼──────┼─────────┤       
  │ Seascapes, CDOM/SPM/nFLH        │ gap across all │      │         │
  └─────────────────────────────────┴────────────────┴──────┴─────────┘       
  
  Pipeline reads `app/global.R` d_vars (parsed without sourcing), `meta/*.yml`,   
  `../eco-indicators/data/copernicus_variables_trim.csv` + `erddap.csv`, and
  `../climate-dashboard/data/datasets.csv`. Writes long-form CSV to             
  `data/summary_eov_coverage.csv`. Re-render on the server for the latest.

Drop the variables not found in any product: Seascapes, CDOM/SPM/nFLH, CMIP6/CESM2.

Provide descriptions of each aggregate value. For instance, what is CN-a?

Why does flexdashboard have no variables when clearly it has SST, Chl and projection variables.

⏺ Re-rendering after making those edits — also worth noting: the
  flexdashboard-empty issue was a bug in my first render (the active column
  was being auto-coerced to logical so the filter dropped everything). That
  was fixed just before I reported back, so you may have been viewing the     
  stale HTML. Confirming post-fix that flexdashboard shows live for SST, CN-a,
   SSS, MLD, pH/DIC, NPP.   

⏺ Now also drop the CESM2 short-name mapping entries from eov_map so the
  flexdashboard projections still count toward their primary EOVs only. Let me
   also add an EOV-description table section above the figure and join
  descriptions into the detail table. 

⏺ Rendered. Dropped Seascapes/CDOM/CMIP6 rows, added an EOV descriptions table
   (with a plain-language definition of each aggregate like CN-a =
  chlorophyll-a, MLD = mixed layer depth, etc.), and joined descriptions into
  the detail table.                                                           
   
  Also confirmed the flexdashboard column is correctly populated — 9 variables
   across SST, CN-a, SSS, MLD, NPP, pH/DIC (both ERDDAP SST/chl + 6 CESM2
  LENS2 projections). The earlier "all-gap" flexdashboard column was a bug I  
  fixed before the last render; if you were viewing the HTML before that fix,
  a reload should now show the filled-in column.

## 2026-04-15 run process/update_data.R as su

I am running this repo on a Linux server and now rerunning the @process/update_data.R 
as root user so the crontab continues to work even when user (previously admin) 
logged out. Based on @log/update_data_log.txt I  can see that I need to also 
install h5py into the R reticulate Python environment with `sudo R`:
```r
reticulate::virtualenv_install(envname = "CopernicusMarine", packages   = c("copernicusmarine","h5py"))
```

I am also seeing `TypeError: variables must be of type list` for 
dataset `cmems_mod_glo_bgc-co2_anfc_0.25deg_P1D-m` -- is there a problem with 
@meta/copernicus_bgc-co2.yml? What other errors can I fix?

⏺ Summary                        

  TypeError root cause — Not the yml itself; it's process/copernicus.qmd:370. map_chr() returns a length-1 character vector when the yml has a single variable, and reticulate        
  converts that to a Python str rather than a list. Two ymls have only one variable:
  - meta/copernicus_bgc-co2.yml → spco2                                                                                                                                               
  - meta/copernicus_bgc-plankton.yml → zooc (will hit the same error)                                                                                                                 
   
  Fixed by wrapping in as.list().                                                                                                                                                     
                                                                                                                                                                                    
  h5py — copernicus.qmd:115 already documents virtualenv_install(..., c("copernicusmarine","h5py")), so your sudo R step matches the intended env. Good.                              
                                                                  
  Other potential issues to watch                                                                                                                                                     
  - `copernicus.qmd`:51 reads `../climate-dashboard/data/sanctuaries.rds` — a sibling repo outside this project. Make sure root's working tree has that sibling checked out at
  /share/github/noaa-onms/climate-dashboard, or the script will fail for all yml files
  
  - `copernicus.qmd`:128 hardcodes `/share/private/data.marine.copernicus.eu_bbest1-password.txt`; root must be able to read it.
  
  - `update_data.R`:23 calls `gitcreds_get()`, which reads the user-scoped git credential store. Under sudo/cron as root, that store may be empty — the stopifnot(... == "ghp") will abort
   before any rendering. You may need to populate root's credential helper (or switch to a GITHUB_PAT env var read in the script).
   
  - `update_data.R`:20 still has `do_git <- T` # DEBUG — intentional, but worth confirming before each cron run.

Yes, root is failing on github credentials. What's the best way to handle this?                                                                                                     
                                                                                  
⏺ Two clean options, pick based on preference:                                                                                                                                        
                                                                                                                                       
  1. **SSH deploy key** (recommended for cron) — Generate a key as root (sudo ssh-keygen), add the public key as a deploy key on the GitHub repo with write access, switch the remote to  
  SSH (git remote set-url origin git@github.com:noaa-onms/climate-dashboard-app.git), then drop the gitcreds_get() block from update_data.R:23-24 entirely. No PAT handling, no       
  expiry, no stopifnot guard needed.                                                                                                                                                  
                                                                                                                                                                                      
  2. **PAT in a root-readable file** — Store the token at e.g. /share/private/github_pat.txt (chmod 600, owned by root), replace lines 23-24 with github_pat <-                           
  readLines("/share/private/github_pat.txt"), then run git config --global credential.helper store as root once and do a manual git push to seed /root/.git-credentials. Mirrors your
  laptop pattern but works non-interactively.                                                                                                                                         
                                                                                                                                                                                      
  SSH is less fragile long-term (PATs expire, deploy keys don't), and the sanctuaries.rds sibling repo could use the same key.   

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
