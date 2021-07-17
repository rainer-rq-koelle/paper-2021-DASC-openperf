from traffic.core import Traffic
import pandas as pd
from pyhere import here, find_root
import glob
import os
import datetime
import pyarrow as pa
from pathlib import Path


base_dir = 'Z:\\Public\\Haren\\RQ\\DASC'
dest_dir = 'C:\\Users\\spi\\repos\\paper-2021-DASC-openperf\\data'
# base_dir = str(here("data-raw"))
# dest_dir = str(here("data"))
for adsb_file in glob.iglob(base_dir + '/**/*.feather', recursive=True):
    airport, date, _ = os.path.basename(adsb_file).split('_')
    dest_file = dest_dir + '\\' + airport + '\\' + f"{airport}_{date}_arrivals.csv"
    if Path(dest_file).exists(): 
        print(f"File {dest_file} exists already...skipping {airport} on {date}.")
        continue
    ts = datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S.%f")
    print(f"Processing {airport} on {date}, {adsb_file}...{ts}")
    print(f"saving result in {dest_file}...")
    # tb = pa.csv.read_csv(adsb_file)
    # df = tb.to_pandas()
    df = pd.read_feather(adsb_file)
    t = Traffic(df)
    arrs = (t.landing_at(airport)
        .final(f'aligned_on_{airport}') # it needs 0fdef2cb9c68b8f739fae8b97d1aab0c054d914f
        .summary(['callsign', 'stop', 'ILS_max'])
        .to_csv(dest_file)
    )
    ts = datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S.%f")
    print(f"Processed  {airport} on {date}, {adsb_file}   {ts}")
