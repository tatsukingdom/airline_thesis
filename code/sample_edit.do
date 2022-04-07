// Goal 1: Render LCC_ratio to the one wit Virgin
// Goal 2: change FD regression: not use FE
// Goal 3: construct an IND ASVX indicator
cd "${rep_folder}/input"
use "dta_clean/sample", clear
forvalues n=1/4{
	gen ASVX`n' = (market`n'_AS ==1 | market`n'_VX == 1)
}



// Goal 1: Render LCC_ratio to the one wit Virgin


// Goal 2: change FD regression: not use FE


// Goal 3: construct an IND ASVX indicator
gegen int tag_airport1 = tag(market_id AS_indicator4) if 


***********************************
*** 7-1b. OLS/FD City-Pair ASVX ***
***********************************
use  "input/dta_clean/${dataset}_agg3_ASVXonly_city", clear
gen post4 = !inlist(quarter, tq(2015q1), tq(2015q2), tq(2015q3), tq(2015q4), tq(2016q1), tq(2016q2), tq(2016q3), tq(2016q4), tq(2017q1), tq(2017q2), tq(2017q3), tq(2017q4), tq(2018q1))

local dep fare
local post post4

bysort market_id: egen pre_`dep' = mean(`dep') if post1 == 0
qui bysort market_id: egen post_`dep' = mean(`dep') if `post' == 1
qui bysort market_id (pre_`dep'): replace pre_`dep'=pre_`dep'[1]
gen pre_l`dep' = log(pre_`dep')
gen post_l`dep' = log(post_`dep')
gen diff_l`dep' = post_l`dep' - pre_l`dep'
drop post_l`dep' pre_l`dep' post_`dep' pre_`dep'

gen q = substr(string(quarter, "%tq"), -1, .), after(quarter)
egen id_quarter = group(market_id q)
qui bysort id_quarter: egen pre_q`dep' = mean(`dep') if post1 == 0 
qui bysort id_quarter: egen post_q`dep' = mean(`dep') if `post' == 1 
qui bysort id_quarter (pre_q`dep'): replace pre_q`dep'=pre_q`dep'[1]
gen pre_lq`dep' = log(pre_q`dep')
gen post_lq`dep' = log(post_q`dep')
gen diff_lq`dep' = post_lq`dep' - pre_lq`dep'
drop post_lq`dep' pre_lq`dep' post_q`dep' pre_q`dep'
label var diff_lq`dep' "Diff_lfare"

local seat_contr restricted business first
local itineary_contr coupon_num roundtrip transfer
local vars `seat_contr' `itineary_contr'
foreach m of local vars{
	qui bysort market_id: egen pre_`m' = mean(`m') if post1 == 0
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

xi: xtreg diff_lq`dep' lcc_ratio_mkt, vce(robust)
	eststo asvx_fe_1
	estadd local mfe "No" : asvx_fe_1
	estadd local qfe "No" : asvx_fe_1

xi: xtreg diff_lq`dep' lcc_ratio_mkt, fe vce(robust)
	eststo asvx_fe_2
	estadd local mfe "Yes" : asvx_fe_2
	estadd local qfe "No" : asvx_fe_2

xi: xtreg diff_lq`dep' lcc_ratio_mkt i.q, fe vce(robust)
	eststo asvx_fe_3
	estadd local mfe "Yes" : asvx_fe_3
	estadd local qfe "Yes" : asvx_fe_3

xi: xtreg diff_lq`dep' lcc_ratio_mkt i.q `itineary_contr', fe vce(robust)
	eststo asvx_fe_4
	estadd local mfe "Yes" : asvx_fe_4
	estadd local qfe "Yes" : asvx_fe_4

xi: xtreg diff_lq`dep' lcc_ratio_mkt i.q `itineary_contr' `seat_contr' `interactions', fe vce(robust)
	eststo asvx_fe_5
	estadd local mfe "Yes" : asvx_fe_5
	estadd local qfe "Yes" : asvx_fe_5


esttab asvx_fe* using "output/tables/asvx_fe.tex", replace booktabs ///
	keep(lcc_ratio_mkt _Iq_2 _Iq_3 _Iq_4 `itineary_contr' `seat_contr' `interactions') label b(5) se(5) star(* 0.10 ** 0.05 *** 0.01) noabbrev ///
	coeflabels(lcc_ratio_mkt "LCC ratio" _Iq_2 "Q2" _Iq_3 "Q3" _Iq_4 "Q4" coupon_num_diff "Number of coupons" roundtrip_diff "\Centerstack{Roundtrip \\ (dummy)}" transfer_diff "\Centerstack{Transfer \\ (dummy)}" restricted_diff "Restricted seat ratio" business_diff "Business class ratio" first_diff "First class ratio" carrier_total_`post' "Total # of carriers $\times$ Post" carrier_total_lcc_`post' "Total # of LCC carriers $\times$ Post" market_WN_`post' "Southwest dummy $\times$ Post") ///
	stats(mfe qfe N r2, fmt(0 0 0 a3) ///
		labels("Market FE" "Time FE"  "N" "R^2")) ///
	title("First Difference Regression" \label{asvx_fe})
