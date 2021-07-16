from traffic.core import Traffic
import pandas as pd
from pyhere import here, find_root
import glob
import os
import datetime
import pyarrow as pa
from pathlib import Path


base_dir = str(here("data-raw"))
dest_dir = str(here("data"))
for adsb_file in glob.iglob(base_dir + '/**/*.feather', recursive=True):
    airport, date, _ = os.path.basename(adsb_file).split('_')
    dest_file = Path(dest_dir) /  airport  /  f"{airport}_{date}_arrivals-new.csv"
    if dest_file.exists(): 
        print(f"File {dest_file} exists already...skipping {airport} on {date}.")
        continue
    ts = datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S.%f")
    print(f"Processing {airport} on {date}, {adsb_file}...{ts}")
    print(f"saving result in {dest_file}...")

    t = Traffic(pd.read_feather(adsb_file))
    arrs = (
        t.landing_at(airport)
        .next(f'aligned_on_{airport}')
        .eval(desc="")
        .summary(["callsign", "icao24", "registration", "stop", "ILS_max"])
        .to_csv(dest_file)
    )
    ts = datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S.%f")
    print(f"Processed  {airport} on {date}, {adsb_file}   {ts}")
