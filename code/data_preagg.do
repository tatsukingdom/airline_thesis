// 2.Data Pre-Aggregation File for DB1B public database
// Name: Tatsuki Kikugawa

use "dta_clean/${dataset}_clean", clear
drop if fareI == .
************************************
**  4.Preparation for Aggregation **
************************************
* Route identifying algorithm to make code that transforms ticket-level data to airpor-pair (and to city-pair)
*** Construct an algorithm to identify destination and find one-way trip with no more than one stop and symmetric round-trip
gen origin = airport0
gen destination_final = airport1
replace destination_final = airport2 if !missing(airport2)
replace destination_final = airport3 if !missing(airport3)
replace destination_final = airport4 if !missing(airport4)

gen destination = ""
gen roundtrip = .
replace destination = airport1 if coupon_num == 1 //one coupon
replace roundtrip = 0 if coupon_num == 1
replace destination = airport2 if coupon_num == 2 & airport0 != airport2 //one-way trip with one stop
replace roundtrip = 0 if coupon_num == 2 & airport0 != airport2
replace destination = airport1 if coupon_num == 2 & airport0 == airport2 //round-trip with no stop
replace roundtrip = 1 if coupon_num == 2 & airport0 == airport2

replace destination = "" if coupon_num == 3 & airport0 != airport3 //one-way trip with two stops or round-trip+one-way trip
replace roundtrip = . if coupon_num == 3 & airport0 != airport3
replace destination = "" if coupon_num == 3 & airport0 == airport3 //round-trip with one stop in either trip
replace roundtrip = . if coupon_num == 3 & airport0 == airport3
 
replace destination = "" if coupon_num == 4 & airport0 != airport4 //four coupons
replace roundtrip = . if coupon_num == 4 & airport0 != airport4
replace destination = airport2 if coupon_num == 4 & airport0 == airport4 & airport1 == airport3 // symmetric round-trip
replace roundtrip = 1  if coupon_num == 4 & airport0 == airport4 & airport1 == airport3
replace destination = ""  if coupon_num == 4 & airport0 == airport4 & airport1 != airport3 //asymmetric round-trip
replace roundtrip = . if coupon_num == 4 & airport0 == airport4 & airport1 != airport3

order origin destination destination_final roundtrip, after(coupon_num)
drop if destination == ""
save "dta_clean/${dataset}_agg1", replace 

gegen long market_id = group(origin destination)

gegen int tag1 = tag(market_id carrier1) if coupon_num >= 1
gegen int carrier1_total = total(tag1) if coupon_num >= 1, by (market_id)
gegen int tag2 = tag(market_id carrier2) if coupon_num >= 2
gegen int carrier2_total = total(tag2) if coupon_num >= 2, by (market_id) 
gegen int tag3 = tag(market_id carrier3) if coupon_num >= 3
gegen int carrier3_total = total(tag3) if coupon_num >= 3, by (market_id) 
gegen int tag4 = tag(market_id carrier4) if coupon_num >= 4
gegen int carrier4_total = total(tag4) if coupon_num >= 4, by (market_id) 
drop tag1 tag2 tag3 tag4 

* Dummy = 1 if Alaska ("AS") or Virgin ("VX") serves for the market
/* (Computationally expensive)
local merged AS VX
foreach m of local merged {
	forvalues n=1/4{
		gen `m'_indicator`n' = (carrier`n' == "`m'") if carrier`n' != ""
		fegen int tag_`m'`n' = tag(market_id `m'_indicator`n') if coupon_num >= `n'
		fegen int market`n'_`m' = total(tag_`m'`n') if coupon_num >= `n', by (market_id)
		drop `m'_indicator`n' tag_`m'`n'
		*replace market`n'_`m' = . if market`n'_`m' == 0
		replace market`n'_`m' = 0 if market`n'_`m' == 1
		replace market`n'_`m' = 1 if market`n'_`m' == 2
	}
}
*/

gen AS_indicator1 = (carrier1 == "AS") if carrier1 != ""
gegen int tag_AS1 = tag(market_id AS_indicator1) if coupon_num >= 1
gegen int market1_AS = total(tag_AS1) if coupon_num >= 1, by (market_id)
drop AS_indicator1 tag_AS1
replace market1_AS = 0 if market1_AS == 1
replace market1_AS = 1 if market1_AS == 2

