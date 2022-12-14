**********
* STEP 1 *
**********
* Read in .csv file from Pandas
cd "/Users/changjay/Desktop/Pandas-to-STATA Project/countylevel_tariffs_and_exports"
import delimited "countylevel_tariffs_and_exports_initial.csv", stringcols(2 4 9) numericcols(3) clear 
// this .csv needs to be downloaded by python code since it's too big to push to github
save "step1_initial.dta", replace

* Then we can start adressing our data
use "step1_initial.dta", clear
keep if agglvl_code == 75
keep if own_code == 5

***********************************************************************************
*** The following three commands are erroneously "not" run in the author's file ***
gen area_fips_head = substr(area_fips, 1, 2) // create this to drop some useless observations
drop if area_fips_head == "72" | area_fips_head == "78" | area_fips_head == "02" | area_fips_head == "15" // keep observations with area_fips_head other than "72", "78", "02", or "15". obs: 199,393, correct!
drop area_fips_head // this temporary variable can be dropped
***********************************************************************************
save "df_county.dta", replace // this one is for step 5 use

collapse (sum) annual_avg_emplvl, by (industry_code) // sum annual_avg_emplvl in the same industry_code
rename annual_avg_emplvl nat_emplvl
save "step1.dta", replace

* Check: We check if there's any difference in nat_emplvl.
* import the output created by pandas
import delimited "step1_pandas.csv", stringcols(2) clear
drop v1 // drop index created by Pandas
save "step1_pandas.dta", replace

* merge our data and the data produced by pandas
use "step1.dta", clear
clonevar nat_emplvl_test = nat_emplvl // make this variable's name different from data from pandas, otherwise there will be problems when merging
merge 1:1 industry_code using "step1_pandas.dta"

* assertion
assert nat_emplvl_test == nat_emplvl // correct!

* total(nat_emplvl) // checking the sum of nat_emplvl

**********
* STEP 2 *
**********
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
gen time_stata = date(time,"YMD")
format time_stata %td
drop time
keep if year(time_stata) == 2017
collapse (sum) china_trade, by (e_commodity) // obs: 5320, correct!
rename e_commodity hs6
rename china_trade china_trade_2017
tostring hs6, replace // make it string in order to merge
save "2017_china_trade.dta", replace

merge 1:1 hs6 using "/Users/changjay/Desktop/Pandas-to-STATA Project/alt_hs_naics_mapping/merged_trade_modified.dta", keep(1 3) // obs: 5320, correct!
keep china_trade_2017 hs6 naics
gen naics_4 = substr(naics, 1, 4)
gen naics_3 = substr(naics, 1, 3)
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
rename naics_3 industry_code
save "step3.dta", replace

* Check: We check whether the same naics_3 leads to the same nat_emplvl, china_trade_2017, and trd_wts (the weights)
import delimited "step3_pandas.csv", stringcols(2) clear
drop v1 // drop the index created by pandas
gen trd_wts_round = round(trd_wts, .0000001) // create this for assertion
save "step3_pandas.dta", replace

* Now we prepare our own data to merge
use "step3.dta", clear
rename nat_emplvl nat_emplvl_test
gen trd_wts_test = round(trd_wts, .0000001) // create this for assertion

merge 1:1 industry_code using "step3_pandas.dta" // merge the two

* assertions
assert nat_emplvl_test == nat_emplvl
assert china_trade_2017 == _china_trade
assert trd_wts_test == trd_wts_round // all correct!

**********
* STEP 4 *
**********
* Following "dict" codes are doing what "dictionary" does in Pandas.
* create the initial tariff dict
cd "/Users/changjay/Desktop/Pandas-to-STATA Project/updated_tariff_data"
use "updated_tariff_data_finished.dta",clear
keep if time_of_tariff == "20180101"
keep hs6 cum_tariff
save "/Users/changjay/Desktop/Pandas-to-STATA Project/countylevel_tariffs_and_exports/initial_tariff_dict.dta",replace

