// 3.Data Aggregation File for DB1B public database
// Name: Tatsuki Kikugawa

**********************************
*** 6.Aggregation and Cleaning ***
**********************************
************************
*** 6-1. Airport All ***
************************
cd "${rep_folder}/input"
use "dta_clean/${dataset}_agg2", clear

collapse (rawsum) revenue passenger passenger_lcc1-passenger_lcc4 passenger_ASVX1-passenger_ASVX4 (mean) fareI coupon_num roundtrip transfer restricted1-restricted4 business1-business4 first1-first4 carrier1_total-carrier4_total carrier1_total_lcc-carrier4_total_lcc market1_AS-market4_AS market1_VX-market4_VX market1_WN-market4_WN coupon_total1-coupon_total4 [fw = passenger], by(quarter market_id origin destination)
keep if passenger >= 90
rename fareI fare
gen lfare = log(fare), after(fare)
gen lrevenue = log(revenue), after(revenue)
tsset market_id quarter, quarterly
count if inlist(origin, "SFF", "BST", "OLD", "CLV", "DTR", "HST", "LSA", "MAM", "TMP") | inlist(destination, "SFF", "BST", "OLD", "CLV", "DTR", "HST", "LSA", "MAM", "TMP")

* Compute weighted_average
gen coupon_total = coupon_total1 if coupon_total2 == .
replace coupon_total = coupon_total1+coupon_total2 if coupon_total3 == . & coupon_total2 != .
replace coupon_total = coupon_total1+coupon_total2+coupon_total3 if coupon_total4 == . & coupon_total3 != .
replace coupon_total = coupon_total1+coupon_total2+coupon_total3+coupon_total4 if coupon_total4 != .

local weighted passenger_lcc passenger_ASVX restricted business first
foreach m of local weighted{
	gen `m' = (`m'1*coupon_total1)/coupon_total if coupon_total2==., before(`m'1)
	replace `m' = (`m'1*coupon_total1+`m'2*coupon_total2)/coupon_total if coupon_total3 == . & coupon_total2 != .
	replace `m' = (`m'1*coupon_total1+`m'2*coupon_total2+`m'3*coupon_total3)/coupon_total if coupon_total4 == . & coupon_total3 != .
	replace `m' = (`m'1*coupon_total1+`m'2*coupon_total2+`m'3*coupon_total3+`m'4*coupon_total4)/coupon_total if coupon_total4 != .
}

local airlines AS VX WN
foreach m of local airlines{
	gen market_`m' = (market1_`m'*coupon_total1)/coupon_total if coupon_total2==., before(market1_`m')
	replace market_`m' = (market1_`m'*coupon_total1+market2_`m'*coupon_total2)/coupon_total if coupon_total3 == . & coupon_total2 != .
	replace market_`m' = (market1_`m'*coupon_total1+market2_`m'*coupon_total2+market3_`m'*coupon_total3)/coupon_total if coupon_total4 == . & coupon_total3 != .
	replace market_`m' = (market1_`m'*coupon_total1+market2_`m'*coupon_total2+market3_`m'*coupon_total3+market4_`m'*coupon_total4)/coupon_total if coupon_total4 != .
}

local binary _total _total_lcc
foreach m of local binary{
	gen carrier`m' = (carrier1`m'*coupon_total1)/coupon_total if coupon_total2==., before(carrier1`m')
	replace carrier`m' = (carrier1`m'*coupon_total1+carrier2`m'*coupon_total2)/coupon_total if coupon_total3 == . & coupon_total2 != .
	replace carrier`m' = (carrier1`m'*coupon_total1+carrier2`m'*coupon_total2+carrier3`m'*coupon_total3)/coupon_total if coupon_total4 == . & coupon_total3 != .
	replace carrier`m' = (carrier1`m'*coupon_total1+carrier2`m'*coupon_total2+carrier3`m'*coupon_total3+carrier4`m'*coupon_total4)/coupon_total if coupon_total4 != .
}

* Quarter dummy 
forvalues n=1/4{
	gen quarter`n' = inlist(quarter, tq(2015q`n'), tq(2016q`n'), tq(2017q`n'), tq(2018q`n'), tq(2019q`n'))
}
drop quarter1

* Post dummy
gen post1 = !inlist(quarter, tq(2015q1), tq(2015q2), tq(2015q3), tq(2015q4), tq(2016q1), tq(2016q2), tq(2016q3), tq(2016q4))
gen post2 = !inlist(quarter, tq(2015q1), tq(2015q2), tq(2015q3), tq(2015q4), tq(2016q1), tq(2016q2), tq(2016q3), tq(2016q4), tq(2017q1), tq(2017q2))
gen post3 = !inlist(quarter, tq(2015q1), tq(2015q2), tq(2015q3), tq(2015q4), tq(2016q1), tq(2016q2), tq(2016q3), tq(2016q4), tq(2017q1), tq(2017q2), tq(2017q3), tq(2017q4))
gen post4 = !inlist(quarter, tq(2015q1), tq(2015q2), tq(2015q3), tq(2015q4), tq(2016q1), tq(2016q2), tq(2016q3), tq(2016q4), tq(2017q1), tq(2017q2), tq(2017q3), tq(2017q4), tq(2018q1))

* lcc-market share in each market
gen lcc_ratio = passenger_lcc / passenger
gegen long lcc_ratio_pre1 = total(passenger_lcc) if post4 == 0, by(market_id)
gegen long lcc_ratio_pre2 = total(passenger) if post4 == 0, by(market_id)
gen lcc_ratio_pre = lcc_ratio_pre1 / lcc_ratio_pre2

