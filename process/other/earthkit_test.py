import earthkit as ek
import earthkit.data as ekdata
#import earthkit.plots as ekplots
import earthkit.plots.quickmap as qmap

# https://earthkit-plots.readthedocs.io/en/latest/examples/guide/01-introduction.html#What-is-earthkit-plots?
data = ekdata.from_source("sample", "era5-monthly-mean-2t-199312.grib")
data.ls()
qmap.block(data, domain="France", levels=range(250, 300))

# [Sea surface temperature daily data from 1981 to present derived from satellite observations](https://cds-beta.climate.copernicus.eu/datasets/satellite-sea-surface-temperature?tab=overview)
data = ekdata.from_source(
    'cds',
    'satellite-sea-surface-temperature',
    {
      'processinglevel': 'level_4',
      'sensor_on_satellite': 'combined_product',
      'version': '2_1',
      'year': ['2022'],
      'month': ['01'],
      'day': ['01']
    } )
qmap(data)


client = cdsapi.Client()
  
import cdsapi

dataset = "reanalysis-era5-pressure-levels"
request = {
    'product_type': ['reanalysis'],
    'variable': ['geopotential'],
    'year': ['2024'],
    'month': ['03'],
    'day': ['01'],
    'time': ['13:00'],
    'pressure_level': ['1000'],
    'data_format': 'netcdf',
    'download_format': 'unarchived'
}

client = cdsapi.Client()
client.retrieve(dataset, request).download()