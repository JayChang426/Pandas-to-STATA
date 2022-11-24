**********
* STEP 1 *
**********
clear all
* Only have to do the following three commands only the first time to tranform the data into .dta file.
cd "/Users/changjay/Desktop/Pandas-to-STATA Project/countylevel_tariffs_and_exports"
import delimited "step1_initial.csv"
save "step1_initial.dta", replace

use "step1_initial.dta", clear
keep if agglvl_code == 75
keep if own_code == 5
gen area_fips_head = substr(area_fips, 1, 2)
drop if area_fips_head == "72" | area_fips_head == "78" | area_fips_head == "02" | area_fips_head == "15" // obs: 199,393, correct!
collapse (sum) annual_avg_emplvl, by (industry_code)
rename annual_avg_emplvl nat_emplvl
* total(nat_emplvl) // checking the sum of nat_emplvl
save "step1.dta", replace // correspond to df.national

* 

**********
* STEP 2 *
**********
clear all
* Only have to do the following three commands only the first time to tranform the data into .dta file.
cd "/Users/changjay/Desktop/Pandas-to-STATA Project/countylevel_tariffs_and_exports"
import delimited "step2_china.csv"
save "step2_china.dta", replace

import delimited "step2_world.csv"
save "step2_world.dta", replace

use "step2_china.dta", clear
merge 1:m using e_commodity time using "step2_world.dta"

use "step2_world.dta", clear

* Actually it just requested two data from some url and merged then together, nothing is done other than this.
* So I directly give you the .dta file and skip this step.

