drop passenger_lcc1-passenger_lcc4 passenger_ASVX1-passenger_ASVX4 restricted1-restricted4 business1-business4 first1-first4 carrier1_total-carrier4_total carrier1_total_lcc-carrier4_total_lcc market1_AS-market4_AS market1_VX-market4_VX market1_WN-market4_WN coupon_total1-coupon_total4 lcc_ratio_pre1 lcc_ratio_pre2

/* Merge with lookup tables
save "dta_clean/${dataset}_agg3", replace
import delimited "lookup/airports_codes.txt", clear 
drop worldareacode
rename airportcode origin
save "lookup/airport_code_origin", replace
rename origin destination
save "lookup/airport_code_destination", replace
use "dta_clean/${dataset}_agg3", clear
*/

local citytype origin destination
foreach m of local citytype {
	merge m:1 `m' using "lookup/airport_code_`m'"
	drop if _merge == 2
	replace cityname = "Phoenix, Arizona, USA" if `m' == "AZA"
	replace cityname = "Branson, Missouri, USA" if `m' == "BKG"
	replace cityname = "Bay County, Florida, USA" if `m' == "ECP"
	replace cityname = "Concord, North Carolina, USA" if inlist(`m', "JQF", "USA")
	drop if inlist(`m', "DSS", "ICN", "PVG") 
	drop _merge
	rename cityname `m'_name
	split `m'_name, parse(,)
	replace `m'_name3 = strtrim(`m'_name3)
	replace `m'_name4 = strtrim(`m'_name4)
	drop if `m'_name3 != "USA" & `m'_name4 != "USA"
	drop `m'_name1-`m'_name4
}

tsset market_id quarter, quarterly
save "dta_clean/${dataset}_agg3", replace


*************************
*** 6-2. Airport ASVX ***
*************************
use  "dta_clean/${dataset}_agg2_ASVX", clear

collapse (rawsum) revenue passenger passenger_lcc1-passenger_lcc4 passenger_ASVX1-passenger_ASVX4 (mean) fareI coupon_num roundtrip transfer restricted1-restricted4 business1-business4 first1-first4 carrier1_total-carrier4_total carrier1_total_lcc-carrier4_total_lcc market1_AS-market4_AS market1_VX-market4_VX market1_WN-market4_WN coupon_total1-coupon_total4 [fw = passenger], by(quarter market_id origin destination)
keep if passenger >= 90
rename fareI fare
gen lfare = log(fare), after(fare)
gen lrevenue = log(revenue), after(revenue)
tsset market_id quarter, quarterly

* Compute weighted_average
gen coupon_total = coupon_total1 if coupon_total2 == .
replace coupon_total = coupon_total1+coupon_total2 if coupon_total3 == . & coupon_total2 != .
replace coupon_total = coupon_total1+coupon_total2+coupon_total3 if coupon_total4 == . & coupon_total3 != .
replace coupon_total = coupon_total1+coupon_total2+coupon_total3+coupon_total4 if coupon_total4 != .

local weighted passenger_lcc passenger_ASVX restricted business first
foreach m of local weighted{
	gen `m' = (`m'1*coupon_total1)/coupon_total if coupon_total2==., before(`m'1)
	replace `m' = (`m'1*coupon_total1+`m'2*coupon_total2)/coupon_total if coupon_total3 == . & coupon_total2 != .
	replace `m' = (`m'1*coupon_total1+`m'2*coupon_total2+`m'3*coupon_total3)/coupon_total if coupon_total4 == . & coupon_total3 != .
	replace `m' = (`m'1*coupon_total1+`m'2*coupon_total2+`m'3*coupon_total3+`m'4*coupon_total4)/coupon_total if coupon_total4 != .
}

local airlines AS VX WN
foreach m of local airlines{
	gen market_`m' = (market1_`m'*coupon_total1)/coupon_total if coupon_total2==., before(market1_`m')
	replace market_`m' = (market1_`m'*coupon_total1+market2_`m'*coupon_total2)/coupon_total if coupon_total3 == . & coupon_total2 != .
	replace market_`m' = (market1_`m'*coupon_total1+market2_`m'*coupon_total2+market3_`m'*coupon_total3)/coupon_total if coupon_total4 == . & coupon_total3 != .
	replace market_`m' = (market1_`m'*coupon_total1+market2_`m'*coupon_total2+market3_`m'*coupon_total3+market4_`m'*coupon_total4)/coupon_total if coupon_total4 != .
}

local binary _total _total_lcc
foreach m of local binary{
	gen carrier`m' = (carrier1`m'*coupon_total1)/coupon_total if coupon_total2==., before(carrier1`m')
	replace carrier`m' = (carrier1`m'*coupon_total1+carrier2`m'*coupon_total2)/coupon_total if coupon_total3 == . & coupon_total2 != .
	replace carrier`m' = (carrier1`m'*coupon_total1+carrier2`m'*coupon_total2+carrier3`m'*coupon_total3)/coupon_total if coupon_total4 == . & coupon_total3 != .
	replace carrier`m' = (carrier1`m'*coupon_total1+carrier2`m'*coupon_total2+carrier3`m'*coupon_total3+carrier4`m'*coupon_total4)/coupon_total if coupon_total4 != .
}

* Quarter dummy 
forvalues n=1/4{
	gen quarter`n' = inlist(quarter, tq(2015q`n'), tq(2016q`n'), tq(2017q`n'), tq(2018q`n'), tq(2019q`n'))
}
drop quarter1