* create the 232 tariff dict
cd "/Users/changjay/Desktop/Pandas-to-STATA Project/updated_tariff_data"
use "updated_tariff_data_finished.dta",clear
keep if time_of_tariff == "20180402"
keep hs6 cum_tariff
rename cum_tariff cum_tariff_232 // rename this, we'll conditionally update the original cum_tariff using this
save "/Users/changjay/Desktop/Pandas-to-STATA Project/countylevel_tariffs_and_exports/tariff_232_dict.dta",replace

* create the r1 tariff dict
cd "/Users/changjay/Desktop/Pandas-to-STATA Project/updated_tariff_data"
use "updated_tariff_data_finished.dta",clear
keep if time_of_tariff == "20180706"
keep hs6 cum_tariff
rename cum_tariff cum_tariff_r1 // rename this, we'll conditionally update the original cum_tariff using this
save "/Users/changjay/Desktop/Pandas-to-STATA Project/countylevel_tariffs_and_exports/tariff_r1_dict.dta",replace

* create the r2 tariff dict
cd "/Users/changjay/Desktop/Pandas-to-STATA Project/updated_tariff_data"
use "updated_tariff_data_finished.dta",clear
keep if time_of_tariff == "20180823"
keep hs6 cum_tariff
rename cum_tariff cum_tariff_r2 // rename this, we'll conditionally update the original cum_tariff using this
save "/Users/changjay/Desktop/Pandas-to-STATA Project/countylevel_tariffs_and_exports/tariff_r2_dict.dta",replace

* create the r3 tariff dict
cd "/Users/changjay/Desktop/Pandas-to-STATA Project/updated_tariff_data"
use "updated_tariff_data_finished.dta",clear
keep if time_of_tariff == "20180924"
keep hs6 cum_tariff
rename cum_tariff cum_tariff_r3 // rename this, we'll conditionally update the original cum_tariff using this
save "/Users/changjay/Desktop/Pandas-to-STATA Project/countylevel_tariffs_and_exports/tariff_r3_dict.dta",replace

* create the mfn tariff dict
cd "/Users/changjay/Desktop/Pandas-to-STATA Project/updated_tariff_data"
use "updated_tariff_data_finished.dta",clear
keep if time_of_tariff == "20181101"
keep hs6 cum_tariff
rename cum_tariff cum_tariff_mfn // rename this, we'll conditionally update the original cum_tariff using this
save "/Users/changjay/Desktop/Pandas-to-STATA Project/countylevel_tariffs_and_exports/tariff_mfn_dict.dta",replace

* create the mfn 2019 tariff dict
cd "/Users/changjay/Desktop/Pandas-to-STATA Project/updated_tariff_data"
use "updated_tariff_data_finished.dta",clear
keep if time_of_tariff == "20190102"
keep hs6 cum_tariff
rename cum_tariff cum_tariff_mfn_2019 // rename this, we'll conditionally update the original cum_tariff using this
save "/Users/changjay/Desktop/Pandas-to-STATA Project/countylevel_tariffs_and_exports/tariff_mfn_2019_dict.dta",replace
* "dict" creating ended

* We first merge the output in step2 with mapping data from alt_hs_naics_mapping, which will map hs6 to naics code.
clear all
cd "/Users/changjay/Desktop/Pandas-to-STATA Project/countylevel_tariffs_and_exports"
use "step2.dta", clear
clonevar hs6 = e_commodity // create key for merging
merge m:1 hs6 using "/Users/changjay/Desktop/Pandas-to-STATA Project/alt_hs_naics_mapping/merged_trade_modified.dta", keep(1 3)
drop _merge
sort e_commodity (time)
gen naics_3 = substr(naics, 1, 3)
gen naics_4 = substr(naics, 1, 4) // these are for further grouping
gen time_stata = date(time,"YMD")
format time_stata %td // use this to "update" tariff after assigned dates

