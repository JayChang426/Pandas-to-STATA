clear all
global parent_path "C:\Users\johan\OneDrive\桌面\研究所學習\RA\Pandas-to-STATA"

****************
    *Step 1*
****************
import excel "$parent_path\bown-jung-zhang-2019-06-12.xlsx",firstrow sheet(China Tariff Rates) // choosing shhet
gen hs8 = substr(hs10, 1, 8) // this is for further grouping
gen hs6 = substr(hs10, 1, 6) // this is for further grouping
* the author said that for most trade data in this project, hs6 is the most suitable one to use as a index to merge with other data

****************
    *Step 2*
****************
* preparing for reshape
rename January12018MFNTariffRates tariff20180101
rename April22018RetaliationtoUS tariff20180402
rename May12018ChangeofMFNtariff tariff20180512
rename July12018ChangeofMFNtarif tariff20180701
rename July62018RetaliationtoUSS tariff20180706
rename August232018RetaliationtoU tariff20180823
rename September242018Retaliationt tariff20180924
rename November12018ChangeofMFNt tariff20181101
rename January12019Changeoftempor tariff20190101
rename January12019Suspensionofre tariff20190102
rename June12019Changeofretaliati tariff20190612

* reshape to long
reshape long tariff, i(hs10) j(time_of_tariff, string) // obs: 129,690, correct!
* (note: j(time_of_tariff) = 01012018 01012019 01022019 04022018 05012018 06012019 07012018 07062018 08232018 09242018 11012018)

****************
    *Step 3*
****************
* cummulative sum
gen value = tariff // creat an identical variable of tariff to make sure the missing value not to be replace by cummulative sum in order to be consistent to the author's data
bysort hs10 (time_of_tariff) : gen cum_tariff = sum(tariff) // cumulative sum, sort by hs10(first) and time_of_tariff(second)
replace cum_tariff =  . if value == . // putting the missing data back
collapse (max) cum_tariff, by(hs6 time_of_tariff) // finding finding maxima in the same hs6 and time_of_tariff, Obs: 59,257, correct!
sort hs6 (time_of_tariff)
drop if time_of_tariff == "20190101" // Obs: 53,870, correct!

save "$parent_path\updated_tariff_data\updated_tariff_data_finished.dta", replace
* export delimited time_of_tariff hs6 cum_tariff updated_tariff_data_finished.csv
* since we will use this data in later section, so it is not necessary to convert it to .csv as the author did. Also, exporting time-series are not allowed in.csv format, so I choose not to do this.

*********************************************************************** 
*Test whether data I created are consistent to what the author created*
*********************************************************************** 
* merge for test
use "$parent_path\updated_tariff_data\updated_tariff_data_finished.dta"
gen index = _n - 1 // setting a distinct variable to merge
rename hs6 hs6_mine // reaname to keep naics that we created, otherwise it will be overwritten by the test data
merge 1:1 index using "$parent_path\data_check\updated_tariff_data_test.dta", force

* create testing variables and test them
gen tariff_test = round(tariff, 0.00001)
gen cum_tariff_test = round(cum_tariff, 0.00001) // set this for checking, otherwise 'assert' command will be false since there is some tiny difference after 10 demical places
assert hs6_mine == hs6 // correct!
assert cum_tariff_test == tariff_test // correct!