* Post dummy
gen post1 = !inlist(quarter, tq(2015q1), tq(2015q2), tq(2015q3), tq(2015q4), tq(2016q1), tq(2016q2), tq(2016q3), tq(2016q4))
gen post2 = !inlist(quarter, tq(2015q1), tq(2015q2), tq(2015q3), tq(2015q4), tq(2016q1), tq(2016q2), tq(2016q3), tq(2016q4), tq(2017q1), tq(2017q2))
gen post3 = !inlist(quarter, tq(2015q1), tq(2015q2), tq(2015q3), tq(2015q4), tq(2016q1), tq(2016q2), tq(2016q3), tq(2016q4), tq(2017q1), tq(2017q2), tq(2017q3), tq(2017q4))
gen post4 = !inlist(quarter, tq(2015q1), tq(2015q2), tq(2015q3), tq(2015q4), tq(2016q1), tq(2016q2), tq(2016q3), tq(2016q4), tq(2017q1), tq(2017q2), tq(2017q3), tq(2017q4), tq(2018q1))

* lcc-market share in each market
gen lcc_ratio = passenger_lcc / passenger
gegen long lcc_ratio_pre1 = total(passenger_lcc) if post4 == 0, by(market_id)
gegen long lcc_ratio_pre2 = total(passenger) if post4 == 0, by(market_id)
gen lcc_ratio_pre = lcc_ratio_pre1 / lcc_ratio_pre2

drop passenger_lcc1-passenger_lcc4 passenger_ASVX1-passenger_ASVX4 restricted1-restricted4 business1-business4 first1-first4 carrier1_total-carrier4_total carrier1_total_lcc-carrier4_total_lcc market1_AS-market4_AS market1_VX-market4_VX market1_WN-market4_WN coupon_total1-coupon_total4 lcc_ratio_pre1 lcc_ratio_pre2

local citytype origin destination
foreach m of local citytype {
	merge m:1 `m' using "lookup/airport_code_`m'"
	drop if _merge == 2
	replace cityname = "Phoenix, Arizona, USA" if `m' == "AZA"
	replace cityname = "Branson, Missouri, USA" if `m' == "BKG"
	replace cityname = "Bay County, Florida, USA" if `m' == "ECP"
	replace cityname = "Concord, North Carolina, USA" if inlist(`m', "JQF", "USA")
	drop if inlist(`m', "DSS", "ICN", "PVG") 
	drop _merge
	rename cityname `m'_name
	split `m'_name, parse(,)
	replace `m'_name3 = strtrim(`m'_name3)
	replace `m'_name4 = strtrim(`m'_name4)
	drop if `m'_name3 != "USA" & `m'_name4 != "USA"
	drop `m'_name1-`m'_name4
}

tsset market_id quarter, quarterly
save "dta_clean/${dataset}_agg3_ASVX", replace


*****************************
*** 6-3. Airport ASVXonly ***
*****************************
use  "dta_clean/${dataset}_agg2_ASVXonly", clear

collapse (rawsum) revenue passenger passenger_lcc1-passenger_lcc4 passenger_ASVX1-passenger_ASVX4 (mean) fareI coupon_num roundtrip transfer restricted1-restricted4 business1-business4 first1-first4 carrier1_total-carrier4_total carrier1_total_lcc-carrier4_total_lcc market1_AS-market4_AS market1_VX-market4_VX market1_WN-market4_WN coupon_total1-coupon_total4 [fw = passenger], by(quarter market_id origin destination)
keep if passenger >= 30
rename fareI fare
gen lfare = log(fare), after(fare)
gen lrevenue = log(revenue), after(revenue)
tsset market_id quarter, quarterly


* Compute weighted_average
gen coupon_total = coupon_total1 if coupon_total2 == .
replace coupon_total = coupon_total1+coupon_total2 if coupon_total3 == . & coupon_total2 != .
replace coupon_total = coupon_total1+coupon_total2+coupon_total3 if coupon_total4 == . & coupon_total3 != .
replace coupon_total = coupon_total1+coupon_total2+coupon_total3+coupon_total4 if coupon_total4 != .

local weighted passenger_lcc passenger_ASVX restricted business first
foreach m of local weighted{
	gen `m' = (`m'1*coupon_total1)/coupon_total if coupon_total2==., before(`m'1)
	replace `m' = (`m'1*coupon_total1+`m'2*coupon_total2)/coupon_total if coupon_total3 == . & coupon_total2 != .
	replace `m' = (`m'1*coupon_total1+`m'2*coupon_total2+`m'3*coupon_total3)/coupon_total if coupon_total4 == . & coupon_total3 != .
	replace `m' = (`m'1*coupon_total1+`m'2*coupon_total2+`m'3*coupon_total3+`m'4*coupon_total4)/coupon_total if coupon_total4 != .
}

local airlines AS VX WN
foreach m of local airlines{
	gen market_`m' = (market1_`m'*coupon_total1)/coupon_total if coupon_total2==., before(market1_`m')
	replace market_`m' = (market1_`m'*coupon_total1+market2_`m'*coupon_total2)/coupon_total if coupon_total3 == . & coupon_total2 != .
	replace market_`m' = (market1_`m'*coupon_total1+market2_`m'*coupon_total2+market3_`m'*coupon_total3)/coupon_total if coupon_total4 == . & coupon_total3 != .
	replace market_`m' = (market1_`m'*coupon_total1+market2_`m'*coupon_total2+market3_`m'*coupon_total3+market4_`m'*coupon_total4)/coupon_total if coupon_total4 != .
}