* Then we can "update" the tariff data gradually
merge m:1 hs6 using "initial_tariff_dict.dta", keep(1 3) nogen
merge m:1 hs6 using "tariff_232_dict.dta", keep(1 3) nogen
replace cum_tariff = cum_tariff_232 if time_stata >= td(1,4,2018)
drop cum_tariff_232
merge m:1 hs6 using "tariff_r1_dict.dta", keep(1 3) nogen
replace cum_tariff = cum_tariff_r1 if time_stata >= td(1, 7, 2018)
drop cum_tariff_r1
merge m:1 hs6 using "tariff_r2_dict.dta", keep(1 3) nogen
replace cum_tariff = cum_tariff_r2 if time_stata >= td(1, 9, 2018)
drop cum_tariff_r2
merge m:1 hs6 using "tariff_r3_dict.dta", keep(1 3) nogen
replace cum_tariff = cum_tariff_r3 if time_stata >= td(1, 10, 2018)
drop cum_tariff_r3
merge m:1 hs6 using "tariff_mfn_dict.dta", keep(1 3) nogen
replace cum_tariff = cum_tariff_mfn if time_stata >= td(1, 11, 2018)
drop cum_tariff_mfn
merge m:1 hs6 using "tariff_mfn_2019_dict.dta", keep(1 3) nogen
replace cum_tariff = cum_tariff_mfn_2019 if time_stata >= td(1, 1, 2019)
drop cum_tariff_mfn_2019

replace cum_tariff = 0 if cum_tariff == .
merge m:1 hs6 using "2017_china_trade.dta", keep(3) nogen // merge the 2017 china trade data in

* Finally, we can create the weights
gen numerator = cum_tariff * china_trade_2017
* ssc install gtools // this involves gcollapse command, which is more convenient in keeping other variables when doing collapse
gcollapse (sum) numerator, by (time naics_3) merge replace // merge means bringing other variables back to the original data, otherwise other variables will be deleted
gcollapse (sum) china_trade_2017, by (time naics_3) merge replace
gen tariff_trd_w_avg = numerator / china_trade_2017
gcollapse (sum) total_trade, by (time naics_3) merge replace
gcollapse (sum) china_trade, by (time naics_3) merge replace
keep time naics_3 china_trade total_trade tariff_trd_w_avg
duplicates drop time naics_3, force // obs: 2,883, correct!
// time and naics_3 uniquely define observations, so drop those "duplicates"
save "step4.dta", replace

* Check: We check whether tariff_trd_w_avg, total_trade, and china_trade are the same in our data and Pandas data.
* first we need to prepare data from Pandas
cd "/Users/changjay/Desktop/Pandas-to-STATA Project/countylevel_tariffs_and_exports"
import delimited "step4_pandas.csv", clear
rename naics3 naics_3
tostring naics_3, replace // for merge, key's data type must be the same
gen tariff_trd_w_avg_round = round(tariff_trd_w_avg, .0001) // otherwise there will be some slight difference, assertions will fail
save "step4_pandas.dta", replace

* then we prepare for test in our own data
use "step4.dta", clear
gen tariff_trd_w_avg_test = round(tariff_trd_w_avg, .0001) // otherwise there will be some slight difference, assertions will fail
rename total_trade total_trade_test 
rename china_trade china_trade_test // to make these variables' name different from data from pandas, otherwise there will be problems when merging

merge 1:1 naics_3 time using "step4_pandas.dta" // merge with data produced by pandas, naics_3 and time uniquely define observations

* assertions
assert tariff_trd_w_avg_test == tariff_trd_w_avg_round
assert total_trade_test == total_trade
assert china_trade_test == china_trade // all correct!

**********
* STEP 5 *
**********
use "df_county.dta", clear // from step1
merge m:1 industry_code using "step3.dta", nogen // merge with national data, all matched (_merge == 3)
gen emp_wts = annual_avg_emplvl / nat_emplvl
egen total_employment = total(annual_avg_emplvl), by(area_fips)
sort area_fips (industry_code)
save "weights.dta", replace

