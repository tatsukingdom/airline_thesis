// Data Aggregation File for DB1B public database
// Name: Tatsuki Kikugawa

*********************
*** 7. Regression ***
*********************

*******************************
*** 7-0. Summary Statistics ***
*******************************
cd "${rep_folder}"
clear
/*
use "input/dta_clean/${dataset}_agg2", clear

gen coupon_num2 = coupon_num if inlist(coupon_num, 1, 4)
replace coupon_num2 = 3 if coupon_num == 2 & roundtrip == 1
replace coupon_num2 = 2 if coupon_num == 2 & roundtrip == 0
label var coupon_num2 "Ticket type"
label define coupon_num2 1 "1 coupon" 2 "2 coupons/One-way" 3 "2 coupons/roundtrip" 4 "4 coupons"
label values coupon_num2 coupon_num2
hist coupon_num2 [fweight=passenger], freq ///
	barwidth(0.5) ///
	xlabel(, valuelabel) ///
	ytitle("Ticket count (in 10M)") //subtitle("Distribution of ticket type")
graph save Graph "${figs}/fig1_hist_ticket", replace

*** Summary Statistics
cd "${rep_folder}"
use  "input/dta_clean/${dataset}_agg3", clear
eststo data2: estpost summarize fare passenger revenue lcc_ratio_pre  coupon_num roundtrip transfer restricted business first carrier_total carrier_total_lcc market_AS market_VX market_WN 

use  "input/dta_clean/${dataset}_agg3_city", clear
eststo data1: estpost summarize fare passenger revenue lcc_ratio_pre  coupon_num roundtrip transfer restricted business first carrier_total carrier_total_lcc market_AS market_VX market_WN 

use  "input/dta_clean/${dataset}_agg3_ASVX_city", clear
eststo data3: estpost summarize fare passenger revenue lcc_ratio_pre  coupon_num roundtrip transfer restricted business first carrier_total carrier_total_lcc market_AS market_VX market_WN 

use  "input/dta_clean/${dataset}_agg3_ASVXonly_city", clear
eststo data4: estpost summarize fare passenger revenue coupon_num roundtrip transfer restricted business first 

esttab data* using "output/tables/sumstats.tex", replace tex ///
		main(mean %6.2f) aux(sd) ///
		coeflabels(fare "\Centerstack{Market airfaree \\ (mean)}" passenger "Total passengers" revenue "Total revenue" lcc_ratio_pre "Ratio of LCC seats" coupon_num "\Centerstack{Number of coupons \\ (mean)}"roundtrip "\Centerstack{Roundtrip \\ (mean of dummy)}" transfer  "\Centerstack{Transfer \\ (mean of dummy)}" restricted "Ratio of restricted tickets" business "Ratio of business-class" first "Ratio of first-class" carrier_total "Total carriers" carrier_total_lcc "Total LCC carriers" market_AS "\Centerstack{Alaska Route \\ (mean of dummy)}" market_VX "\Centerstack{Virgin Route \\ (mean of dummy)}" market_WN "\Centerstack{Southwest Route \\ (mean of dummy)}") ///
		title("Summary Statistics" \label{sumstats}) ///
		mtitle("\shortstack{Airport-Pair \\ All \\ All Airlines}" "\shortstack{City-Pair \\ All \\ All Airlines}" "\shortstack{City-Pair \\ Alaska+Virgin Markets \\ All Airlines}"  "\shortstack{City-Pair \\ Alaska+Virgin Markets \\ Alaska+Virgin}")
*/

**********************************************
*** 7-1-1. First Difference City-Pair ASVX ***
**********************************************
use  "input/dta_clean/${dataset}_agg3_ASVXonly_city", clear

local dep fare
local post post4

