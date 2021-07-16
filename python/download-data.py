from traffic.data import opensky
from traffic.data import airports
from datetime import datetime, timezone
import pyarrow.feather as feather
from pathlib import Path

output_dir = Path(".") / "data-raw"

for airport in ["EGLL", "EHAM", "LSZH"]:
    if not (output_dir / airport).exists():
        (output_dir / airport).mkdir(parents=True)
    for year in [2019, 2020, 2021]:
        for month in [3, 5]:
            for day in range(1, 32):
                date = datetime(year, month, day, 0, 0, 0, tzinfo=timezone.utc)
                filename = f"{airport}_{date:%Y-%m-%d}_history.feather"
                fout = output_dir / airport / filename

                if fout.exists():
                    continue

                t = opensky.history(date, airport=airport)
                if t is None:
                    continue
                t_prep = (
                    t.resample("1s")
                    # keep only flight portions within 200 NM
                    .distance(airports[airport])
                    .query("distance <= 200")
                    .eval(desc="preprocessing", max_workers=4)
                )

                feather.write_feather(t_prep.data, fout)
