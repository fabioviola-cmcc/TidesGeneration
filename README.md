# TidesGeneration
Set of scripts to generate tides with **OTPSnc** over a wide domain. To run this you need:

1. OTPSnc in a folder that we may call `$OTPSPATH`
2. This repository inside `$OTPSPATH/bin/` directory
3. The `makeDat.py` script, or something similar, to generate time/lat/lon files

That said, once your requirements are satisfied, you can start your simulation through these steps:

1. Check and adapt the content of `tideGen.conf` to your needs
2. Call `sh invokePredict.sh <YYYYMMDD>`

Please, note that this set of script is experimental! Run it at your own risk :-D For any doubt, please contact me at fabio <dot> viola <at> cmcc <dot> it