gen AS_indicator2 = (carrier2 == "AS") if carrier2 != ""
gegen int tag_AS2 = tag(market_id AS_indicator2) if coupon_num >= 2
gegen int market2_AS = total(tag_AS2) if coupon_num >= 2, by (market_id)
drop AS_indicator2 tag_AS2
replace market2_AS = 0 if market2_AS == 1
replace market2_AS = 1 if market2_AS == 2

gen AS_indicator3 = (carrier3 == "AS") if carrier3 != ""
gegen int tag_AS3 = tag(market_id AS_indicator3) if coupon_num >= 3
gegen int market3_AS = total(tag_AS3) if coupon_num >= 3, by (market_id)
drop AS_indicator3 tag_AS3
replace market3_AS = 0 if market3_AS == 1
replace market3_AS = 1 if market3_AS == 2

gen AS_indicator4 = (carrier4 == "AS") if carrier4 != ""
gegen int tag_AS4 = tag(market_id AS_indicator4) if coupon_num >= 4
gegen int market4_AS = total(tag_AS4) if coupon_num >= 4, by (market_id)
drop AS_indicator4 tag_AS4
replace market4_AS = 0 if market4_AS == 1
replace market4_AS = 1 if market4_AS == 2

gen VX_indicator1 = (carrier1 == "VX") if carrier1 != ""
gegen int tag_VX1 = tag(market_id VX_indicator1) if coupon_num >= 1
gegen int market1_VX = total(tag_VX1) if coupon_num >= 1, by (market_id)
drop VX_indicator1 tag_VX1
replace market1_VX = 0 if market1_VX == 1
replace market1_VX = 1 if market1_VX == 2

gen VX_indicator2 = (carrier2 == "VX") if carrier2 != ""
gegen int tag_VX2 = tag(market_id VX_indicator2) if coupon_num >= 2
gegen int market2_VX = total(tag_VX2) if coupon_num >= 2, by (market_id)
drop VX_indicator2 tag_VX2
replace market2_VX = 0 if market2_VX == 1
replace market2_VX = 1 if market2_VX == 2

gen VX_indicator3 = (carrier3 == "VX") if carrier3 != ""
gegen int tag_VX3 = tag(market_id VX_indicator3) if coupon_num >= 3
gegen int market3_VX = total(tag_VX3) if coupon_num >= 3, by (market_id)
drop VX_indicator3 tag_VX3
replace market3_VX = 0 if market3_VX == 1
replace market3_VX = 1 if market3_VX == 2

gen VX_indicator4 = (carrier4 == "VX") if carrier4 != ""
gegen int tag_VX4 = tag(market_id VX_indicator4) if coupon_num >= 4
gegen int market4_VX = total(tag_VX4) if coupon_num >= 4, by (market_id)
drop VX_indicator4 tag_VX4
replace market4_VX = 0 if market4_VX == 1
replace market4_VX = 1 if market4_VX == 2

* Southwest indicator 
gen WN_indicator1 = (carrier1 == "WN") if carrier1 != ""
gegen int tag_WN1 = tag(market_id WN_indicator1) if coupon_num >= 1
gegen int market1_WN = total(tag_WN1) if coupon_num >= 1, by (market_id)
drop WN_indicator1 tag_WN1
replace market1_WN = 0 if market1_WN == 1
replace market1_WN = 1 if market1_WN == 2

gen WN_indicator2 = (carrier2 == "WN") if carrier2 != ""
gegen int tag_WN2 = tag(market_id WN_indicator2) if coupon_num >= 2
gegen int market2_WN = total(tag_WN2) if coupon_num >= 2, by (market_id)
drop WN_indicator2 tag_WN2
replace market2_WN = 0 if market2_WN == 1
replace market2_WN = 1 if market2_WN == 2

gen WN_indicator3 = (carrier3 == "WN") if carrier3 != ""
gegen int tag_WN3 = tag(market_id WN_indicator3) if coupon_num >= 3
gegen int market3_WN = total(tag_WN3) if coupon_num >= 3, by (market_id)
drop WN_indicator3 tag_WN3
replace market3_WN = 0 if market3_WN == 1
replace market3_WN = 1 if market3_WN == 2

