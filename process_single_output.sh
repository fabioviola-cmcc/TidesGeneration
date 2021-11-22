#!/bin/bash

# read args
ORIGFILE_FN=$1
DATE=$2
CLEAN=$3
DDATE=$(date -d "$DATE" +%d.%m.%Y)

# get the basename
BASEPATH=$(dirname $ORIGFILE_FN)
ORIGFILE_BN=$(basename $ORIGFILE_FN)

# fix "***** Site is out of model grid OR land *****" lines
python replace_land.py ${ORIGFILE_FN} ${DDATE} ${ORIGFILE_FN}_fix
ORIGFILE_FN=${ORIGFILE_FN}_fix
ORIGFILE_BN=$(basename ${ORIGFILE_FN})

# generate lat and lon files
LATFILE_FN=$BASEPATH/lat_${ORIGFILE_BN:8:-8}
LONFILE_FN=$BASEPATH/lon_${ORIGFILE_BN:8:-8}
tail -n +7 ${ORIGFILE_FN} | tr -s " " | cut -d " " -f 2 | sort | uniq > $LATFILE_FN
tail -n +7 ${ORIGFILE_FN} | tr -s " " | cut -d " " -f 3 | sort | uniq > $LONFILE_FN

# generate grid file
GRIDFILE_FN=$BASEPATH/grid_${ORIGFILE_BN:8:-8}
echo "gridtype = latlon" > $GRIDFILE_FN
echo "xsize = $(cat $LONFILE_FN | sort | uniq | wc -l)" >> $GRIDFILE_FN
echo "ysize = $(cat $LATFILE_FN | sort | uniq | wc -l)" >> $GRIDFILE_FN
echo "xvals = $(cat $LONFILE_FN | sort | uniq | tr '\n' ' ')" >> $GRIDFILE_FN
echo "yvals = $(cat $LATFILE_FN | sort | uniq | tr '\n' ' ')" >> $GRIDFILE_FN

# generate z files
for i in $(seq -w 0 23) ; do
    cat $BASEPATH/${ORIGFILE_BN} | tr -s " " | cut -f 2,3,5,6 -d " " | grep "$i:00:00" > ${BASEPATH}/z_${ORIGFILE_BN:8:-8}___$i.out
    cat $BASEPATH/z_${ORIGFILE_BN:8:-8}___${i}.out | cut -f 4 -d " " > $BASEPATH/z_${ORIGFILE_BN:8:-8}___${i}_ready.out
done

# generate netcdf file
for i in $(seq -w 0 23) ; do   
    python ascii2nc.py $LATFILE_FN $LONFILE_FN $BASEPATH/z_${ORIGFILE_BN:8:-8}___${i}_ready.out $DATE "$i:00:00" $BASEPATH/z_${ORIGFILE_BN:8:-8}___${i}.nc
done

# remove temporary files
if [[ $CLEAN -eq 1 ]]; then
    rm $LATFILE_FN
    rm $LONFILE_FN
    rm $GRIDFILE_FN
    rm $BASEPATH/*.out
    rm $BASEPATH/*.fix
fi