bysort market_id: egen pre_`dep' = mean(`dep') if `post' == 0
qui bysort market_id: egen post_`dep' = mean(`dep') if `post' == 1
qui bysort market_id (pre_`dep'): replace pre_`dep'=pre_`dep'[1]
gen pre_l`dep' = log(pre_`dep')
gen post_l`dep' = log(post_`dep')
gen diff_l`dep' = post_l`dep' - pre_l`dep'
drop post_l`dep' pre_l`dep' post_`dep' pre_`dep'

gen q = substr(string(quarter, "%tq"), -1, .), after(quarter)
egen id_quarter = group(market_id q)
qui bysort id_quarter: egen pre_q`dep' = mean(`dep') if `post' == 0 
qui bysort id_quarter: egen post_q`dep' = mean(`dep') if `post' == 1 
qui bysort id_quarter (pre_q`dep'): replace pre_q`dep'=pre_q`dep'[1]
gen pre_lq`dep' = log(pre_q`dep')
gen post_lq`dep' = log(post_q`dep')
gen diff_lq`dep' = post_lq`dep' - pre_lq`dep'
drop post_lq`dep' pre_lq`dep' post_q`dep' pre_q`dep'
label var diff_lq`dep' "Diff_lqfare"

encode q, gen(q2)
drop q
rename q2 q
qui bysort market_id (lcc_ratio_pre): replace lcc_ratio_pre=lcc_ratio_pre[1] if post4 == 1