gen WN_indicator4 = (carrier4 == "WN") if carrier4 != ""
gegen int tag_WN4 = tag(market_id WN_indicator4) if coupon_num >= 4
gegen int market4_WN = total(tag_WN4) if coupon_num >= 4, by (market_id)
drop WN_indicator4 tag_WN4
replace market4_WN = 0 if market4_WN == 1
replace market4_WN = 1 if market4_WN == 2

* LCC indicator and count LCC passengers in the top 50 airlines
forvalues n=1/4{
	gen aggregate`n' = carrier`n' if inlist(carrier`n', "WN", "DL", "AA", "UA", "OO", "B6", "AS", "YX", "EV")
	replace aggregate`n' = carrier`n' if inlist(carrier`n', "NK", "MQ", "9E", "YV", "OH", "G4", "F9", "QX", "US")
	replace aggregate`n' = carrier`n' if inlist(carrier`n', "G7", "CP", "HA", "ZW", "VX", "PT", "SS", "AX", "SY")
	replace aggregate`n' = carrier`n' if inlist(carrier`n', "C5", "16", "17", "BA", "AC", "LH", "9K", "3M", "KL")
	replace aggregate`n' = carrier`n' if inlist(carrier`n', "AF", "NH", "VS", "LA", "JL", "KS", "7H", "KE", "WS")
	replace aggregate`n' = carrier`n' if inlist(carrier`n', "QF", "AM", "IB", "EM", "LX")
	drop if aggregate`n' == "" & coupon_num >= `n' // drop non-top50 observations
	gen lcc`n' = inlist(carrier`n', "WN", "B6", "NK", "G4", "F9", "VX", "SY") if carrier`n' != ""
	gen passenger_lcc`n' = passenger if lcc`n' == 1
	drop aggregate`n'
}

* Number of LCCs on the route
forvalues n=1/4{
	gen lcc_carrier`n' = carrier`n' if inlist(carrier`n', "WN", "B6", "NK", "G4", "F9", "VX", "SY")
	gegen int tag`n' = tag(market_id lcc_carrier`n') if coupon_num >= `n'
	gegen int carrier`n'_total_lcc = total(tag`n') if coupon_num >= `n', by (market_id)
	drop tag`n' lcc_carrier`n'
}

* Revenue
gen float revenue = fare * passenger

* Indicator for transfer
gen transfer = 0, after(roundtrip)
replace transfer = 1 if coupon_num==2 & roundtrip==0
replace transfer = 1 if coupon_num==4

* Re-order variables 
order passenger_lcc1 passenger_lcc2 passenger_lcc3 passenger_lcc4 lcc1 lcc2 lcc3 lcc4, after(market4_WN)
order carrier1_total_lcc carrier2_total_lcc carrier3_total_lcc carrier4_total_lcc, after(carrier4_total)
order market_id fareI Ifare revenue, after(passenger)
order airport1 airport2 airport3 airport4, after(airport0)
order city0 city1 city2 city3 city4, after(airport4)
order state0 state1 state2 state3 state4, after(city4)
order carrier1 carrier2 carrier3 carrier4, after(state4)
order fare_type1 fare_type2 fare_type3 fare_type4, after(carrier4)
order distance1 distance2 distance3 distance4, after(fare_type4)
order restricted1 restricted2 restricted3 restricted4, after(distance4)
order business1 business2 business3 business4, after(restricted4)
order first1 first2 first3 first4, after(business4)

* Number of coupons in a given market in each quarter
gegen long mkt_quarter = group(market_id quarter) 
gegen long coupon_total1 = total(passenger) if coupon_num >= 1, by(mkt_quarter)
gegen long coupon_total2 = total(passenger) if coupon_num >= 2, by(mkt_quarter)
gegen long coupon_total3 = total(passenger) if coupon_num >= 3, by(mkt_quarter)
gegen long coupon_total4 = total(passenger) if coupon_num >= 4, by(mkt_quarter)

* Market shares of Alaska and Virgin
forvalues n=1/4{
	gen passenger_ASVX`n' = passenger if inlist(carrier`n', "AS", "VX")
	replace passenger_ASVX`n' = 0 if passenger_ASVX`n' == .
}

drop mkt_quarter
save "dta_clean/${dataset}_agg2", replace

* Create ASVX specific datasets
keep if (market1_AS == 1 | market1_VX == 1) & (market2_AS == 1 | market2_VX == 1 | (market2_AS == . | market2_VX == .))  & (market3_AS == 1 | market3_VX == 1 | (market3_AS == . | market3_VX == .)) & (market4_AS == 1 | market4_VX == 1 | (market4_AS == . | market4_VX == .)) 
save "dta_clean/${dataset}_agg2_ASVX", replace

