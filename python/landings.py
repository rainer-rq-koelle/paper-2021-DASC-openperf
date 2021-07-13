from traffic.core import Traffic
import pandas as pd
from pyhere import here, find_root
import glob
import os
import datetime

for adsb_file in glob.iglob(str(here("data-raw")) + '/**/*.feather', recursive=True):
    airport, date, _ = os.path.basename(adsb_file).split('_')
    ts = datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S.%f")
    print(f"Processing {airport} on {date}, {adsb_file}...{ts}")
    t = Traffic(pd.read_feather(adsb_file))
    arrs = (t.landing_at(airport)
        .next(f'aligned_on_{airport}')
        .summary(['callsign', 'stop', 'ILS_max'])
        .to_csv(here("data", airport, f"{airport}_{date}_arrivals.csv"))
    )
    ts = datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S.%f")
    # print(f"Processing {airport} on {date}, {adsb_file}...{ts}")


# t = Traffic(pd.read_feather('/Users/espin/repos/paper-2021-DASC-openperf/data-raw/EHAM/EHAM_2019-03-01_history.feather'))
# arrs = t.landing_at('EHAM').eval()
# a = arrs.next('aligned_on_EHAM').eval()
# a.summary(['callsign', 'stop', 'ILS_max']).to_csv("/Users/espin/repos/paper-2021-DASC-openperf/data/EHAM/EHAM_2019-03-01_arrivals_other.csv")
