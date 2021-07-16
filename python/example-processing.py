from traffic.core import Traffic
import os
import pandas as pd

airport = 'EGLL'
date = '2021-04-04'

prj_dir, _ = os.path.split(os.path.realpath(__file__))
adsb_file = f'{prj_dir}/{airport}_{date}_history.feather'

# read, process the data and store results
t = Traffic(pd.read_feather(adsb_file))
arrs = (t.landing_at(airport)
    .next(f'aligned_on_{airport}')
    .summary(['callsign', 'stop', 'ILS_max'])
    .to_csv(f"{prj_dir}/{airport}_{date}_arrivals.csv")
)
