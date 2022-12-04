clear all
global parent_path "C:\Users\johan\OneDrive\桌面\研究所學習\RA\Pandas-to-STATA"
cd "$parent_path"

* Actually, there is no 'Step 1, Step 2, Step 3, ......' in this file, 
* so I directly name the titles of each step what the author capitalize in the explanation.

*****************************
*First Read in the HS10 Data*
*****************************
use "$parent_path\all_trade.dta"
rename ALL_VAL_MO total_trade
destring total_trade, replace // make total_trade numbers in order to do calculation
order time, first // take time as index

drop if index >= 107851 // keeping data within 2017
collapse (sum) total_trade, by (E_COMMODITY) // aggregating trade volume in each E_COMMODITY code, Obs: 9151, correct!
rename E_COMMODITY commodity
save "$parent_path/alt_hs_naics_mapping/all_trade_modified.dta", replace

********************************
*Read in the Census Concordance*
********************************
clear all
import excel "$parent_path/expconcord17.xls", sheet("expconcord17") firstrow // for this data file, I directly grab it on its website since it is just a simple .xls
gen hs8 = substr(commodity, 1, 8) // this is for further grouping
gen hs6 = substr(commodity, 1, 6) // this is for further grouping, 
* the author said that for most trade data in this project, 'hs6' is the most suitable one to use as a index to merge with other data
drop descriptn abbreviatn unit_qy1 unit_qy2 sitc end_use usda hitech // droping iseless variables
save "$parent_path/alt_hs_naics_mapping/expconcord17.dta", replace

********************
*Then Merge the Two*
********************
clear all
use "$parent_path\alt_hs_naics_mapping\all_trade_modified.dta"
merge 1:1 commodity using "$parent_path/alt_hs_naics_mapping/expconcord17.dta" // 9,139 matched perfectly
drop if _merge == 1 // cleaning data not merged from master (not merged from using is not deleted by the author), Obs: 9,325, correct!
save "$parent_path/alt_hs_naics_mapping/merged_trade.dta", replace

*************************************
*Then Groupby and Assign Naics Codes*
*************************************
clear all
use "$parent_path/alt_hs_naics_mapping/merged_trade.dta"
clonevar total_trade_2 = total_trade // create an identical variable for making comparison in the next few steps
*ssc install gtools // this involves gcollapse command, which is more convenient in keeping other variables when doing collapse
gcollapse (max) total_trade_2, by (hs6) merge replace // merge means bringing other variables back to the original data, otherwise other variables will be deleted
replace total_trade = 0 if total_trade < total_trade_2 | (total_trade_2 != . & total_trade == .) // the latter conditions are for those missing on total_trade data
drop if total_trade == 0
* What we have done in the above two lines are to drop observations that are "not" maxima in the group of the same hs6
drop commodity hs8 _merge total_trade_2 // drop useless variable (to be consistent with the data as the author)
save "$parent_path/alt_hs_naics_mapping/merged_trade_modified.dta", replace

*********************************************************************** 
*Test whether Data I Created Are Consistent to What the Author Created*
*********************************************************************** 
clear all
use "$parent_path/alt_hs_naics_mapping/merged_trade_modified.dta"
rename naics naics_mine // reaname to keep naics that we created, otherwise it will be overwritten by the test data
merge 1:1 hs6 using "$parent_path/data_check/alt_hs_naics_mapping_test.dta"
assert naics_mine == naics // correct!

/* other simple check: 
Obs: 5,376, correct!
duplicates list hs6 (0 observation since every hs6 code should be unique)
compare the following search in "merged_trade_modified.dta" with the "merged_trade.dta" data
use ctrl+F to search in data browser
search "841391", since naics 333911 has a greater total_trade, it is preserved
*/





