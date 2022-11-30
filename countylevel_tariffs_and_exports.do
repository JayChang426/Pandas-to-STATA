**********
* STEP 1 *
**********
* Only have to do the following three commands only the first time to tranform the data into .dta file.
cd "/Users/changjay/Desktop/Pandas-to-STATA Project/countylevel_tariffs_and_exports"
import delimited "step1_initial.csv", stringcols(2 4 9) numericcols(3) clear
save "step1_initial.dta", replace

* main adjustments for the data
use "step1_initial.dta", clear
keep if agglvl_code == 75
keep if own_code == 5
gen area_fips_head = substr(area_fips, 1, 2) // create this to drop some useless observations
drop if area_fips_head == "72" | area_fips_head == "78" | area_fips_head == "02" | area_fips_head == "15" // keep observations with area_fips_head other than "72", "78", "02", or "15". obs: 199,393, correct!
drop area_fips_head // this temporary variable can be dropped
collapse (sum) annual_avg_emplvl, by (industry_code) // sum annual_avg_emplvl in the same industry_code
rename annual_avg_emplvl nat_emplvl
save "step1.dta", replace // correspond to df.national

* Check: We check if there's any difference in nat_emplvl.
* import the output created by pandas
import delimited "step1_pandas.csv", clear
tostring industry_code, replace // in order to merge (when merging, the key in both files should have the same type)
save "step2_pandas.dta", replace

* merge our data and the data produced by pandas
use "step1.dta", clear
clonevar nat_emplvl_test = nat_emplvl
merge 1:1 industry_code using "step2_pandas.dta"

* assertion
assert nat_emplvl_test == nat_emplvl

* total(nat_emplvl) // checking the sum of nat_emplvl

**********
* STEP 2 *
**********
* Only have to do the following two importing commands only the first time to tranform the .csv into .dta file.
* import the china trade csv
cd "/Users/changjay/Desktop/Pandas-to-STATA Project/countylevel_tariffs_and_exports"
import delimited "step2_china.csv", stringcols(2) clear
save "step2_china.dta", replace

* import the world trade csv
import delimited "step2_world.csv", stringcols(2) clear
save "step2_world.dta", replace

* merge the two with key e_commodity and time
use "step2_china.dta", clear
merge 1:1 e_commodity time using "step2_world.dta"
keep e_commodity comm_lvl total_trade china_trade time
save "step2.dta", replace

* Check: We check whether observations with the same e_commodity code and time have the same china_trade and total_trade.
* For the first time you need to import the output created by pandas.
import delimited "step2_pandas.csv", stringcols(2) clear
save "step2_pandas.dta", replace

* merge our data and the data produced by pandas
use "step2.dta", clear
clonevar china_trade_test = china_trade
clonevar total_trade_test = total_trade
merge 1:1 e_commodity time using "step2_pandas.dta"

* assertions
assert china_trade_test == china_trade
assert total_trade_test == total_trade // both are correct!

**********
* STEP 3 *
**********
clear all
cd "/Users/changjay/Desktop/Pandas-to-STATA Project/countylevel_tariffs_and_exports"
use "step2.dta" , clear
gen time_stata=date(time,"YMD")
drop time
format time_stata %td
keep if year(time_stata)==2017
collapse (sum) china_trade, by (e_commodity) // obs: 5320, correct!
rename e_commodity hs6
tostring hs6, replace

merge 1:1 hs6 using "/Users/changjay/Desktop/Pandas-to-STATA Project/alt_hs_naics_mapping/merged_trade_modified.dta", keep(1 3) // obs: 5320, correct!
keep china_trade hs6 naics
gen naics_4 = substr(naics, 1, 4)
gen naics_3 = substr(naics, 1, 3)
rename china_trade china_trade_2017 //the variable name can't be openedd with numbers
collapse (sum) china_trade_2017, by (naics_3) // obs: 31, correct!
save "step3_china.dta", replace

use "step1.dta", clear
rename industry_code naics_3
merge 1:1 naics_3 using "step3_china.dta", keep(1 3)

egen total_china_trade_2017 = total(china_trade_2017)
gen trd_wts = china_trade_2017 / total_china_trade_2017 
total(trd_wts) // = 1, correct!
replace china_trade_2017 = 0 if china_trade_2017 == .
replace trd_wts = 0 if trd_wts == .
keep naics_3 nat_emplvl china_trade_2017 trd_wts
save "step3.dta", replace

* Check: We check whether the same naics_3 leads to the same nat_emplvl, china_trade_2017, and trd_wts (the weights)
* Do the following commands only one time since we'll have to save it, and this will cover the original version of data from pandas.
use "step3_pandas.dta", clear
rename industry_code naics_3
drop index
gen trd_wts_round = round(trd_wts, .0000001) // create this for assertion
save "step3_pandas.dta", replace

* Now we prepare to merge the two data
use "step3.dta", clear
rename nat_emplvl nat_emplvl_test
rename china_trade_2017 china_trade_2017_test
gen trd_wts_test = round(trd_wts, .0000001) // create this for assertion
merge 1:1 naics_3 using "step3_pandas.dta"

* assertions
assert nat_emplvl_test == nat_emplvl
assert china_trade_2017_test == _2017_china_trade
assert trd_wts_test == trd_wts_round // all correct!










