#!/usr/bin/python3

# reqs
import os
import sys
import xarray as xr

# main
if __name__ == "__main__":

    hour = sys.argv[1]
    srcf = sys.argv[2]
    dest = sys.argv[3]

    print(hour)
    print(srcf)
    print(dest)
    
    datasets = []

    # cycle over files
    print("opening files")
    for f in os.listdir(srcf):

        # open dataset
        if f.endswith("%s.nc" % hour):
            print(f)
            fd = xr.open_dataset(os.path.join(srcf, f))
            datasets.append(fd)
            
    # merge
    print("Merging")
    merged = xr.merge(datasets)

    # replace values
    data00 = merged.sel(lon=0.0).tide
    data03 = merged.sel(lon=0.3).tide
    merged.tide.loc[dict(lon=0.1)] = data00
    merged.tide.loc[dict(lon=0.2)] = data03
    
    # save as netcdf
    outfile = os.path.join(dest, "FINAL_%s.nc" % hour)
    print("Generating %s" % outfile)
    merged.to_netcdf(outfile)
        
