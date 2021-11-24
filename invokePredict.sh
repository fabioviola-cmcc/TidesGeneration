#!/bin/bash

# read arg
REQDATE=$1

#############################################################
#
# Initial config
#
#############################################################

# debug print
echo "[invokeExtract] -- Configuring environment..."

# load config files
source ./tideGen.conf
source ~/.bash_anaconda_3.8

# modules
module load $MODULES

# load config and profile files
conda activate ${CONDA_ENV}

# create output folder
mkdir -p ${OUTPUT_PATH}
mkdir -p ${WORK_PATH}
ln -sf $SCRIPT_PATH/DATA $WORK_PATH

# go to OTPS folder
cd $SCRIPT_PATH

# count areas to process
COUNTER=0
for LON in $(seq ${MIN_LON} ${LON_STEP} ${MAX_LON}); do
    for LAT in $(seq ${MIN_LAT} ${LAT_STEP} ${MAX_LAT}); do
	    COUNTER=$(echo "$COUNTER + 1" | bc -l)
    done
done
TOTCOUNTER=$COUNTER
echo "== Will process $COUNTER areas"


#############################################################
#
# create date/latlon files
#
#############################################################

# debug info
echo "== Creating $COUNTER time/lat/lon files"

COUNTER=0
for LON in $(seq ${MIN_LON} ${LON_STEP} ${MAX_LON}); do
    for LAT in $(seq ${MIN_LAT} ${LAT_STEP} ${MAX_LAT}); do

	    # increment counter
	    COUNTER=$(echo "$COUNTER + 1" | bc -l)
	    
	    # determine boundaries
	    dw_lat=$LAT
	    dw_lon=$LON
	    up_lat=$(echo "$LAT + $LAT_STEP" | bc -l)
	    up_lon=$(echo "$LON + $LON_STEP" | bc -l)	

	    # call makeDat
	    echo "==== Calling makeDat (${COUNTER} / ${TOTCOUNTER})"
	    BJOBS=$(bjobs -o "job_name" -noheader| grep tides_${REQDATE} | grep -v grep | wc -l)       
	    while [[ $BJOBS -gt $NJOBS ]]; do
	        sleep 5
	        BJOBS=$(bjobs -o "job_name" -noheader| grep tides_${REQDATE} | grep -v grep | wc -l)       
	    done
	    bsub -R "span[ptile=1]" -q ${LSF_QUEUE} -P ${LSF_PROJECT} -J tides_${REQDATE}_${COUNTER} "python ${MAKEDAT} --startDate=$REQDATE --endDate=$REQDATE --outname=${WORK_PATH}/frontex_${LAT}_${LON} --boundingBox=${dw_lon},${dw_lat},${up_lon},${up_lat} --dx=0.1 --dy=0.1"
        
    done
done


BJOBS=$(bjobs -o "job_name" -noheader| grep tides_${REQDATE} | grep -v grep | wc -l)       
while [[ $BJOBS -gt 0 ]]; do
    sleep 5
    BJOBS=$(bjobs -o "job_name" -noheader| grep tides_${REQDATE} | grep -v grep | wc -l)       
done


#############################################################
#
# create setup files
#
#############################################################

# debug info
echo "== Creating $COUNTER config files"

COUNTER=0
for LON in $(seq ${MIN_LON} ${LON_STEP} ${MAX_LON}); do
    for LAT in $(seq ${MIN_LAT} ${LAT_STEP} ${MAX_LAT}); do

	    # increment counter
	    COUNTER=$(echo "$COUNTER + 1" | bc -l)

	    # determine boundaries
	    dw_lat=$LAT
	    dw_lon=$LON
	    up_lat=$(echo "$LAT + $LAT_STEP" | bc -l)
	    up_lon=$(echo "$LON + $LON_STEP" | bc -l)	

	    # create configuration file
	    echo "==== Creating config file (${COUNTER} / ${TOTCOUNTER})"
	    echo "DATA/Model_load" > ${WORK_PATH}/setup_frontex_${LAT}_${LON}
	    echo "${WORK_PATH}/frontex_${LAT}_${LON}.dat" >> ${WORK_PATH}/setup_frontex_${LAT}_${LON}
	    echo "z" >> ${WORK_PATH}/setup_frontex_${LAT}_${LON}
	    echo "m2,s2,k1,o1,n2" >> ${WORK_PATH}/setup_frontex_${LAT}_${LON}
	    echo "AP" >> ${WORK_PATH}/setup_frontex_${LAT}_${LON}
	    echo "geo" >> ${WORK_PATH}/setup_frontex_${LAT}_${LON}
	    echo "1" >> ${WORK_PATH}/setup_frontex_${LAT}_${LON}
	    echo "${WORK_PATH}/frontex_${LAT}_${LON}.out" >> ${WORK_PATH}/setup_frontex_${LAT}_${LON}

    done
done


#############################################################
#
# create tides
#
#############################################################

# debug info
echo "== Creating $COUNTER instances of the OTPS model"

