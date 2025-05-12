# climate-dashboard-app

Shiny app for climate dashboard

- app: <https://shiny.marinebon.app/nms-cc>
- log: <https://noaa-onms.github.io/climate-dashboard-app>

## data processing

Metadata for datasets (`/meta/*.yaml`) are used by the update script 
(`process/update_data.R`), which uses dataset-specific Quarto notebooks
(`process/copernicus|erddap.qmd`) to generate the data files (`/data/*`) 
and the log files (`/log/*.html`), eg:

```
meta/erddap_sst.yaml -[ erddap.qmd ]-> data/erddap_sst/*, log/erddap_sst.html
```

I'll update the README.md section to include a more detailed tree-like file structure and add a Mermaid diagram to better explain the data processing workflow. Here's my updated version:

## Data Processing

Metadata for datasets (`/meta/*.yaml`) are used by the update script (`process/update_data.R`), which uses dataset-specific Quarto notebooks (`process/copernicus|erddap.qmd`) to generate the data files (`/data/*`) and the log files (`/log/*.html`).

### File Structure

```
project/
├── meta/
│   ├── copernicus_mld.yaml
│   ├── erddap_sss.yaml
│   └── erddap_sst.yaml
├── process/
│   ├── copernicus.qmd
│   ├── erddap.qmd
│   └── update_data.R
├── data/
│   ├── copernicus_mld/
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
    ├── copernicus_mld.html
    ├── erddap_sss.html
    └── erddap_sst.html
```

### Data Processing Workflow

The data processing workflow follows this pattern:

```
meta/erddap_sst.yaml -[ erddap.qmd ]-> data/erddap_sst/*, log/erddap_sst.html
```

This process is illustrated in the diagram below:


```mermaid
graph LR
    subgraph Metadata
        M1[meta/erddap_sst.yaml]
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
            D1[data/erddap_sst/*]
            D2[data/copernicus_wind/*]
            D3[data/erddap_chla/*]
        end
        
        subgraph Logs
            L1[log/erddap_sst.html]
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

```mermaid
graph LR
    subgraph Metadata
        M1[erddap_sst.yaml]
        M2[copernicus_mld.yaml]
        M3[erddap_sss.yaml]
    end
    
    subgraph Processors
        P1[update_data.R]
        P2[copernicus.qmd]
        P3[erddap.qmd]
    end
    
    subgraph Outputs
        D[Data]
        L[Logs]
    end
    
    Metadata --> P1
    P1 --> P2
    P1 --> P3
    
    P2 --> D
    P2 --> L
    P3 --> D
    P3 --> L
    
    style Metadata fill:#f9f,stroke:#333,stroke-width:1px
    style P1 fill:#bbf,stroke:#333,stroke-width:1px
    style P2 fill:#ddf,stroke:#333,stroke-width:1px
    style P3 fill:#ddf,stroke:#333,stroke-width:1px
    style D fill:#bfb,stroke:#333,stroke-width:1px
    style L fill:#fbb,stroke:#333,stroke-width:1px
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
quarto render extractr.qmd --execute-params data/metadata/erddap_dhw.yaml
```

This will take a long time and show little output. 
NOTE: Cannot get more verbose, even using `--execute-debug --log-level info --output -`.

Alternatively: edit the `params` header in the `extractr.qmd` file itself & run from RStudio.

The ability to **use** this data is not yet coded into global.R, server.R, and ui.R.