keep if (inlist(carrier1, "AS", "VX") & inlist(carrier2, "AS", "VX", "") & inlist(carrier3, "AS", "VX", "") & inlist(carrier4, "AS", "VX", ""))
save "dta_clean/${dataset}_agg2_ASVXonly", replace


********************************************
*** 5.Preparation for Aggregation ~City~ ***
********************************************
use "dta_clean/${dataset}_agg1", clear

local apts origin destination destination_final
foreach m of local apts{
	gen `m'_city = `m'
	replace `m'_city = "WDC" if inlist(`m', "DCA", "IAD", "BWI")
	replace `m'_city = "SFF" if inlist(`m', "SFO", "OAK")
	replace `m'_city = "BST" if inlist(`m', "ZZZ")
	replace `m'_city = "OLD" if inlist(`m', "ORD", "MDW")
	replace `m'_city = "CNC" if inlist(`m', "CVG", "DAY")
	replace `m'_city = "CLV" if inlist(`m', "CLE", "CAK")
	replace `m'_city = "DFO" if inlist(`m', "DFW", "DAL")
	replace `m'_city = "DTR" if inlist(`m', "ZZZ")
	replace `m'_city = "HST" if inlist(`m', "IAH", "HOU")
	replace `m'_city = "LSA" if inlist(`m', "ZZZ")
	replace `m'_city = "MAM" if inlist(`m', "MIA", "FLL") 
	replace `m'_city = "NYT" if inlist(`m', "LGA", "EWR", "JFK")
	replace `m'_city = "TMP" if inlist(`m', "TPA", "PIE")
}

gegen long market_id_city = group(origin_city destination_city)

gegen int tag1 = tag(market_id_city carrier1) if coupon_num >= 1
gegen int carrier1_total = total(tag1) if coupon_num >= 1, by (market_id_city)
gegen int tag2 = tag(market_id_city carrier2) if coupon_num >= 2
gegen int carrier2_total = total(tag2) if coupon_num >= 2, by (market_id_city) 
gegen int tag3 = tag(market_id_city carrier3) if coupon_num >= 3
gegen int carrier3_total = total(tag3) if coupon_num >= 3, by (market_id_city) 
gegen int tag4 = tag(market_id_city carrier4) if coupon_num >= 4
gegen int carrier4_total = total(tag4) if coupon_num >= 4, by (market_id_city) 
drop tag1 tag2 tag3 tag4 

gen AS_indicator1 = (carrier1 == "AS") if carrier1 != ""
gegen int tag_AS1 = tag(market_id_city AS_indicator1) if coupon_num >= 1
gegen int market1_AS = total(tag_AS1) if coupon_num >= 1, by (market_id_city)
drop AS_indicator1 tag_AS1
replace market1_AS = 0 if market1_AS == 1
replace market1_AS = 1 if market1_AS == 2

gen AS_indicator2 = (carrier2 == "AS") if carrier2 != ""
gegen int tag_AS2 = tag(market_id_city AS_indicator2) if coupon_num >= 2
gegen int market2_AS = total(tag_AS2) if coupon_num >= 2, by (market_id_city)
drop AS_indicator2 tag_AS2
replace market2_AS = 0 if market2_AS == 1
replace market2_AS = 1 if market2_AS == 2

gen AS_indicator3 = (carrier3 == "AS") if carrier3 != ""
gegen int tag_AS3 = tag(market_id_city AS_indicator3) if coupon_num >= 3
gegen int market3_AS = total(tag_AS3) if coupon_num >= 3, by (market_id_city)
drop AS_indicator3 tag_AS3
replace market3_AS = 0 if market3_AS == 1
replace market3_AS = 1 if market3_AS == 2

gen AS_indicator4 = (carrier4 == "AS") if carrier4 != ""
gegen int tag_AS4 = tag(market_id_city AS_indicator4) if coupon_num >= 4
gegen int market4_AS = total(tag_AS4) if coupon_num >= 4, by (market_id_city)
drop AS_indicator4 tag_AS4
replace market4_AS = 0 if market4_AS == 1
replace market4_AS = 1 if market4_AS == 2