local binary _total _total_lcc
foreach m of local binary{
	gen carrier`m' = (carrier1`m'*coupon_total1)/coupon_total if coupon_total2==., before(carrier1`m')
	replace carrier`m' = (carrier1`m'*coupon_total1+carrier2`m'*coupon_total2)/coupon_total if coupon_total3 == . & coupon_total2 != .
	replace carrier`m' = (carrier1`m'*coupon_total1+carrier2`m'*coupon_total2+carrier3`m'*coupon_total3)/coupon_total if coupon_total4 == . & coupon_total3 != .
	replace carrier`m' = (carrier1`m'*coupon_total1+carrier2`m'*coupon_total2+carrier3`m'*coupon_total3+carrier4`m'*coupon_total4)/coupon_total if coupon_total4 != .
}

* Quarter dummy 
forvalues n=1/4{
	gen quarter`n' = inlist(quarter, tq(2015q`n'), tq(2016q`n'), tq(2017q`n'), tq(2018q`n'), tq(2019q`n'))
}
drop quarter1

* Post dummy
gen post1 = !inlist(quarter, tq(2015q1), tq(2015q2), tq(2015q3), tq(2015q4), tq(2016q1), tq(2016q2), tq(2016q3), tq(2016q4))
gen post2 = !inlist(quarter, tq(2015q1), tq(2015q2), tq(2015q3), tq(2015q4), tq(2016q1), tq(2016q2), tq(2016q3), tq(2016q4), tq(2017q1), tq(2017q2))
gen post3 = !inlist(quarter, tq(2015q1), tq(2015q2), tq(2015q3), tq(2015q4), tq(2016q1), tq(2016q2), tq(2016q3), tq(2016q4), tq(2017q1), tq(2017q2), tq(2017q3), tq(2017q4))
gen post4 = !inlist(quarter, tq(2015q1), tq(2015q2), tq(2015q3), tq(2015q4), tq(2016q1), tq(2016q2), tq(2016q3), tq(2016q4), tq(2017q1), tq(2017q2), tq(2017q3), tq(2017q4), tq(2018q1))

* lcc-market share in each market
gen lcc_ratio_all = passenger_lcc / passenger
gegen long lcc_ratio_pre1 = total(passenger_lcc) if post4 == 0, by(market_id)
gegen long lcc_ratio_pre2 = total(passenger) if post4 == 0, by(market_id)
gen lcc_ratio_pre = lcc_ratio_pre1 / lcc_ratio_pre2

drop passenger_lcc1-passenger_lcc4 passenger_ASVX1-passenger_ASVX4 restricted1-restricted4 business1-business4 first1-first4 carrier1_total-carrier4_total carrier1_total_lcc-carrier4_total_lcc market1_AS-market4_AS market1_VX-market4_VX market1_WN-market4_WN coupon_total1-coupon_total4 lcc_ratio_pre1 lcc_ratio_pre2

local citytype origin destination
foreach m of local citytype {
	merge m:1 `m' using "lookup/airport_code_`m'"
	drop if _merge == 2
	replace cityname = "Phoenix, Arizona, USA" if `m' == "AZA"
	replace cityname = "Branson, Missouri, USA" if `m' == "BKG"
	replace cityname = "Bay County, Florida, USA" if `m' == "ECP"
	replace cityname = "Concord, North Carolina, USA" if inlist(`m', "JQF", "USA")
	drop if inlist(`m', "DSS", "ICN", "PVG") 
	drop _merge
	rename cityname `m'_name
	split `m'_name, parse(,)
	replace `m'_name3 = strtrim(`m'_name3)
	replace `m'_name4 = strtrim(`m'_name4)
	drop if `m'_name3 != "USA" & `m'_name4 != "USA"
	drop `m'_name1-`m'_name4
}

tsset market_id quarter, quarterly
save "dta_clean/${dataset}_agg3_ASVXonly", replace


*********************
*** 6-4. City All ***
*********************
use "dta_clean/${dataset}_agg2_city", clear

collapse (rawsum) revenue passenger passenger_lcc1-passenger_lcc4 passenger_ASVX1-passenger_ASVX4 (mean) fareI coupon_num roundtrip transfer restricted1-restricted4 business1-business4 first1-first4 carrier1_total-carrier4_total carrier1_total_lcc-carrier4_total_lcc market1_AS-market4_AS market1_VX-market4_VX market1_WN-market4_WN coupon_total1-coupon_total4 apt_num_origin_city apt_num_destination_city total_passenger_lcc1-total_passenger_lcc4 [fw = passenger], by(quarter market_id_city origin_city destination_city)
keep if passenger >= 90
rename (fareI origin_city destination_city market_id_city) (fare origin destination market_id)
gen lfare = log(fare), after(fare)
gen lrevenue = log(revenue), after(revenue)
tsset market_id quarter, quarterly

* Compute weighted_average
gen coupon_total = coupon_total1 if coupon_total2 == .
replace coupon_total = coupon_total1+coupon_total2 if coupon_total3 == . & coupon_total2 != .
replace coupon_total = coupon_total1+coupon_total2+coupon_total3 if coupon_total4 == . & coupon_total3 != .
replace coupon_total = coupon_total1+coupon_total2+coupon_total3+coupon_total4 if coupon_total4 != .

