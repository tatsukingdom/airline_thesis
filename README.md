# Description

Replication Code for Tatsuki Kikugawa's paper:
**"The Impact of Existing LCCs on Airfares of a Merged Airline: Evidence from Alaska Airlines-Virgin America Merger"**

This folder contains replication code that replicates publicly replicable figures and tables in the paper using Stata. 
To run the exhibit replication code, update the file path in /code/analysis.do to the location of the replication folder on your computer. Output is saved in /output/

All heavy files (>100MB) cannot be included in this repository, but I am happy to share them upon request (tk802@georgetown.edu)


## Steps:

1. Save the replication code folder in your desired directory and change your stata directory to that location.

2. Open the file master.do and set the global macro on line 6 to be the filepath of the replication folder.

3. Running data cleaning files (data_clean.do, data_preagg.do, and data_aggregation.do) takes at least 12 hours with potential RAM shortage; thus, I recommend commenting out line 22-26 in master.do and just run analysis.do.


## Caveat:
* Don't forget to ssc install ftools gtools.
* Please let me (=Tatsuki) know if you have any question regarding these files. Also, any improvement ideas will be welcomed, especially with regard to file management and coding here!


![Airline Merger](https://s.abcnews.com/images/Business/ht_alaska_airlines_virgin_america_merger_graphic_jc_160404_16x9_992.jpg)
