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
    ts = datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S.%f")
    print(f"Processing {airport} on {date}, {adsb_file}...{ts}")
    print(f"saving result in {dest_file}...")
    # tb = pa.csv.read_csv(adsb_file)
    # df = tb.to_pandas()
    df = pd.read_feather(adsb_file)
    t = Traffic(df)
    arrs = (t.landing_at(airport)
        .next(f'aligned_on_{airport}')
        .summary(['callsign', 'stop', 'ILS_max'])
        .to_csv(dest_file)
    )
    ts = datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S.%f")
    print(f"Processed  {airport} on {date}, {adsb_file}   {ts}")


# t = Traffic(pd.read_feather('/Users/espin/repos/paper-2021-DASC-openperf/data-raw/EHAM/EHAM_2019-03-01_history.feather'))
# arrs = t.landing_at('EHAM').eval()
# a = arrs.next('aligned_on_EHAM').eval()
# a.summary(['callsign', 'stop', 'ILS_max']).to_csv("/Users/espin/repos/paper-2021-DASC-openperf/data/EHAM/EHAM_2019-03-01_arrivals_other.csv")
