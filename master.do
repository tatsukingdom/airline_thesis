// 0.Master File
capture log close
clear all

// Change the file directory below.
global rep_folder "/Users/tsukik/Downloads/airline_tatsuki" 

global dataset merged

global image_suffix doc

global tables "${rep_folder}/output/tables"

global figs "${rep_folder}/output/figs"

cd "${rep_folder}"

log using master, replace

* Run data-cleaning file (You can skip this step to generate results)
/*
do "${rep_folder}/code/data_clean.do"

do "${rep_folder}/code/data_preagg.do"

do "${rep_folder}/code/data_aggregation.do"
*/
* Run data-analysis file

do "${rep_folder}/code/analysis.do"

log close