local seat_contr restricted business first
local itineary_contr coupon_num roundtrip transfer
local vars `seat_contr' `itineary_contr'
foreach m of local vars{
	qui bysort market_id: egen pre_`m' = mean(`m') if `post' == 0
	qui bysort market_id (pre_`m'): replace pre_`m'=pre_`m'[1]
	gen post_`m' = `m' if `post' == 1
	gen `m'_diff = post_`m' - pre_`m'
	drop pre_`m' post_`m'
}
local seat_contr restricted_diff business_diff first_diff
local itineary_contr coupon_num_diff roundtrip_diff transfer_diff

gen carrier_total_`post' =  carrier_total * `post'
gen carrier_total_lcc_`post' = carrier_total_lcc * `post' 
gen market_WN_`post' = market_WN  * `post'
local interactions carrier_total_`post' carrier_total_lcc_`post' market_WN_`post'

gegen int tag_unique = tag(market_id q) if post4 == 1
order tag_unique, after(diff_lqfare)

reg diff_lq`dep' lcc_ratio_pre if tag_unique == 1, r
	eststo asvx_fd_1
	estadd local qfe "No" : asvx_fd_1

reg diff_lq`dep' lcc_ratio_pre i.q if tag_unique == 1, r
	eststo asvx_fd_2
	estadd local qfe "Yes" : asvx_fd_2
	
reg diff_lq`dep' lcc_ratio_pre i.q `itineary_contr' if tag_unique == 1, r
	eststo asvx_fd_3
	estadd local qfe "Yes" : asvx_fd_3

reg diff_lq`dep' lcc_ratio_pre i.q `itineary_contr' `seat_contr' `interactions' if tag_unique == 1, r
	eststo asvx_fd_4
	estadd local qfe "Yes" : asvx_fd_4

	/*
xi: xtreg diff_lq`dep' lcc_ratio_pre i.q `itineary_contr' `seat_contr' `interactions' if tag_unique == 1, fe vce(robust)
	eststo asvx_fe_5
	estadd local qfe "Yes" : asvx_fe_5
	estadd local mfe "Yes" : asvx_fe_5
	*/

esttab asvx_fd* using "output/tables/asvx_fd.tex", replace booktabs ///
	keep(lcc_ratio_pre `itineary_contr' `seat_contr' `interactions') label b(5) se(5) star(* 0.10 ** 0.05 *** 0.01) noabbrev ///
	coeflabels(lcc_ratio_pre "LCC ratio" coupon_num_diff "Number of coupons" roundtrip_diff "\Centerstack{Roundtrip \\ (dummy)}" transfer_diff "\Centerstack{Transfer \\ (dummy)}" restricted_diff "Restricted seat ratio" business_diff "Business class ratio" first_diff "First class ratio" carrier_total_`post' "Total # of carriers $\times$ Post" carrier_total_lcc_`post' "Total # of LCC carriers $\times$ Post" market_WN_`post' "Southwest dummy $\times$ Post") ///
	stats(qfe N r2, fmt(0 0 a3) ///
		labels("Time FE" "N" "R^2")) ///
	title("\Centerstack{First Difference Regression\\Regression of Alaska/Virgin airfares}" \label{asvxfd})

	
*******************************************
*** 7-1-2. Fixed Effects City-Pair ASVX ***
*******************************************
use  "input/dta_clean/${dataset}_agg3_ASVXonly_city", clear
local dep fare
local post post4
gen lpassenger=log(passenger)
qui bysort market_id (lcc_ratio_pre): replace lcc_ratio_pre=lcc_ratio_pre[1] if post4 == 1
gen lcc_`post' = lcc_ratio_pre * `post'

local seat_contr restricted business first
local itineary_contr coupon_num roundtrip transfer

gen carrier_total_`post' =  carrier_total * `post'
gen carrier_total_lcc_`post' = carrier_total_lcc * `post' 
gen market_WN_`post' = market_WN  * `post'
gen apt_num_origin_`post' = apt_num_origin * `post' 
gen apt_num_destination_city_`post' = apt_num_destination_city * `post'
local interactions carrier_total_`post' carrier_total_lcc_`post' market_WN_`post' apt_num_origin_`post' apt_num_destination_city_`post'

xi: xtreg l`dep' lcc_`post', cluster(market_id)
	eststo asvx_fe_1
	estadd local mfe "No" : asvx_fe_1
	estadd local qfe "No" : asvx_fe_1
	estadd local itinearycontrol "No" : asvx_fe_1
	estadd local control "No" : asvx_fe_1
	
xi: xtreg l`dep' lcc_`post' `itineary_contr', cluster(market_id)
	eststo asvx_fe_2
	estadd local mfe "No" : asvx_fe_2
	estadd local qfe "No" : asvx_fe_2
	estadd local itinearycontrol "Yes" : asvx_fe_2
	estadd local control "No" : asvx_fe_2

xi: xtreg l`dep' lcc_`post' `itineary_contr' `seat_contr' `interactions', cluster(market_id)
	eststo asvx_fe_3
	estadd local mfe "No" : asvx_fe_3
	estadd local qfe "No" : asvx_fe_3
	estadd local itinearycontrol "Yes" : asvx_fe_3
	estadd local control "Yes" : asvx_fe_3
	
xi: xtreg l`dep' lcc_`post' i.quarter, fe cluster(market_id)
	eststo asvx_fe_4
	estadd local mfe "Yes" : asvx_fe_4
	estadd local qfe "Yes" : asvx_fe_4
	estadd local itinearycontrol "No" : asvx_fe_4
	estadd local control "No" : asvx_fe_4

xi: xtreg l`dep' lcc_`post' i.quarter `itineary_contr', fe cluster(market_id)
	eststo asvx_fe_5
	estadd local mfe "Yes" : asvx_fe_5
	estadd local qfe "Yes" : asvx_fe_5
	estadd local itinearycontrol "Yes" : asvx_fe_5
	estadd local control "No" : asvx_fe_5

xi: xtreg l`dep' lcc_`post' i.quarter `itineary_contr' `seat_contr' `interactions', fe cluster(market_id)
	eststo asvx_fe_6
	estadd local mfe "Yes" : asvx_fe_6
	estadd local qfe "Yes" : asvx_fe_6
	estadd local itinearycontrol "Yes" : asvx_fe_6
	estadd local control "Yes" : asvx_fe_6

* Combine all OLS estimates to one table
/*
local dep fare
local post post4
local seat_contr restricted business first
local itineary_contr coupon_num roundtrip transfer
local interactions carrier_total_`post' carrier_total_lcc_`post' market_WN_`post' apt_num_origin_`post' apt_num_destination_city_`post'
*/

esttab asvx_fe_* using "output/tables/asvx_fe.tex", replace booktabs ///
	keep(lcc_`post' `itineary_contr' `seat_contr' `interactions') label b(5) se(5) star(* 0.10 ** 0.05 *** 0.01) noabbrev ///
	coeflabels(lcc_`post' "LCC ratio $\times$ Post" coupon_num "Number of coupons" roundtrip "\shortstack{Roundtrip \\ (dummy)}" transfer "\shortstack{Transfer \\ (dummy)}" restricted "Restricted seat ratio" business "Business class ratio" first "First class ratio" carrier_total_`post' "Total # of carriers $\times$ Post" carrier_total_lcc_`post' "Total # of LCC carriers $\times$ Post" market_WN_`post' "Southwest dummy $\times$ Post" apt_num_origin_`post' "Number of aiports in origin $\times$ Post" apt_num_destination_city_`post' "Number of aiports in destination $\times$ Post") ///
	stats(mfe qfe itinearycontrol control N r2, fmt(0 0 0 0 0 a3) ///
		labels("Market FE" "Time FE" "Itineary Controls" "Other Controls" "N" "R^2")) ///
	title("\Centerstack{Fixed Effects Regression\\Regression of Alaska/Virgin airfares}" \label{asvxfe}) ///
	mgroups("OLS" "Fixed Effects", pattern(1 0 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) 



******************************************
***  7-2. Fixed Effects City-Pair All  ***
******************************************
use  "input/dta_clean/${dataset}_agg3_city", clear

local dep revenue
local post post4
gen lpassenger=log(passenger)
gen market_ASVX = (market_AS > 0 | market_VX > 0)
qui bysort market_id (lcc_ratio_pre): replace lcc_ratio_pre=lcc_ratio_pre[1] if post4 == 1
gen mk_`post' = market_ASVX * `post'
gen lcc_`post' = lcc_ratio_pre * `post'
gen mk_`post'_lcc = mk_`post'*lcc_ratio_pre


local seat_contr restricted business first
local itineary_contr coupon_num roundtrip transfer

gen carrier_total_`post' =  carrier_total * `post'
gen carrier_total_lcc_`post' = carrier_total_lcc * `post' 
gen market_WN_`post' = market_WN  * `post'
gen apt_num_origin_`post' = apt_num_origin * `post' 
gen apt_num_destination_city_`post' = apt_num_destination_city * `post'
local interactions carrier_total_`post' carrier_total_lcc_`post' market_WN_`post' apt_num_origin_`post' apt_num_destination_city_`post'

xi: xtreg l`dep' mk_`post' lcc_`post' mk_`post'_lcc, cluster(market_id)
	eststo any_ols_1
	estadd local mfe "No" : any_ols_1
	estadd local qfe "No" : any_ols_1
	estadd local itinearycontrol "No" : any_ols_1
	estadd local control "No" : any_ols_1
	
xi: xtreg l`dep' mk_`post' lcc_`post' mk_`post'_lcc `itineary_contr', cluster(market_id)
	eststo any_ols_2
	estadd local mfe "No" : any_ols_2
	estadd local qfe "No" : any_ols_2
	estadd local itinearycontrol "Yes" : any_ols_2
	estadd local control "No" : any_ols_2

xi: xtreg l`dep' mk_`post' lcc_`post' mk_`post'_lcc `itineary_contr' `seat_contr' `interactions', cluster(market_id)
	eststo any_ols_3
	estadd local mfe "No" : any_ols_3
	estadd local qfe "No" : any_ols_3
	estadd local itinearycontrol "Yes" : any_ols_3
	estadd local control "Yes" : any_ols_3
	
xi: xtreg l`dep' mk_`post' lcc_`post' mk_`post'_lcc i.quarter, fe cluster(market_id)
	eststo any_ols_4
	estadd local mfe "Yes" : any_ols_4
	estadd local qfe "Yes" : any_ols_4
	estadd local itinearycontrol "No" : any_ols_4
	estadd local control "No" : any_ols_4

xi: xtreg l`dep' mk_`post' lcc_`post' mk_`post'_lcc i.quarter `itineary_contr', fe cluster(market_id)
	eststo any_ols_5
	estadd local mfe "Yes" : any_ols_5
	estadd local qfe "Yes" : any_ols_5
	estadd local itinearycontrol "Yes" : any_ols_5
	estadd local control "No" : any_ols_5

xi: xtreg l`dep' mk_`post' lcc_`post' mk_`post'_lcc i.quarter `itineary_contr' `seat_contr' `interactions', fe cluster(market_id)
	eststo any_ols_6
	estadd local mfe "Yes" : any_ols_6
	estadd local qfe "Yes" : any_ols_6
	estadd local itinearycontrol "Yes" : any_ols_6
	estadd local control "Yes" : any_ols_6

* Combine all OLS estimates to one table
/*
local dep fare
local post post4
local seat_contr restricted business first
local itineary_contr coupon_num roundtrip transfer
local interactions carrier_total_`post' carrier_total_lcc_`post' market_WN_`post' apt_num_origin_`post' apt_num_destination_city_`post'
*/

esttab any_ols* using "output/tables/`post'`dep'.tex", replace booktabs ///
	keep(mk_`post' lcc_`post' mk_`post'_lcc `itineary_contr' `seat_contr' `interactions') label b(5) se(5) star(* 0.10 ** 0.05 *** 0.01) noabbrev ///
	coeflabels(mk_`post' "ASVX market $\times$ Post" lcc_`post' "LCC ratio $\times$ Post" mk_`post'_lcc "ASVX market $\times$ LCC ratio $\times$ Post" coupon_num "Number of coupons" roundtrip "\shortstack{Roundtrip \\ (dummy)}" transfer "\shortstack{Transfer \\ (dummy)}" restricted "Restricted seat ratio" business "Business class ratio" first "First class ratio" carrier_total_`post' "Total # of carriers $\times$ Post" carrier_total_lcc_`post' "Total # of LCC carriers $\times$ Post" market_WN_`post' "Southwest dummy $\times$ Post" apt_num_origin_`post' "Number of aiports in origin $\times$ Post" apt_num_destination_city_`post' "Number of aiports in destination $\times$ Post") ///
	stats(mfe qfe itinearycontrol control N r2, fmt(0 0 0 0 0 a3) ///
		labels("Market FE" "Time FE" "Itineary Controls" "Other Controls" "N" "R^2")) ///
	title("\Centerstack{Fixed Effects Regression\\Regression of All Airlines' \capitalisewords{`dep'}s}" \label{`post'`dep'}) ///
	mgroups("OLS" "Fixed Effects", pattern(1 0 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) 

gen lcc_ratio_group = 0 if inrange(lcc_ratio_pre, 0, 0.1)
replace lcc_ratio_group = 1 if inrange(lcc_ratio_pre, 0.1, 0.3)
replace lcc_ratio_group = 2 if inrange(lcc_ratio_pre, 0.3, 0.6)
replace lcc_ratio_group = 3 if inrange(lcc_ratio_pre, 0.6, 1.0)
label var lcc_ratio_group "LCC Ratio Group"
label define lcc_ratio_group 0 "No LCC" 1 "Low LCC" 2 "Medium LCC" 3 "High LCC"
label values lcc_ratio_group lcc_ratio_group

label var fare "Fare (mean)"
label var post4 "After Jan 2017"
label define post4 0 "Before" 1 "After"
label values post4 post4

label var market_ASVX "Alaska-Virigin market"
label define market_ASVX 0 "No ASVX" 1 "ASVX"
label values market_ASVX market_ASVX

egen mfare = mean(fare), by(lcc_ratio_group)

*graph box fare, over(post4) over(lcc_ratio_group) //medtype(marker) medmarker(msymbol(diamond))
graph box fare, over(market_ASVX) over(post4) over(lcc_ratio_group)
*graph box fare, over(post4) over(market_ASVX) over(lcc_ratio_group)
*graph box fare, over(market_ASVX) over(lcc_ratio_group)		
		

		
		
		

