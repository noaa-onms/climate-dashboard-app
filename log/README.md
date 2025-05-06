# climate-dashboard-app

Shiny app for climate dashboard:

## data processing

Metadata for datasets (`/meta/*.yaml`) are used by the update script 
(`process/update_data.R`), which uses dataset-specific Quarto notebooks
(`process/copernicus|erddap.qmd`) to generate the data files (`/data/*`) 
and the log files (`/log/*.html`), eg:

```
meta/noaa_sst.yaml -[ erddap.qmd ]-> data/noaa_sst/*, log/noaa_sst.html
```

I'll update the README.md section to include a more detailed tree-like file structure and add a Mermaid diagram to better explain the data processing workflow. Here's my updated version:

## Data Processing

Metadata for datasets (`/meta/*.yaml`) are used by the update script (`process/update_data.R`), which uses dataset-specific Quarto notebooks (`process/copernicus|erddap.qmd`) to generate the data files (`/data/*`) and the log files (`/log/*.html`).

### File Structure

```
project/
├── meta/
│   ├── noaa_sst.yaml
│   ├── copernicus_wind.yaml
│   └── erddap_chla.yaml
├── process/
│   ├── update_data.R
│   ├── copernicus.qmd
│   └── erddap.qmd
├── data/
│   ├── noaa_sst/
│   │   ├── monthly.csv
│   │   └── annual.csv
│   ├── copernicus_wind/
│   │   └── wind_data.nc
│   └── erddap_chla/
│       └── chlorophyll.csv
└── log/
    ├── noaa_sst.html
    ├── copernicus_wind.html
    └── erddap_chla.html
```

### Data Processing Workflow

The data processing workflow follows this pattern:

````
meta/noaa_sst.yaml -[ erddap.qmd ]-> data/noaa_sst/*, log/noaa_sst.html
```

This process is illustrated in the diagram below:

```mermaid
  info
```

```mermaid
graph LR
    subgraph Metadata
        M1[meta/noaa_sst.yaml]
        M2[meta/copernicus_wind.yaml]
        M3[meta/erddap_chla.yaml]
    end
    
    subgraph Processors
        P1[update_data.R]
        P2[copernicus.qmd]
        P3[erddap.qmd]
    end
    
    subgraph Outputs
        subgraph Data
            D1[data/noaa_sst/*]
            D2[data/copernicus_wind/*]
            D3[data/erddap_chla/*]
        end
        
        subgraph Logs
            L1[log/noaa_sst.html]
            L2[log/copernicus_wind.html]
            L3[log/erddap_chla.html]
        end
    end
    
    M1 --> P1
    M2 --> P1
    M3 --> P1
    
    P1 --> |ERDDAP data| P3
    P1 --> |Copernicus data| P2
    
    P3 --> D1
    P3 --> L1
    P2 --> D2
    P2 --> L2
    P3 --> D3
    P3 --> L3
    
    style M1 fill:#f9f,stroke:#333,stroke-width:1px
    style M2 fill:#f9f,stroke:#333,stroke-width:1px
    style M3 fill:#f9f,stroke:#333,stroke-width:1px
    
    style P1 fill:#bbf,stroke:#333,stroke-width:1px
    style P2 fill:#ddf,stroke:#333,stroke-width:1px
    style P3 fill:#ddf,stroke:#333,stroke-width:1px
    
    style D1 fill:#bfb,stroke:#333,stroke-width:1px
    style D2 fill:#bfb,stroke:#333,stroke-width:1px
    style D3 fill:#bfb,stroke:#333,stroke-width:1px
    
    style L1 fill:#fbb,stroke:#333,stroke-width:1px
    style L2 fill:#fbb,stroke:#333,stroke-width:1px
    style L3 fill:#fbb,stroke:#333,stroke-width:1px
```

The workflow consists of these key steps:

1. **Configuration**: Metadata YAML files in `/meta/` define dataset parameters
2. **Processing**: The `update_data.R` script reads metadata and determines which Quarto notebook to use
3. **Data Generation**: Either `copernicus.qmd` or `erddap.qmd` notebooks process the raw data sources
4. **Output**: Generated datasets are stored in `/data/` with corresponding processing logs in `/log/`

Here are the latest output log files:

<!-- Jekyll render html in log/*.html -->
{% for file in site.static_files %}
  {% if file.extname == '.html' and file.path contains 'log/' %}
* [{{ file.basename }}]({{ site.baseurl }}{{ file.path }})
  {% endif %}
{% endfor %}

## source

See [github.com/MarineSensitivity/workflows](https://github.com/MarineSensitivity/workflows)


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

