## 2-26-04-15 run process/update_data.R as su

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