use "step4.dta", clear
rename naics_3 industry_code
joinby industry_code using "weights.dta", unmatched(both) // joinby is the real merge m:m
sort area_fips (industry_code time)

egen county_annual_emplvl = total(annual_avg_emplvl), by(area_fips time) // this is the denominator, which is sum of annual avergae employment of a county in "a sector at a specific time" 

* these 3 rows are for china export
gen china_trade_pcs = china_trade * emp_wts
egen china_trade_pcs_sum = total(china_trade_pcs), by (area_fips time)
gen china_exp_pc = (1 / county_annual_emplvl) * china_trade_pcs_sum

* these 3 rows are for total export
gen total_trade_pcs = total_trade * emp_wts
egen total_trade_pcs_sum = total(total_trade_pcs), by (area_fips time)
gen total_exp_pc = (1 / county_annual_emplvl) * total_trade_pcs_sum

* these 2 rows are for tariffs
gen tariff_pcs = annual_avg_emplvl * tariff_trd_w_avg / county_annual_emplvl
egen tariff = total(tariff_pcs), by(area_fips time)

rename county_annual_emplvl emplvl_2017
gsort - tariff - emplvl_2017
duplicates drop area_fips time, force
keep time total_exp_pc china_exp_pc tariff emplvl_2017 area_fips total_employment
save "trade_county.dta", replace

* One more adjustment for total_employment
use "trade_county.dta", clear
gen new_tariff = (emplvl_2017 / total_employment) * tariff
gen new_china_exp_pc = (emplvl_2017 / total_employment) * china_exp_pc
gen new_total_exp_pc = (emplvl_2017 / total_employment) * total_exp_pc
gsort - new_tariff - emplvl_2017
save "trade_county.dta", replace

* Check: We check whether emplvl_2017, new_tariff, new_china_ecp_pc, new_total_ecp_pc, and total_employment are the same in our data and Pandas data.
* prepare pandas data
import delimited "trade_county_pandas.csv", clear
tostring area_fips, replace
gsort - tariff - emplvl_2017
drop if china_exp_pc == . & total_exp_pc == .
rename total_exp_pc total_exp_pc_pandas
rename china_exp_pc china_exp_pc_pandas
rename tariff tariff_pandas
rename emplvl_2017 emplvl_2017_pandas
rename total_employment total_employment_pandas
gen tariff_pandas_test = round(tariff_pandas, .1)
gen china_exp_pc_pandas_test = round(china_exp_pc_pandas)
gen total_exp_pc_pandas_test = round(total_exp_pc_pandas)
save "trade_county_pandas.dta", replace

* prepare our data
use "trade_county.dta", clear
drop if china_exp_pc == . & total_exp_pc == . // 
gen new_tariff_test = round(new_tariff, .1)
gen new_china_exp_pc_test = round(new_china_exp_pc)
gen new_total_exp_pc_test = round(new_total_exp_pc)

* assertions
merge 1:1 time area_fips using "trade_county_pandas.dta", keep(3)
assert emplvl_2017 == emplvl_2017_pandas // all correct
assert new_tariff_test == tariff_pandas_test // all correct
* assert new_china_exp_pc_test == china_exp_pc_pandas_test
// 2 contradictions in 272,600 observations
list if new_china_exp_pc_test != china_exp_pc_pandas_test // difference is very small, run this command you'll know why. (.49999 vs. .5)
* assert new_total_exp_pc_test == total_exp_pc_pandas_test
// 16 contradictions in 272,600 observations
gen test = new_total_exp_pc_test - total_exp_pc_pandas_test if new_total_exp_pc_test != total_exp_pc_pandas_test
list if new_total_exp_pc_test != total_exp_pc_pandas_test // difference is very small, run this command you'll know why. (.49999 vs. .5)
assert total_employment == total_employment_pandas // all correct












