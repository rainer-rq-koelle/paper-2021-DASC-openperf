from traffic.data import opensky
from traffic.data import airports
import pyarrow.feather as feather
import os

airport = 'EGLL'
date = '2021-04-04'

prj_dir, _ = os.path.split(os.path.realpath(__file__))
adsb_file = f'{prj_dir}/{airport}_{date}_history.feather'

# retrieve from OSN
t = opensky.history(date, airport=airport)
t_prep = (
    t.resample("1s")
    # keep only flight portions within 200 NM
    .distance(airports[airport])
    .query("distance <= 200")
    .eval(desc="preprocessing", max_workers=4)
)

feather.write_feather(t_prep.data, adsb_file)
