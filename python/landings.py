from traffic.core import Traffic
import pandas as pd
from pyhere import here, find_root
import glob
import os

airport = "EGLL"
date = "2019-03-01"
i_file = here("data-raw", airport, f"{airport}_{date}_history.feather")
o_file = here("data", airport, f"{airport}_{date}_arrivals.feather")


for adsb_file in glob.iglob(str(here("data-raw")) + '/**/*.feather', recursive=True):
    airport, date, _ = os.path.basename(adsb_file).split('_')
    t = Traffic(pd.read_feather(adsb_file))
    arrs = (t.landing_at('EGLL')
        .next('aligned_on_EGLL')
        .summary(['callsign', 'stop', 'ILS_max'])
        .to_csv(here("data", airport, f"{airport}_{date}_arrivals.csv"))
    )


# arrs = t.landing_at('EGLL').eval()
# a = arrs.next('aligned_on_EGLL').eval()
# a.summary(['callsign', 'stop', 'ILS_max']).to_csv("/Users/espin/repos/paper-2021-DASC-openperf/data/EGLL/EGLL_2019-03-01_arrivals.csv")