local weighted total_passenger_lcc passenger_lcc passenger_ASVX restricted business first
foreach m of local weighted{
	gen `m' = (`m'1*coupon_total1)/coupon_total if coupon_total2==., before(`m'1)
	replace `m' = (`m'1*coupon_total1+`m'2*coupon_total2)/coupon_total if coupon_total3 == . & coupon_total2 != .
	replace `m' = (`m'1*coupon_total1+`m'2*coupon_total2+`m'3*coupon_total3)/coupon_total if coupon_total4 == . & coupon_total3 != .
	replace `m' = (`m'1*coupon_total1+`m'2*coupon_total2+`m'3*coupon_total3+`m'4*coupon_total4)/coupon_total if coupon_total4 != .
}

local airlines AS VX WN
foreach m of local airlines{
	gen market_`m' = (market1_`m'*coupon_total1)/coupon_total if coupon_total2==., before(market1_`m')
	replace market_`m' = (market1_`m'*coupon_total1+market2_`m'*coupon_total2)/coupon_total if coupon_total3 == . & coupon_total2 != .
	replace market_`m' = (market1_`m'*coupon_total1+market2_`m'*coupon_total2+market3_`m'*coupon_total3)/coupon_total if coupon_total4 == . & coupon_total3 != .
	replace market_`m' = (market1_`m'*coupon_total1+market2_`m'*coupon_total2+market3_`m'*coupon_total3+market4_`m'*coupon_total4)/coupon_total if coupon_total4 != .
}

local binary _total _total_lcc
foreach m of local binary{
	gen carrier`m' = (carrier1`m'*coupon_total1)/coupon_total if coupon_total2==., before(carrier1`m')
	replace carrier`m' = (carrier1`m'*coupon_total1+carrier2`m'*coupon_total2)/coupon_total if coupon_total3 == . & coupon_total2 != .
	replace carrier`m' = (carrier1`m'*coupon_total1+carrier2`m'*coupon_total2+carrier3`m'*coupon_total3)/coupon_total if coupon_total4 == . & coupon_total3 != .
	replace carrier`m' = (carrier1`m'*coupon_total1+carrier2`m'*coupon_total2+carrier3`m'*coupon_total3+carrier4`m'*coupon_total4)/coupon_total if coupon_total4 != .
}

* Quarter dummy 
forvalues n=1/4{
	gen quarter`n' = inlist(quarter, tq(2015q`n'), tq(2016q`n'), tq(2017q`n'), tq(2018q`n'), tq(2019q`n'))
}
drop quarter1

* Post dummy
gen post1 = !inlist(quarter, tq(2015q1), tq(2015q2), tq(2015q3), tq(2015q4), tq(2016q1), tq(2016q2), tq(2016q3), tq(2016q4))
gen post2 = !inlist(quarter, tq(2015q1), tq(2015q2), tq(2015q3), tq(2015q4), tq(2016q1), tq(2016q2), tq(2016q3), tq(2016q4), tq(2017q1), tq(2017q2))
gen post3 = !inlist(quarter, tq(2015q1), tq(2015q2), tq(2015q3), tq(2015q4), tq(2016q1), tq(2016q2), tq(2016q3), tq(2016q4), tq(2017q1), tq(2017q2), tq(2017q3), tq(2017q4))
gen post4 = !inlist(quarter, tq(2015q1), tq(2015q2), tq(2015q3), tq(2015q4), tq(2016q1), tq(2016q2), tq(2016q3), tq(2016q4), tq(2017q1), tq(2017q2), tq(2017q3), tq(2017q4), tq(2018q1))

* lcc-market share in each market
gen lcc_ratio = passenger_lcc / passenger
gegen long lcc_ratio_pre1 = total(passenger_lcc) if post4 == 0, by(market_id)
gegen long lcc_ratio_pre2 = total(passenger) if post4 == 0, by(market_id)
gen lcc_ratio_pre = lcc_ratio_pre1 / lcc_ratio_pre2

drop passenger_lcc1-passenger_lcc4 total_passenger_lcc1-total_passenger_lcc4 passenger_ASVX1-passenger_ASVX4 restricted1-restricted4 business1-business4 first1-first4 carrier1_total-carrier4_total carrier1_total_lcc-carrier4_total_lcc market1_AS-market4_AS market1_VX-market4_VX market1_WN-market4_WN coupon_total1-coupon_total4 lcc_ratio_pre1 lcc_ratio_pre2

* Merge with lookup tables
/*
save "dta_clean/${dataset}_agg3_city", replace
import delimited "lookup/airports_codes.txt", clear 
drop worldareacode
rename airportcode origin
drop if inlist(origin, "SFF", "BST", "OLD", "CLV", "DTR")
drop if inlist(origin, "HST", "LSA", "MAM", "TMP", "CNC")
set obs `=_N+13'
replace origin = "WDC" if _n == _N
replace cityname = "Washington D.C., D.C., USA" if _n == _N
replace origin = "SFF" if _n == _N-1
replace cityname = "San Francisco, California, USA" if _n == _N-1
replace origin = "BST" if _n == _N-2
replace cityname = "Boston, Massachusettes, USA" if _n == _N-2
replace origin = "OLD" if _n == _N-3
replace cityname = "Chicago, Illinois, USA" if _n == _N-3
replace origin = "CNC" if _n == _N-4
replace cityname = "Cincinnati, Kentucky, USA" if _n == _N-4
replace origin = "CLV" if _n == _N-5
replace cityname = "Cleveland, Ohio, USA" if _n == _N-5
replace origin = "DFO" if _n == _N-6
replace cityname = "Dallas-Fort Worth, Texas, USA" if _n == _N-6
replace origin = "DTR" if _n == _N-7
replace cityname = "Detroit, Michigan, USA" if _n == _N-7
replace origin = "HST" if _n == _N-8
replace cityname = "Houston, Texas, USA" if _n == _N-8
replace origin = "LSA" if _n == _N-9
replace cityname = "Los Angels, California, USA" if _n == _N-9
replace origin = "MAM" if _n == _N-10
replace cityname = "Miami, Florida, USA" if _n == _N-10
replace origin = "NYT" if _n == _N-11
replace cityname = "New York, New York, USA" if _n == _N-11
replace origin = "TMP" if _n == _N-12
replace cityname = "Tampa, Florida, USA" if _n == _N-12
save "lookup/airport_code_origin_city", replace
rename origin destination
save "lookup/airport_code_destination_city", replace

use "dta_clean/${dataset}_agg3_city", clear
*/
local citytype origin destination