gen VX_indicator1 = (carrier1 == "VX") if carrier1 != ""
gegen int tag_VX1 = tag(market_id_city VX_indicator1) if coupon_num >= 1
gegen int market1_VX = total(tag_VX1) if coupon_num >= 1, by (market_id_city)
drop VX_indicator1 tag_VX1
replace market1_VX = 0 if market1_VX == 1
replace market1_VX = 1 if market1_VX == 2

gen VX_indicator2 = (carrier2 == "VX") if carrier2 != ""
gegen int tag_VX2 = tag(market_id_city VX_indicator2) if coupon_num >= 2
gegen int market2_VX = total(tag_VX2) if coupon_num >= 2, by (market_id_city)
drop VX_indicator2 tag_VX2
replace market2_VX = 0 if market2_VX == 1
replace market2_VX = 1 if market2_VX == 2

gen VX_indicator3 = (carrier3 == "VX") if carrier3 != ""
gegen int tag_VX3 = tag(market_id_city VX_indicator3) if coupon_num >= 3
gegen int market3_VX = total(tag_VX3) if coupon_num >= 3, by (market_id_city)
drop VX_indicator3 tag_VX3
replace market3_VX = 0 if market3_VX == 1
replace market3_VX = 1 if market3_VX == 2

gen VX_indicator4 = (carrier4 == "VX") if carrier4 != ""
gegen int tag_VX4 = tag(market_id_city VX_indicator4) if coupon_num >= 4
gegen int market4_VX = total(tag_VX4) if coupon_num >= 4, by (market_id_city)
drop VX_indicator4 tag_VX4
replace market4_VX = 0 if market4_VX == 1
replace market4_VX = 1 if market4_VX == 2

* Southwest indicator 
gen WN_indicator1 = (carrier1 == "WN") if carrier1 != ""
gegen int tag_WN1 = tag(market_id_city WN_indicator1) if coupon_num >= 1
gegen int market1_WN = total(tag_WN1) if coupon_num >= 1, by (market_id_city)
drop WN_indicator1 tag_WN1
replace market1_WN = 0 if market1_WN == 1
replace market1_WN = 1 if market1_WN == 2

gen WN_indicator2 = (carrier2 == "WN") if carrier2 != ""
gegen int tag_WN2 = tag(market_id_city WN_indicator2) if coupon_num >= 2
gegen int market2_WN = total(tag_WN2) if coupon_num >= 2, by (market_id_city)
drop WN_indicator2 tag_WN2
replace market2_WN = 0 if market2_WN == 1
replace market2_WN = 1 if market2_WN == 2

gen WN_indicator3 = (carrier3 == "WN") if carrier3 != ""
gegen int tag_WN3 = tag(market_id_city WN_indicator3) if coupon_num >= 3
gegen int market3_WN = total(tag_WN3) if coupon_num >= 3, by (market_id_city)
drop WN_indicator3 tag_WN3
replace market3_WN = 0 if market3_WN == 1
replace market3_WN = 1 if market3_WN == 2

gen WN_indicator4 = (carrier4 == "WN") if carrier4 != ""
gegen int tag_WN4 = tag(market_id_city WN_indicator4) if coupon_num >= 4
gegen int market4_WN = total(tag_WN4) if coupon_num >= 4, by (market_id_city)
drop WN_indicator4 tag_WN4
replace market4_WN = 0 if market4_WN == 1
replace market4_WN = 1 if market4_WN == 2

