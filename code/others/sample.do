

// Data Cleaning File for DB1B public database
// Name: Tatsuki Kikugawa

// Change the file directory below.
global rep_folder "/Users/tsukik/Downloads/airline_tatsuki" 


capture log close
cd "${rep_folder}/code"
clear all
cd "${rep_folder}/input"



* Goal is
* to make code that transforms ticket-level data to airpor-pair, and to city-pair
* to apply this code to an actual larger dataset (merged_clean.data) instead of sample
use sample, clear


gen distance = distance1 + distance2 + distance3 + distance4
gen origin = airport0
gen destination_final = airport1
replace destination_final = airport2 if !missing(airport2)
replace destination_final = airport3 if !missing(airport3)
replace destination_final = airport4 if !missing(airport4)


*** Construct an algorithm to identify destination and 
*** Also this aims to find one-way trip with no more than one stop and symmetric round-trip
gen destination = ""
gen roundtrip = .

* one coupon
replace destination = airport1 if coupon_num == 1 
replace roundtrip = 0 if coupon_num == 1

* two coupons
** one-way trip with one stop
replace destination = airport2 if coupon_num == 2 & airport0 != airport2
replace roundtrip = 0 if coupon_num == 2 & airport0 != airport2
** round-trip with no stop
replace destination = airport1 if coupon_num == 2 & airport0 == airport2
replace roundtrip = 1 if coupon_num == 2 & airport0 == airport2

* three coupons
*** [assumption1] any ticket involving three coupons are removed!
** one-way trip with two stops or round-trip+one-way trip
replace destination = "" if coupon_num == 3 & airport0 != airport3
replace roundtrip = . if coupon_num == 3 & airport0 != airport3
**round-trip with one stop in either trip -> we don't know if destination is airport1 or airport2
replace destination = "" if coupon_num == 3 & airport0 == airport3 
replace roundtrip = . if coupon_num == 3 & airport0 == airport3

* four coupons 
**one-way trip with three stops / round-trip plus two one-way tickets / round-trip with one stop plus a one-way ticket
*** [assumption2] any ticket with four coupons that doesn't match origin and destination are removed
replace destination = "" if coupon_num == 4 & airport0 != airport4
replace roundtrip = . if coupon_num == 4 & airport0 != airport4
** symmetric round-trip with one stop each
replace destination = airport2 if coupon_num == 4 & airport0 == airport4 & airport1 == airport3
replace roundtrip = 1  if coupon_num == 4 & airport0 == airport4 & airport1 == airport3
**asymmetric round-trip with one stop each -> we cannot distinguish if destination is airport1 or airport3 
*** [assumption2] any round-trip ticket with one transfer each that has different transfer airports are removed
replace destination = ""  if coupon_num == 4 & airport0 == airport4 & airport1 != airport3
replace roundtrip = . if coupon_num == 4 & airport0 == airport4 & airport1 != airport3

order origin destination destination_final roundtrip, after(coupon_num)

/*
tab carrier1, gen(c1)
tab carrier2, gen(c2)
tab carrier3, gen(c3)
tab carrier4, gen(c4)
*/

