clear all
* using the all_trade.dta (grab by Pandas)
cd "/Users/changjay/Desktop/Pandas-to-STATA Project/alt_hs_naics_mapping"

use "all_trade.dta"
rename ALL_VAL_MO total_trade
destring total_trade, replace // make total_trade numbers in order to do calculation
order time, first // take time as index (but it's still number, hard to convert?)

drop if index >= 107851 // keeping data within 2017
collapse (sum) total_trade, by (E_COMMODITY) // Obs: 9151, correct!
rename E_COMMODITY commodity
save "/Users/changjay/Desktop/Pandas-to-STATA Project/alt_hs_naics_mapping/all_trade_modified.dta", replace

* using concordance
clear all
import excel "/Users/changjay/Desktop/Pandas-to-STATA Project/alt_hs_naics_mapping/expconcord17.xls", sheet("expconcord17") firstrow // for this data file, I directly grab it on its website since it is just a simple .xls
gen hs8 = substr(commodity, 1, 8) // this is for further grouping
gen hs6 = substr(commodity, 1, 6) // this is for further grouping, 
* the author said that for most trade data in this project, hs6 is the most suitable one to use as a index to merge with other data
drop descriptn abbreviatn unit_qy1 unit_qy2 sitc end_use usda hitech // droping variables not used in further research
save "/Users/changjay/Desktop/Pandas-to-STATA Project/alt_hs_naics_mapping/expconcord17.dta", replace

clear all
use "all_trade_modified.dta"
merge 1:1 commodity using "/Users/changjay/Desktop/Pandas-to-STATA Project/alt_hs_naics_mapping/expconcord17.dta" // 9,139 matched perfectly
drop if _merge == 1 // cleaning data not merged from master (not merged from using is not deleted by the author), Obs: 9,325, correct!
save "/Users/changjay/Desktop/Pandas-to-STATA Project/alt_hs_naics_mapping/merged_trade.dta", replace

clear all
use "merged_trade.dta"
clonevar total_trade_2 = total_trade // create an identical variable for making comparison in the next few steps
* ssc install gtools // this involves gcollapse command, which is more convenient in keeping other variables when doing collapse
gcollapse (max) total_trade_2, by (hs6) merge replace // merge means bringing other variables back to the original data, otherwise other variables will be deleted
replace total_trade = 0 if total_trade < total_trade_2 | (total_trade_2 != . & total_trade == .) // the latter conditions are for those missing on total_trade data
drop if total_trade == 0
* What we have done in the above two lines are to drop observations that are "not" maxima in the group of the same hs6
save "/Users/changjay/Desktop/Pandas-to-STATA Project/alt_hs_naics_mapping/merged_trade_modified.dta", replace
/* check: 
Obs: 5,376, correct!
duplicates list hs6 (0 observation since every hs6 code should be unique)
compare the following search in "merged_trade_modified.dta" with the "merged_trade.dta" data
use ctrl+F to search in data browser
search "841391", since naics 333911 has a greater total_trade, it is preserved
*/