* LCC indicator and count LCC passengers in the top 50 airlines
forvalues n=1/4{
	gen aggregate`n' = carrier`n' if inlist(carrier`n', "WN", "DL", "AA", "UA", "OO", "B6", "AS", "YX", "EV")
	replace aggregate`n' = carrier`n' if inlist(carrier`n', "NK", "MQ", "9E", "YV", "OH", "G4", "F9", "QX", "US")
	replace aggregate`n' = carrier`n' if inlist(carrier`n', "G7", "CP", "HA", "ZW", "VX", "PT", "SS", "AX", "SY")
	replace aggregate`n' = carrier`n' if inlist(carrier`n', "C5", "16", "17", "BA", "AC", "LH", "9K", "3M", "KL")
	replace aggregate`n' = carrier`n' if inlist(carrier`n', "AF", "NH", "VS", "LA", "JL", "KS", "7H", "KE", "WS")
	replace aggregate`n' = carrier`n' if inlist(carrier`n', "QF", "AM", "IB", "EM", "LX")
	drop if aggregate`n' == "" & coupon_num >= `n' // drop non-top50 observations
	gen lcc`n' = inlist(carrier`n', "WN", "B6", "NK", "G4", "F9", "VX", "SY") if carrier`n' != ""
	gen passenger_lcc`n' = passenger if lcc`n' == 1
	drop aggregate`n'
}

* Number of LCCs on the route
forvalues n=1/4{
	gen lcc_carrier`n' = carrier`n' if inlist(carrier`n', "WN", "B6", "NK", "G4", "F9", "VX", "SY")
	gegen int tag`n' = tag(market_id_city lcc_carrier`n') if coupon_num >= `n'
	gegen int carrier`n'_total_lcc = total(tag`n') if coupon_num >= `n', by (market_id_city)
	drop tag`n' lcc_carrier`n'
}

* Revenue
gen float revenue = fare * passenger

* Indicator for transfer
gen transfer = 0, after(roundtrip)
replace transfer = 1 if coupon_num==2 & roundtrip==0
replace transfer = 1 if coupon_num==4

* Re-order variables 
order passenger_lcc1 passenger_lcc2 passenger_lcc3 passenger_lcc4 lcc1 lcc2 lcc3 lcc4, after(market4_WN)
order carrier1_total_lcc carrier2_total_lcc carrier3_total_lcc carrier4_total_lcc, after(carrier4_total)
order market_id_city fareI Ifare revenue, after(passenger)
order airport1 airport2 airport3 airport4, after(airport0)
order city0 city1 city2 city3 city4, after(airport4)
order state0 state1 state2 state3 state4, after(city4)
order carrier1 carrier2 carrier3 carrier4, after(state4)
order fare_type1 fare_type2 fare_type3 fare_type4, after(carrier4)
order distance1 distance2 distance3 distance4, after(fare_type4)
order restricted1 restricted2 restricted3 restricted4, after(distance4)
order business1 business2 business3 business4, after(restricted4)
order first1 first2 first3 first4, after(business4)

* Number of coupons in a given market in each quarter
gegen long mkt_quarter = group(market_id_city quarter)
gegen long coupon_total1 = total(passenger) if coupon_num >= 1, by(mkt_quarter)
gegen long coupon_total2 = total(passenger) if coupon_num >= 2, by(mkt_quarter)
gegen long coupon_total3 = total(passenger) if coupon_num >= 3, by(mkt_quarter)
gegen long coupon_total4 = total(passenger) if coupon_num >= 4, by(mkt_quarter)

* Market shares of Alaska and Virgin
forvalues n=1/4{
	gen passenger_ASVX`n' = passenger if inlist(carrier`n', "AS", "VX")
	replace passenger_ASVX`n' = 0 if passenger_ASVX`n' == .
}

* Number of airports 
local airports origin_city destination_city destination_final_city
foreach m of local airports{
	gen apt_num_`m' = 1
	replace apt_num_`m' = 2 if inlist(`m', "OLD", "CNC", "CLV", "DFO", "HST", "MAM", "SFF", "TMP")
	replace apt_num_`m' = 3 if inlist(`m', "NYT", "WDC")
}
drop mkt_quarter
forvalues n=1/4{
	gegen long total_passenger_lcc`n' = total(passenger_lcc`n') if coupon_num >= `n', by(market_id_city quarter)
}
save "dta_clean/${dataset}_agg2_city", replace

* Create a dataset with routes where either Alaska or Virgin operate 
keep if (market1_AS == 1 | market1_VX == 1) & (market2_AS == 1 | market2_VX == 1 | (market2_AS == . | market2_VX == .))  & (market3_AS == 1 | market3_VX == 1 | (market3_AS == . | market3_VX == .)) & (market4_AS == 1 | market4_VX == 1 | (market4_AS == . | market4_VX == .)) 

save "dta_clean/${dataset}_agg2_ASVX_city", replace


* Create a dataset with only Alaska 
keep if (inlist(carrier1, "AS", "VX") & inlist(carrier2, "AS", "VX", "") & inlist(carrier3, "AS", "VX", "") & inlist(carrier4, "AS", "VX", ""))
save "dta_clean/${dataset}_agg2_ASVXonly_city", replace
