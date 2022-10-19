clear all
*using updated tariff data
cd "/Users/changjay/Desktop/Pandas-to-STATA Project/updated_tariff_data"
import excel "bown-jung-zhang-2019-06-12.xlsx",firstrow sheet(China Tariff Rates) // choosing shhet

gen hs8 = substr(hs10, 1, 8) // this is for further grouping
gen hs6 = substr(hs10, 1, 6) // this is for further grouping

*preparing for reshape
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
* save "/Users/changjay/Desktop/Pandas-to-STATA Project/updated_tariff_data/updated_tariff_data_reshaped.dta", replace
* (note: j(time_of_tariff) = 01012018 01012019 01022019 04022018 05012018 06012019 07012018 07062018 08232018 09242018 11012018)

* since saving the reshaped data will exceed the limit of git(100MB), I comment those codes

* clear all
* use "/Users/changjay/Desktop/Pandas-to-STATA Project/updated_tariff_data/updated_tariff_data_reshaped.dta"
* cumulative sum and sorting
replace tariff = 0 if tariff == . // 56 "." is replaced by 0
bysort hs10 (time_of_tariff) : gen cum_tariff = sum(tariff) // cumulative sum, sort by hs10(first) and time_of_tariff(second)

* finding finding maxima in the same hs6 and time_of_tariff
collapse (max) cum_tariff, by(hs6 time_of_tariff) // Obs: 59257, correct!
sort hs6 (time_of_tariff)
drop if time_of_tariff == "20190101" // Obs: 59257, correct!
save "/Users/changjay/Desktop/Pandas-to-STATA Project/updated_tariff_data/updated_tariff_data_finished.dta", replace
* export delimited time_of_tariff hs6 cum_tariff updated_tariff_data_finished.csv // exporting time-series are not allowed in.csv format QQ


* not used code / method
* egen hs6_time = group(hs6 time_of_tariff) // making groups for the same hs6 and group
* clonevar tariff_2 = tariff // generate template data for intermediate use