foreach m of local citytype {
	merge m:1 `m' using "lookup/airport_code_`m'_city"
	drop if _merge == 2
	replace cityname = "Phoenix, Arizona, USA" if `m' == "AZA"
	replace cityname = "Branson, Missouri, USA" if `m' == "BKG"
	replace cityname = "Bay County, Florida, USA" if `m' == "ECP"
	replace cityname = "Concord, North Carolina, USA" if inlist(`m', "JQF", "USA")
	drop if inlist(`m', "DSS", "ICN", "PVG") 
	drop _merge
	rename cityname `m'_name
	split `m'_name, parse(,)
	replace `m'_name3 = strtrim(`m'_name3)
	replace `m'_name4 = strtrim(`m'_name4)
	drop if `m'_name3 != "USA" & `m'_name4 != "USA"
	drop `m'_name1-`m'_name4
}

tsset market_id quarter, quarterly
save "dta_clean/${dataset}_agg3_city", replace

*use "dta_clean/${dataset}_agg3_city", clear
keep quarter market_id revenue lrevenue passenger passenger_ASVX fare lfare lcc_ratio
rename (revenue lrevenue passenger passenger_ASVX fare lfare) (revenue_mkt lrevenue_mkt passenger_mkt passenger_ASVX_mkt fare_mkt lfare_mkt)
save "dta_clean/${dataset}_agg3_ASVXmarket", replace

**********************
*** 6-5. City ASVX ***
**********************
use  "dta_clean/${dataset}_agg2_ASVX_city", clear

collapse (rawsum) revenue passenger passenger_lcc1-passenger_lcc4 passenger_ASVX1-passenger_ASVX4 (mean) fareI coupon_num roundtrip transfer restricted1-restricted4 business1-business4 first1-first4 carrier1_total-carrier4_total carrier1_total_lcc-carrier4_total_lcc market1_AS-market4_AS market1_VX-market4_VX market1_WN-market4_WN coupon_total1-coupon_total4 apt_num_origin_city apt_num_destination_city total_passenger_lcc1-total_passenger_lcc4 [fw = passenger], by(quarter market_id_city origin_city destination_city)
keep if passenger >= 90
rename (fareI origin_city destination_city market_id_city) (fare origin destination market_id)
gen lfare = log(fare), after(fare)
gen lrevenue = log(revenue), after(revenue)
tsset market_id quarter, quarterly

* Compute weighted_average
gen coupon_total = coupon_total1 if coupon_total2 == .
replace coupon_total = coupon_total1+coupon_total2 if coupon_total3 == . & coupon_total2 != .
replace coupon_total = coupon_total1+coupon_total2+coupon_total3 if coupon_total4 == . & coupon_total3 != .
replace coupon_total = coupon_total1+coupon_total2+coupon_total3+coupon_total4 if coupon_total4 != .

local weighted passenger_lcc passenger_ASVX restricted business first
foreach m of local weighted{
	gen `m' = (`m'1*coupon_total1)/coupon_total if coupon_total2==., before(`m'1)
	replace `m' = (`m'1*coupon_total1+`m'2*coupon_total2)/coupon_total if coupon_total3 == . & coupon_total2 != .
	replace `m' = (`m'1*coupon_total1+`m'2*coupon_total2+`m'3*coupon_total3)/coupon_total if coupon_total4 == . & coupon_total3 != .
	replace `m' = (`m'1*coupon_total1+`m'2*coupon_total2+`m'3*coupon_total3+`m'4*coupon_total4)/coupon_total if coupon_total4 != .
}

local airlines AS VX WN
foreach m of local airlines{
	gen market_`m' = (market1_`m'*coupon_total1)/coupon_total if coupon_total2==., before(market1_`m')
	replace market_`m' = (market1_`m'*coupon_total1+market2_`m'*coupon_total2)/coupon_total if coupon_total3 == . & coupon_total2 != .
	replace market_`m' = (market1_`m'*coupon_total1+market2_`m'*coupon_total2+market3_`m'*coupon_total3)/coupon_total if coupon_total4 == . & coupon_total3 != .
	replace market_`m' = (market1_`m'*coupon_total1+market2_`m'*coupon_total2+market3_`m'*coupon_total3+market4_`m'*coupon_total4)/coupon_total if coupon_total4 != .
}

local binary _total _total_lcc
foreach m of local binary{
	gen carrier`m' = (carrier1`m'*coupon_total1)/coupon_total if coupon_total2==., before(carrier1`m')
	replace carrier`m' = (carrier1`m'*coupon_total1+carrier2`m'*coupon_total2)/coupon_total if coupon_total3 == . & coupon_total2 != .
	replace carrier`m' = (carrier1`m'*coupon_total1+carrier2`m'*coupon_total2+carrier3`m'*coupon_total3)/coupon_total if coupon_total4 == . & coupon_total3 != .
	replace carrier`m' = (carrier1`m'*coupon_total1+carrier2`m'*coupon_total2+carrier3`m'*coupon_total3+carrier4`m'*coupon_total4)/coupon_total if coupon_total4 != .
}

