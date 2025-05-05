# climate-dashboard-app
Shiny app for climate dashboard

# log

- [logs](./log)

# install
```bash
# install data repo
git clone git@github.com:noaa-onms/climate-dashboard.git\
# install this repo
git clone git@github.com:noaa-onms/climate-dashboard-app.git
```

# Add Variable Data
Data is stored in `/data/` and checked into github.
Installation of data isn't needed unless more variables are being added.
`extractr` is used to fetch data and save it to this location.
Modify `extractr.qmd` to add more variables from an ERDDAP server.
To run this `.qmd` you will need to put the extractr pacakage one directory level up from this repo (`../`).

```bash
cd ..
git clone git@github.com:marinebon/extractr.git
```

Run for variables of interest:

```bash
quarto render extractr.qmd --execute-params data/metadata/noaa_dhw.yaml
```

This will take a long time and show little output. 
NOTE: Cannot get more verbose, even using `--execute-debug --log-level info --output -`.

Alternatively: edit the `params` header in the `extractr.qmd` file itself & run from RStudio.

The ability to **use** this data is not yet coded into global.R, server.R, and ui.R.