/*
if coupon_num == 1 {
	*one way trip
	replace destination = airport1 if coupon_num == 1 
	replace roundtrip = 0 if coupon_num == 1
}
if coupon_num == 2 {
	if airport0 != airport2 {
		*one-way trip with one stop
		replace destination = airport2 if coupon_num == 2 & airport0 != airport2
		replace roundtrip = 0 if coupon_num == 2 & airport0 != airport2
	}
	if airport0 == airport2{
		*round-trip with no stop 
		replace destination = airport1 if coupon_num == 2 & airport0 == airport2
		replace roundtrip = 1 if coupon_num == 2 & airport0 == airport2
	}
}
else if coupon_num == 3 {
	if airport0 != airport3{
		*one-way trip with two stops or round-trip+one-way trip
		replace destination = . if coupon_num == 3 & airport0 != airport3
		replace roundtrip = . if coupon_num == 3 & airport0 != airport3
		/*
		if airport0 == airport2 | airport1 == airport3 {
			replace destination == .
		}*/
	}
	else if airport0 == airport3{
		*round-trip with one stop in either trip
		replace destination = . if coupon_num == 3 & airport0 == airport3 
		// we don't know if destination is airport1 or airport2
		replace roundtrip = . if coupon_num == 3 & airport0 == airport3
	}
}
else if coupon_num == 4 {
	if aiport0 != airport4 {
		*one-way trip with three stops
		*round-trip plus two one-way tickets
		*round-trip with one stop plus a one-way ticket
		replace destination = . if coupon_num == 4 & airport0 != airport4
		replace roundtrip = . if coupon_num == 4 & airport0 != airport4
	}
	if airport0 == airport4 {
		if airport1 == airport3{
			* symmetric round-trip with one stop each
			replace destination = airport2 if coupon_num == 4 & airport0 == airport4 & airport1 == airport3
			replace roundtrip = 1  if coupon_num == 4 & airport0 == airport4 & airport1 == airport3
		}
		else if airport1 != airport3 {
			*asymmetric round-trip with one stop each
			replace destination = .  if coupon_num == 4 & airport0 == airport4 & airport1 != airport3
			// we cannot distinguish if destination is airport1 or airport3 
			replace roundtrip = . if coupon_num == 4 & airport0 == airport4 & airport1 != airport3
		}
	}
}
*/

* I want to count competitors in each market 
egen market_id = group(coupon_num origin destination destination_final)
forvalues n=1/4 {
	egen tag`n' = tag(market_id carrier`n')if coupon_num >= `n'
	egen carrier`n'_total = total(tag`n') if coupon_num >= `n', by (market_id) 
	drop tag`n'
}
*br if market_id == 28338

* I want to create a dummy indicator if Alaska ("AS") or Virgin ("VX") serves for the market
forvalues n=1/4{
	gen AS_indicator`n' = (carrier`n' == "AS") if carrier`n' != ""
	egen tag_AS`n' = tag(market_id AS_indicator`n') if coupon_num >= `n'
	egen market`n'_AS = total(tag_AS`n') if coupon_num >= `n', by (market_id)
	drop AS_indicator`n' tag_AS`n'
	*replace market`n'_AS = . if market`n'_AS == 0
	replace market`n'_AS = 0 if market`n'_AS == 1
	replace market`n'_AS = 1 if market`n'_AS == 2
	
	gen VX_indicator`n' = (carrier`n' == "VX") if carrier`n' != ""
	egen tag_VX`n' = tag(market_id VX_indicator`n') if coupon_num >= `n'
	egen market`n'_VX = total(tag_VX`n') if coupon_num >= `n', by (market_id)
	drop VX_indicator`n' tag_VX`n'
	*replace market`n'_VX = . if market`n'_VX == 0
	replace market`n'_VX = 0 if market`n'_VX == 1
	replace market`n'_VX = 1 if market`n'_VX == 2
}

rename date quarter

keep if market1_AS == 1 | market2_AS == 1 | market3_AS == 1 | market4_AS == 1 | market1_VX == 1 |  market1_VX == 1 |  market3_VX == 1 |  market4_VX == 1
collapse (rawsum) passenger (mean) fare restricted1 business1 first1 restricted2 business2 first2 restricted3 business3 first3 restricted4 business4 first4 carrier1_total carrier2_total carrier3_total carrier4_total market1_AS market2_AS market3_AS market4_AS market1_VX market2_VX market3_VX market4_VX [fw = passenger], by(quarter coupon_num market_id origin destination destination_final)

save airport_pair, replace

import delimited "/Users/tsukik/Downloads/airline_tatsuki/input/lookup/airports_codes.txt", clear 
drop worldareacode
rename airportcode origin
save airport_code_origin, replace
rename origin destination
save airport_code_destination, replace
rename destination destination_final
save airport_code_destination_final, replace

cd "${rep_folder}/input"
use airport_pair, clear
merge m:1 origin using airport_code_origin
drop if _merge == 2
drop _merge
rename cityname origin_name
merge m:1 destination using airport_code_destination
drop if _merge == 2
replace cityname = "Bay County, Florida, USA" if destination == "ECP"
drop _merge
rename cityname destination_name
merge m:1 destination_final using airport_code_destination_final
drop if _merge == 2
replace cityname = "Bay County, Florida, USA" if destination_final == "ECP"
drop _merge
rename cityname destination_final_name

save aiportpair, replace 