cd $WORK_PATH
COUNTER=0
for LON in $(seq ${MIN_LON} ${LON_STEP} ${MAX_LON}); do
    for LAT in $(seq ${MIN_LAT} ${LAT_STEP} ${MAX_LAT}); do

	    # increment counter
	    COUNTER=$(echo "$COUNTER + 1" | bc -l)

	    # determine boundaries
	    dw_lat=$LAT
	    dw_lon=$LON
	    up_lat=$(echo "$LAT + $LAT_STEP" | bc -l)
	    up_lon=$(echo "$LON + $LON_STEP" | bc -l)	

	    # call predict (but wait if there are 50 processes already submitted)
	    echo "==== Calling PredictTides (${COUNTER} / ${TOTCOUNTER})"
	    BJOBS=$(bjobs -o "job_name" -noheader| grep tides_${REQDATE} | grep -v grep | wc -l)       
	    while [[ $BJOBS -gt $NJOBS ]]; do
	        sleep 5
	        BJOBS=$(bjobs -o "job_name" -noheader| grep tides_${REQDATE} | grep -v grep | wc -l)       
	    done
	    bsub -R "span[ptile=1]" -q ${LSF_QUEUE} -P ${LSF_PROJECT} -J tides_${REQDATE}_${COUNTER} "$SCRIPT_EXE < $WORK_PATH/setup_frontex_${LAT}_${LON}"

    done    
done

sleep 10

BJOBS=$(bjobs -o "job_name" -noheader| grep tides_${REQDATE} | grep -v grep | wc -l)
while [[ $BJOBS -gt 0 ]]; do
    sleep 5
    BJOBS=$(bjobs -o "job_name" -noheader| grep tides_${REQDATE} | grep -v grep | wc -l)       
done


#############################################################
#
# produce netcdf files for all the sub-areas and ts 
#
#############################################################

# debug info
echo "== Creating NetCDF files"

cd $SCRIPT_PATH

# iterate over .out files
COUNTER=0
for INFILE in $(ls ${WORK_PATH}/frontex*.out) ; do

    # debug print
    echo "==== Processing file $ORIGFILE_FN ($COUNTER / $TOTCOUNTER)"
    
    # create netcdf file
    BJOBS=$(bjobs -o "job_name" -noheader| grep tides_${REQDATE} | grep -v grep | wc -l)
    while [[ $BJOBS -gt $NJOBS ]]; do
	    sleep 5
	    BJOBS=$(bjobs -o "job_name" -noheader| grep tides_${REQDATE} | grep -v grep | wc -l)       
    done
    echo $INFILE
    bsub -R "span[ptile=1]" -q ${LSF_QUEUE} -P ${LSF_PROJECT} -J tides_${REQDATE}_${COUNTER} "sh ${SCRIPT_PATH}/process_single_output.sh $INFILE $REQDATE $CLEAN"

    # increment counter
    COUNTER=$(echo "$COUNTER + 1" | bc -l)
    
done

BJOBS=$(bjobs -o "job_name" -noheader| grep tides_${REQDATE} | grep -v grep | wc -l)       
while [[ $BJOBS -gt 0 ]]; do
    sleep 5
    BJOBS=$(bjobs -o "job_name" -noheader| grep tides_${REQDATE} | grep -v grep | wc -l)       
done


#############################################################
#
# UNIFY
#
#############################################################

# loop over hours
COUNTER=0
for i in $(seq -w 0 23); do

    BJOBS=$(bjobs -o "job_name" -noheader| grep tides_${REQDATE} | grep -v grep | wc -l)
    while [[ $BJOBS -gt 4 ]]; do
	    sleep 5
	    BJOBS=$(bjobs -o "job_name" -noheader| grep tides_${REQDATE} | grep -v grep | wc -l)       
    done
    
    # invoke python unify
    bsub -R "span[ptile=1]" -q ${LSF_QUEUE} -P ${LSF_PROJECT} -J tides_${REQDATE}_${COUNTER} "python ${SCRIPT_PATH}/unify.py $i ${WORK_PATH} ${OUTPUT_PATH}"
    sleep 5
    
    # increment counter
    COUNTER=$(echo "$COUNTER + 1" | bc -l)
    
done

BJOBS=$(bjobs -o "job_name" -noheader| grep tides_${REQDATE} | grep -v grep | wc -l)       
while [[ $BJOBS -gt 0 ]]; do
    sleep 5
    BJOBS=$(bjobs -o "job_name" -noheader| grep tides_${REQDATE} | grep -v grep | wc -l)
done


#############################################################
#
# SET T AXIS
#
#############################################################

for HOUR in $(seq -w 0 23); do

    YEAR=${REQDATE:0:4}
    MONTH=${REQDATE:4:2}
    DAY=${REQDATE:6:2}
    
    cdo -r -f nc settaxis,$YEAR-$MONTH-$DAY,$HOUR:00:00,1day ${OUTPUT_PATH}/FINAL_${HOUR}.nc ${OUTPUT_PATH}/${HOUR}.nc 
    mv ${OUTPUT_PATH}/$HOUR.nc ${OUTPUT_PATH}/FINAL_${HOUR}.nc
done


#############################################################
#
# FINAL CLEAN
#
#############################################################

echo "== Final clean..."
if [[ $CLEAN -eq 1 ]]; then
    echo "==== ...in progress"
    rm -rf $WORK_PATH
else
    echo "==== ...skipped! Check settings!"
fi