* Quarter dummy 
forvalues n=1/4{
	gen quarter`n' = inlist(quarter, tq(2015q`n'), tq(2016q`n'), tq(2017q`n'), tq(2018q`n'), tq(2019q`n'))
}
drop quarter1

* Post dummy
gen post1 = !inlist(quarter, tq(2015q1), tq(2015q2), tq(2015q3), tq(2015q4), tq(2016q1), tq(2016q2), tq(2016q3), tq(2016q4))
gen post2 = !inlist(quarter, tq(2015q1), tq(2015q2), tq(2015q3), tq(2015q4), tq(2016q1), tq(2016q2), tq(2016q3), tq(2016q4), tq(2017q1), tq(2017q2))
gen post3 = !inlist(quarter, tq(2015q1), tq(2015q2), tq(2015q3), tq(2015q4), tq(2016q1), tq(2016q2), tq(2016q3), tq(2016q4), tq(2017q1), tq(2017q2), tq(2017q3), tq(2017q4))
gen post4 = !inlist(quarter, tq(2015q1), tq(2015q2), tq(2015q3), tq(2015q4), tq(2016q1), tq(2016q2), tq(2016q3), tq(2016q4), tq(2017q1), tq(2017q2), tq(2017q3), tq(2017q4), tq(2018q1))

* lcc-market share in each market
gen lcc_ratio = passenger_lcc / passenger
gegen long lcc_ratio_pre1 = total(passenger_lcc) if post4 == 0, by(market_id)
gegen long lcc_ratio_pre2 = total(passenger) if post4 == 0, by(market_id)
gen lcc_ratio_pre = lcc_ratio_pre1 / lcc_ratio_pre2

drop passenger_lcc1-passenger_lcc4 total_passenger_lcc1-total_passenger_lcc4 passenger_ASVX1-passenger_ASVX4 restricted1-restricted4 business1-business4 first1-first4 carrier1_total-carrier4_total carrier1_total_lcc-carrier4_total_lcc market1_AS-market4_AS market1_VX-market4_VX market1_WN-market4_WN coupon_total1-coupon_total4 lcc_ratio_pre1 lcc_ratio_pre2

local citytype origin destination
foreach m of local citytype {
	merge m:1 `m' using "lookup/airport_code_`m'_city"
	drop if _merge == 2 
	replace cityname = "Phoenix, Arizona, USA" if `m' == "AZA"
	replace cityname = "Branson, Missouri, USA" if `m' == "BKG"
	replace cityname = "Bay County, Florida, USA" if `m' == "ECP"
	replace cityname = "Concord, North Carolina, USA" if inlist(`m', "JQF", "USA")
	drop if inlist(`m', "DSS", "ICN", "PVG") 
	drop _merge
	rename cityname `m'_name
	split `m'_name, parse(,)
	replace `m'_name3 = strtrim(`m'_name3)
	replace `m'_name4 = strtrim(`m'_name4)
	drop if `m'_name3 != "USA" & `m'_name4 != "USA"
	drop `m'_name1-`m'_name4
}

tsset market_id quarter, quarterly
save "dta_clean/${dataset}_agg3_ASVX_city", replace

*use "dta_clean/${dataset}_agg3_ASVX_city", clear
keep quarter market_id revenue lrevenue passenger passenger_ASVX fare lfare lcc_ratio_pre
rename (revenue lrevenue passenger passenger_ASVX fare lfare) (revenue_mkt lrevenue_mkt passenger_mkt passenger_ASVX_mkt fare_mkt lfare_mkt)
save "dta_clean/${dataset}_agg3_ASVXmarket", replace

**************************
*** 6-6. City ASVXonly ***
**************************
use  "dta_clean/${dataset}_agg2_ASVXonly_city", clear

collapse (rawsum) revenue passenger passenger_lcc1-passenger_lcc4 passenger_ASVX1-passenger_ASVX4 (mean) fareI coupon_num roundtrip transfer restricted1-restricted4 business1-business4 first1-first4 carrier1_total-carrier4_total carrier1_total_lcc-carrier4_total_lcc market1_AS-market4_AS market1_VX-market4_VX market1_WN-market4_WN coupon_total1-coupon_total4 apt_num_origin_city apt_num_destination_city total_passenger_lcc1-total_passenger_lcc4 [fw = passenger], by(quarter market_id_city origin_city destination_city)
keep if passenger >= 30
rename (fareI origin_city destination_city market_id_city) (fare origin destination market_id)
gen lfare = log(fare), after(fare)
gen lrevenue = log(revenue), after(revenue)
tsset market_id quarter, quarterly

* Compute weighted_average
gen coupon_total = coupon_total1 if coupon_total2 == .
replace coupon_total = coupon_total1+coupon_total2 if coupon_total3 == . & coupon_total2 != .
replace coupon_total = coupon_total1+coupon_total2+coupon_total3 if coupon_total4 == . & coupon_total3 != .
replace coupon_total = coupon_total1+coupon_total2+coupon_total3+coupon_total4 if coupon_total4 != .

