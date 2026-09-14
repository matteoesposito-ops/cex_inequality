* Extracts the MS vehicle service flow (interview-level, on newid) for ALL years.
* Run once; every wave/year script then merges this single file.

clear all
do "../globalpaths.do"

use "$data/all_cons_data_for_stata_80_17.dta", clear
* you can add more years here
* note the we are using the survey year variable, not the actual year
keep if inrange(srv_year, 109, 112)   
keep newid n_tot_vflow1
capture confirm string variable newid
if !_rc destring newid, replace
duplicates drop newid, force
save "$data2010/ms_vflow_09_12.dta", replace