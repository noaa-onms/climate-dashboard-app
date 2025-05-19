# climate-dashboard-app

Shiny app for climate dashboard

- app: <https://shiny.marinebon.app/nms-cc>
- log: <https://noaa-onms.github.io/climate-dashboard-app>

## Data Extraction

Metadata for datasets (`/meta/*.yaml`) are used by the update script 
(`process/update_data.R`), which uses dataset-specific Quarto notebooks
(`process/copernicus|erddap.qmd`) to generate the data files (`/data/*`) 
and the log files (`/log/*.html`). These are run daily (`process/update_data.R`)
by a cron job on the server and consumed by the [app](https://shiny.marinebon.app/nms-cc).

The data processing workflow follows this pattern:

```
meta/erddap_sst.yaml -[ erddap.qmd ]-> data/erddap_sst/*, log/erddap_sst.html
```

This process is illustrated in the diagram below:

```mermaid
graph LR
    subgraph Metadata
        M1[meta/copernicus_phy.yaml]
        M2[meta/erddap_sss.yaml]
        M3[meta/erddap_sst.yaml]
    end
    
    subgraph Processors
        P1[update_data.R]
        P2[copernicus.qmd]
        P3[erddap.qmd]
    end
    
    subgraph Outputs
        subgraph Data
            D1[data/copernicus_phy/*]
            D2[data/erddap_sss/*]
            D3[data/erddap_sst/*]
        end
        
        subgraph Logs
            L1[log/copernicus_phy.html]
            L2[log/erddap_sss.html]
            L3[log/erddap_sst.html]
        end
    end
    
    M1 --> P1
    M2 --> P1
    M3 --> P1
    
    P1 --> |Copernicus data| P2
    P1 --> |ERDDAP data| P3
    
    P2 --> D1
    P2 --> L1
    P3 --> D2
    P3 --> L2
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

### File Structure

```
project/
├── meta/
│   ├── copernicus_phy.yaml
│   ├── erddap_sss.yaml
│   └── erddap_sst.yaml
├── process/
│   ├── copernicus.qmd
│   ├── erddap.qmd
│   └── update_data.R
├── data/
│   ├── copernicus_phy/
│   │   ├── 2010.csv
│   │   ├── 2010.tif
│   │   ├── 2011.csv
│   │   └── 2011.tif
│   ├── erddap_sst/
│   │   ├── 2010.csv
│   │   ├── 2010.tif
│   │   ├── 2011.csv
│   │   └── 2011.tif
│   └── erddap_sss/
│   │   ├── 2010.csv
│   │   ├── 2010.tif
│   │   ├── 2011.csv
│   │   └── 2011.tif
└── log/
    ├── copernicus_phy.html
    ├── erddap_sss.html
    └── erddap_sst.html
```

## Extracting individual dataset variables

Data is stored in `/data/` and checked into Github.
The 
[`extractr::ed_extract()`](https://marinebon.github.io/extractr/reference/ed_extract.html) 
function is used to fetch ERDDAP data and save it to this location.
Add a metada file to `meta/*.yml` to add more variables from an ERDDAP server.

Run for variables of interest:

```bash
quarto render process/extractr.qmd --execute-params meta/erddap_sst.yaml
```

Alternatively: edit the `params` header in the `extractr.qmd` file itself & run from RStudio.

## TODO

- TODO: Add configurations to yml to use the data in the app (`global.R`).
