#!/usr/bin/python3

# global reqs
import xarray as xr
import numpy as np
import datetime
import sys
import pdb


# main
if __name__ == "__main__":

    # read cli args
    latfile = sys.argv[1]
    lonfile = sys.argv[2]
    zfile = sys.argv[3]
    day = sys.argv[4]
    hour = sys.argv[5]
    print("_______________________________")
    print(day)
    print(hour)
    print("_______________________________")
    outfile = sys.argv[6]
    
    # read lats and lons from files
    lats = np.sort(np.loadtxt(latfile))
    lats[lats == -0] = 0
    lons = np.sort(np.loadtxt(lonfile))
    lons[lons == -0] = 0
    z = np.loadtxt(zfile)

    # reshape z
    zzz = np.reshape(z, (1, len(lats), len(lons)))
    zzz[zzz == -0] = 0
    zzz[zzz > 9000] = np.nan

    # create dataset
    ds = xr.Dataset(
    
        {"tide": (("time", "lat", "lon"), zzz)},
        coords={
            "lat": lats,
            "lon": lons,
            "time": [datetime.datetime.strptime("%s %s" % (day, hour), "%Y%m%d %H:%M:%S")]
        },
    )
    # ds.time.encoding['units'] = 'days since 1900-01-01'
    
    # generate output netcdf file
    print("Generating %s" % outfile)
    ds.to_netcdf(outfile)