local weighted passenger_lcc passenger_ASVX restricted business first
foreach m of local weighted{
	gen `m' = (`m'1*coupon_total1)/coupon_total if coupon_total2==., before(`m'1)
	replace `m' = (`m'1*coupon_total1+`m'2*coupon_total2)/coupon_total if coupon_total3 == . & coupon_total2 != .
	replace `m' = (`m'1*coupon_total1+`m'2*coupon_total2+`m'3*coupon_total3)/coupon_total if coupon_total4 == . & coupon_total3 != .
	replace `m' = (`m'1*coupon_total1+`m'2*coupon_total2+`m'3*coupon_total3+`m'4*coupon_total4)/coupon_total if coupon_total4 != .
}

local airlines AS VX WN
foreach m of local airlines{
	gen market_`m' = (market1_`m'*coupon_total1)/coupon_total if coupon_total2==., before(market1_`m')
	replace market_`m' = (market1_`m'*coupon_total1+market2_`m'*coupon_total2)/coupon_total if coupon_total3 == . & coupon_total2 != .
	replace market_`m' = (market1_`m'*coupon_total1+market2_`m'*coupon_total2+market3_`m'*coupon_total3)/coupon_total if coupon_total4 == . & coupon_total3 != .
	replace market_`m' = (market1_`m'*coupon_total1+market2_`m'*coupon_total2+market3_`m'*coupon_total3+market4_`m'*coupon_total4)/coupon_total if coupon_total4 != .
}

local binary _total _total_lcc
foreach m of local binary{
	gen carrier`m' = (carrier1`m'*coupon_total1)/coupon_total if coupon_total2==., before(carrier1`m')
	replace carrier`m' = (carrier1`m'*coupon_total1+carrier2`m'*coupon_total2)/coupon_total if coupon_total3 == . & coupon_total2 != .
	replace carrier`m' = (carrier1`m'*coupon_total1+carrier2`m'*coupon_total2+carrier3`m'*coupon_total3)/coupon_total if coupon_total4 == . & coupon_total3 != .
	replace carrier`m' = (carrier1`m'*coupon_total1+carrier2`m'*coupon_total2+carrier3`m'*coupon_total3+carrier4`m'*coupon_total4)/coupon_total if coupon_total4 != .
}

* Quarter dummy 
forvalues n=1/4{
	gen quarter`n' = inlist(quarter, tq(2015q`n'), tq(2016q`n'), tq(2017q`n'), tq(2018q`n'), tq(2019q`n'))
}
drop quarter1

* Post dummy
gen post1 = !inlist(quarter, tq(2015q1), tq(2015q2), tq(2015q3), tq(2015q4), tq(2016q1), tq(2016q2), tq(2016q3), tq(2016q4))
gen post2 = !inlist(quarter, tq(2015q1), tq(2015q2), tq(2015q3), tq(2015q4), tq(2016q1), tq(2016q2), tq(2016q3), tq(2016q4), tq(2017q1), tq(2017q2))
gen post3 = !inlist(quarter, tq(2015q1), tq(2015q2), tq(2015q3), tq(2015q4), tq(2016q1), tq(2016q2), tq(2016q3), tq(2016q4), tq(2017q1), tq(2017q2), tq(2017q3), tq(2017q4))
gen post4 = !inlist(quarter, tq(2015q1), tq(2015q2), tq(2015q3), tq(2015q4), tq(2016q1), tq(2016q2), tq(2016q3), tq(2016q4), tq(2017q1), tq(2017q2), tq(2017q3), tq(2017q4), tq(2018q1))

* lcc-market share in each market
gen lcc_ratio = passenger_lcc / passenger
gegen long lcc_ratio_pre1 = total(passenger_lcc) if post4 == 0, by(market_id)
gegen long lcc_ratio_pre2 = total(passenger) if post4 == 0, by(market_id)
gen lcc_ratio_pre = lcc_ratio_pre1 / lcc_ratio_pre2

drop passenger_lcc1-passenger_lcc4 total_passenger_lcc1-total_passenger_lcc4 passenger_ASVX1-passenger_ASVX4 restricted1-restricted4 business1-business4 first1-first4 carrier1_total-carrier4_total carrier1_total_lcc-carrier4_total_lcc market1_AS-market4_AS market1_VX-market4_VX market1_WN-market4_WN coupon_total1-coupon_total4 lcc_ratio_pre1 lcc_ratio_pre2

local citytype origin destination
foreach m of local citytype {
	merge m:1 `m' using "lookup/airport_code_`m'_city"
	drop if _merge == 2
	replace cityname = "Phoenix, Arizona, USA" if `m' == "AZA"
	replace cityname = "Branson, Missouri, USA" if `m' == "BKG"
	replace cityname = "Bay County, Florida, USA" if `m' == "ECP"
	replace cityname = "Concord, North Carolina, USA" if inlist(`m', "JQF", "USA")
	drop if inlist(`m', "DSS", "ICN", "PVG") 
	drop _merge
	rename cityname `m'_name
	split `m'_name, parse(,)
	replace `m'_name3 = strtrim(`m'_name3)
	replace `m'_name4 = strtrim(`m'_name4)
	drop if `m'_name3 != "USA" & `m'_name4 != "USA"
	drop `m'_name1-`m'_name4
}

*save "dta_clean/${dataset}_agg3_ASVXonly_city", replace
*use "dta_clean/${dataset}_agg3_ASVXonly_city", clear
merge 1:1 market_id quarter using "dta_clean/${dataset}_agg3_ASVXmarket"
keep if _merge == 3 //check later
tsset market_id quarter, quarterly
save "dta_clean/${dataset}_agg3_ASVXonly_city", replace
