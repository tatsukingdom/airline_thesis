// 1.Data Cleaning File for DB1B public database
// Name: Tatsuki Kikugawa

************************************
***　     1.Raw Data merger      ***
************************************
cd "${rep_folder}/input"
/*
use "dta_raw/public201503", clear

local quarter 201503 201506 201509 201512 201603 201606 201609 201612 201703 201706 201709 201712 201803 201806 201809 201812 201903 201906 201909 201912 

disp `"`quarter'"'
*201503 201506 201509 201512 201603 201606 201609 201612 201703 201706 201709 201712 201803 201806 201809 201812 201903 201906 201909 201912

foreach q of local quarter {
	append using "dta_raw/public`q'"
}
save "dta_clean/merged", replace
*/

************************************
***  2.basic coding & cleaning  ***
************************************
use "dta_clean/${dataset}", clear
drop airport_id trip report_carrier airport_id2* ticketed* trip*

order dollar_id airport_city_code city_market_id state_id opeartin_carrier coupon fare_type distance airport_city city_market_id2 state_id2, after(num_passenger)

rename (index-state_id2_3) (index fare quarter coupon_num passenger dollar_id airport0 city0 state0 carrier1 coupon1 fare_type1 distance1 airport1 city1 state1 carrier2 coupon2 fare_type2 distance2 airport2 city2 state2 carrier3 coupon3 fare_type3 distance3 airport3 city3 state3 carrier4 coupon4 fare_type4 distance4 airport4 city4 state4)

label variable airport0 "Origin Airport Code (3 characters)"
label variable city0 "Origin City Market ID (5 digits)"
label variable state0 "State Code (2 digits)"

* Convert variables to a usable form
**destring fare quarter coupon_num passenger city0 state0, replace
local vars fare quarter coupon_num passenger city0 state0
foreach m of local vars {
	gen long `m'Temp = real(`m')
	order `m'Temp, after(`m')
	drop `m'
	rename `m'Temp `m'
}

forvalues n=1/4 {
	*Set our default is restriced coach class (X): restriced
	gen restricted`n'=1 if inlist(fare_type`n', "F", "C", "Y")
	replace restricted`n'=0 if inlist(fare_type`n', "G", "D", "X")
	*tab fare_type`n' restricted`n', m
	gen business`n'=1 if inlist(fare_type`n', "C", "D")
	replace business`n'=0 if inlist(fare_type`n', "F", "G", "X", "Y")
	*tab fare_type`n' business`n', m
	gen first`n'=1 if inlist(fare_type`n', "F", "G")
	replace first`n'=0 if inlist(fare_type`n', "C", "D", "X", "Y")
	*tab fare_type`n' first`n', m
	**destring distance`n' city`n' state`n', replace
	local vars distance`n' city`n' state`n'
	foreach m of local vars {
		gen long `m'Temp = real(`m')
		order `m'Temp, after(`m')
		drop `m'
		rename `m'Temp `m'
	}
}

* convert quarter(integer) to datetime
tostring quarter, gen(quarter_tq3)
replace quarter_tq3 = substr(quarter_tq3, 1, 4) + "q" + substr(quarter_tq3, -1, .)
gen quarter_tq2 = quarterly(quarter_tq3, "YQ") // replace gives type mismatch error
gen quarter_tq = quarter
replace quarter = quarter_tq2
format quarter %tq
drop quarter_tq quarter_tq2 quarter_tq3

************************************
***      3.Sample Selection      ***
************************************
drop if dollar_id == "*" //questionable fare value
drop if coupon_num>4 //more than 4 coupons are excluded
drop opeartin_carrier_4-state_id2_15 dollar_id coupon1 coupon2 coupon3 coupon4

gegen fare_type_group = group(business1 first1 business2 first2 business3 first3 business4 first4)
gegen IQRfare=iqr(fare), by(fare_type_group)
gegen P25fare=pctile(fare), p(25) by(fare_type_group)
gegen P75fare=pctile(fare), p(75) by(fare_type_group)
gen Ifare=(fare>P75fare+3*IQRfare | fare<P25fare-3*IQRfare) if fare<. & IQRfare<. & P25fare<. & P75fare<.
gen fareI=fare if Ifare!=1 & fare > 0
drop IQRfare P25fare P75fare fare_type_group 
replace index = _n

save "dta_clean/${dataset}_clean", replace
