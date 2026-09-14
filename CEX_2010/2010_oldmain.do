********************************************************************************
* We append the 11 quarterly FMLY files of the CEX Interview Survey (2009Q2 -> 2011Q4) and aggregate to one row per consumer unit by summing across their 4 expenditure interviews, following Aguiar & Bils (2015).
*
* Inputs (CEX FMLY files):
*           fmli092.dta    Q2 2009
*           fmli093.dta    Q3 2009    fmli111x.dta   Q1 2011
*           fmli094.dta    Q4 2009    fmli112.dta    Q2 2011
*           fmli101x.dta   Q1 2010    fmli113.dta    Q3 2011
*           fmli102.dta    Q2 2010    fmli113.dta    Q4 2011
*           fmli103.dta    Q3 2010
*           fmli104.dta    Q4 2010
*         
* CU identifier and interview number
*    NEWID = 7-digit integer where the last digit is the interview number (2-5). 
*            Digits 1-6 (CU sequence number, 1 through 9999999) uniquely identify the CU.
*    CUID = 6-digit integer -> NEWID without last digit.
*
* Methodology:
*
*   Each interview reports the previous 3 months of expenditure (PQ + CQ), where PQ 
*   stands for expenditures that fall into previous quarter and CQ for current quarter.
*   Summing the four 3-month totals gives a 12-month annual expenditure measure.
*
*    Income is taken from the 5th interview (already a 12-month total). 
*    Note that the first interview is purely explorative 
*    and it's not reported in the data (hence, we have interviews 2-5).
*
*   We account for inflation across different years.
*
* Sample restrictions:
*   - CU completed all 4 expenditure interviews
*   - At least one reference month in calendar 2010
*   - Reference-person age 25-60 (5th interview)
*   - Owner or renter (cutenure 1-4)
*   - Pre-tax-and-transfer earned income >= $4,542.49 (= $5,000 in 2016)
*
* Then, we build the CLM (Comin-Lashkari-Mestieri) food-at-home / goods /
* services categorization, substituting the Meyer-Sullivan vehicle service flow.
*
* We compute pre and post-tax-and-transfer income, log-expenditure moments, and
* CLM expenditure shares by expenditure quintile (raw and OECD-equivalized).
********************************************************************************

* you need to put all_cons_data_for_stata_80_17.dta in the data folder
* since it's too heavy to have on github

clear all
set more off

do "../globalpaths.do"

*-------------------------------------------------------------------------------
* 0. Prepare the MS per-interview vehicle service flow.
*    MS store n_tot_vflow1 at the interview (newid) level on a quarterly scale
*    (the annual service flow divided by 4). We sum it back across a CU's four
*    interviews in the collapse below to recover an annual flow per CU.
*    Runs first because `use` clears memory.
*-------------------------------------------------------------------------------
use "$data/all_cons_data_for_stata_80_17.dta", clear
keep newid n_tot_vflow1
capture confirm string variable newid
if !_rc destring newid, replace        // match the numeric newid in our data
duplicates drop newid, force
save "$data2010/ms_vflow_2010.dta", replace


*-------------------------------------------------------------------------------
* 1. Append the 11 quarter files (2009 Q2 - 2011 Q4) into one dataset.
*    Each file contains interviews from one quarter (3 consecutive months).
*    Each interview reports the previous 3 months of expenditure.
*-------------------------------------------------------------------------------


use "$data2010/fmli092.dta", clear
gen long file_yq = 20092

append using "$data2010/fmli093.dta"
replace file_yq = 20093 if missing(file_yq)

append using "$data2010/fmli094.dta"
replace file_yq = 20094 if missing(file_yq)

append using "$data2010/fmli101x.dta"
replace file_yq = 20101 if missing(file_yq)

append using "$data2010/fmli102.dta"
replace file_yq = 20102 if missing(file_yq)

append using "$data2010/fmli103.dta"
replace file_yq = 20103 if missing(file_yq)

append using "$data2010/fmli104.dta"
replace file_yq = 20104 if missing(file_yq)

append using "$data2010/fmli111x.dta"
replace file_yq = 20111 if missing(file_yq)

append using "$data2010/fmli112.dta"
replace file_yq = 20112 if missing(file_yq)

append using "$data2010/fmli113.dta"
replace file_yq = 20113 if missing(file_yq)

append using "$data2010/fmli114.dta"
replace file_yq = 20114 if missing(file_yq)

destring qintrvmo qintrvyr, replace


*-------------------------------------------------------------------------------
* 2. Each interview asks about the previous 3 months. 
*    If the interview is in month m of year y, the 3 reference months are 
*    (m-3, m-2, m-1) of year y, rolling into year y-1 when m <= 3.
*
*    We flag whether ANY of the 3 reference months falls inside calendar 2010.
*-------------------------------------------------------------------------------


gen byte iv_no = mod(newid, 10)           // 2, 3, 4, or 5
gen byte touches_2010 = 0
forvalues k = 1/3 {
    * month being checked: qintrvmo - k (the k-th month before the interview)
    * encoded as year*12 + month for clean comparison
    local m_year_expr  "(qintrvyr - cond(qintrvmo - `k' < 1, 1, 0))"
    local m_month_expr "(qintrvmo - `k' + cond(qintrvmo - `k' < 1, 12, 0))"
    gen long m_ym_`k' = `m_year_expr' * 12 + `m_month_expr'
    replace touches_2010 = 1 if inrange(m_ym_`k', 2010*12 + 1, 2010*12 + 12)
    drop m_ym_`k'
}


*-------------------------------------------------------------------------------
* 3. For each summary expenditure category, build the 3-month total
*       <stem>_3mo = PQ + CQ
*-------------------------------------------------------------------------------

local stems ///
    totexp totex4 ///                                          /* totals */
    food fdhome fdaway ///                                     /* food */
    alcbev ///                                                 /* alcohol */
    hous shelt rendwe rntxrp othlod util  ///            /* housing */
    elctrc ntlgas fuloil othfls teleph watrps ///              /* utilities */
    housop domsrv dmsxcc bbyday ///                      /* household services */
    houseq furntr majapp smlapp textil flrcvr misceq ///       /* household goods */
    appar mensix womsix boyfif grlfif chldrn footwr othapl ///   /* apparel */
    trans cartkn cartku othveh gasmo vehfin mainrp vehins vrntlo pubtra ///  /* transport */
    health hlthin medsrv predrg medsup ///                     /* health */
    entert feeadm tvrdio otheqp pettoy othent ///                     /* entertainment */
    persca read educa tobacc ///                               /* personal, educ, tobacco */
    owndwe mrtint proptx mrpins ///                            /* owned dwellings */
    cashco perins           ///                                /* cash contrib & insurance */
	miscx4                                                     /* miscellaneous */

foreach s of local stems {
    gen double `s'_q = `s'pq + `s'cq
}

*-------------------------------------------------------------------------------
* 4. CPI-U deflation (convert nominal to constant 2010 dollars)
*
*   Series: CPI-U, U.S. city average, all items, NSA (BLS CUUR0000SA0)
*   Base:   2010 annual average = 218.056
*
*   Three reference periods are used:
*     - Expenditure _q vars: spending occurs across the 3-month reference
*                            period (qintrvmo-1, qintrvmo-2, qintrvmo-3). We *                            deflate by the AVERAGE CPI of those 3 months.
*     - Income vars (5th interview only): income is a 12-month total ending
*                            at the 5th interview. We deflate by the AVERAGE
*                            CPI of those 12 months.
*     - RENTEQVX (5th interview only): CPI at the 5th interview itself
*                                      = qintrvmo, qintrvyr
*        since question is : "If someone were to rent your home today, how much *                            do you think it would rent for monthly, unfurnished
*                            and without utilities?"
*-------------------------------------------------------------------------------

* Build monthly CPI-U lookup (Jan 2008 - Dec 2011)
tempfile cpi
preserve
    clear
    input int year int month double cpi_u
    2008  1 211.080
    2008  2 211.693
    2008  3 213.528
    2008  4 214.823
    2008  5 216.632
    2008  6 218.815
    2008  7 219.964
    2008  8 219.086
    2008  9 218.783
    2008 10 216.573
    2008 11 212.425
    2008 12 210.228
    2009  1 211.143
    2009  2 212.193
    2009  3 212.709
    2009  4 213.240
    2009  5 213.856
    2009  6 215.693
    2009  7 215.351
    2009  8 215.834
    2009  9 215.969
    2009 10 216.177
    2009 11 216.330
    2009 12 215.949
    2010  1 216.687
    2010  2 216.741
    2010  3 217.631
    2010  4 218.009
    2010  5 218.178
    2010  6 217.965
    2010  7 218.011
    2010  8 218.312
    2010  9 218.439
    2010 10 218.711
    2010 11 218.803
    2010 12 219.179
    2011  1 220.223
    2011  2 221.309
    2011  3 223.467
    2011  4 224.906
    2011  5 225.964
    2011  6 225.722
    2011  7 225.922
    2011  8 226.545
    2011  9 226.889
    2011 10 226.421
    2011 11 226.230
    2011 12 225.672
    end
    gen int ym = year * 12 + month
    keep ym cpi_u
    save `cpi'
restore

scalar cpi_base = 218.056   // 2010 annual average

* Deflate expenditure _q variables
forvalues k = 1/3 {
    gen int ym = (qintrvyr - cond(qintrvmo - `k' < 1, 1, 0)) * 12 ///
              + (qintrvmo - `k' + cond(qintrvmo - `k' < 1, 12, 0))
    merge m:1 ym using `cpi', keep(master match) keepusing(cpi_u) nogen
    rename cpi_u cpi_ref`k'
    drop ym
}

gen double cpi_exp = (cpi_ref1 + cpi_ref2 + cpi_ref3) / 3
drop cpi_ref1 cpi_ref2 cpi_ref3

foreach s of local stems {
    replace `s'_q = `s'_q * (cpi_base / cpi_exp) ///
        if !missing(`s'_q) & !missing(cpi_exp)
}
drop cpi_exp

* Deflate income variables
gen double cpi_inc = 0
forvalues k = 1/12 {
    gen int ym = (qintrvyr - cond(qintrvmo - `k' < 1, 1, 0)) * 12  ///
              + (qintrvmo - `k' + cond(qintrvmo - `k' < 1, 12, 0)) ///
              if iv_no == 5
    merge m:1 ym using `cpi', keep(master match) keepusing(cpi_u) nogen
    replace cpi_inc = cpi_inc + cpi_u / 12 ///
        if iv_no == 5 & !missing(cpi_u)
    drop ym cpi_u
}
replace cpi_inc = . if iv_no != 5

foreach v in fsalarym fnonfrmm ffrmincm fssixm unemplxm compensm welfarem ///
             foodsmpm chdothxm aliothxm tottxpdm {
    replace `v' = `v' * (cpi_base / cpi_inc) ///
        if iv_no == 5 & !missing(`v') & !missing(cpi_inc)
}
drop cpi_inc

* Deflate RENTEQVX
gen int ym = qintrvyr * 12 + qintrvmo if iv_no == 5
merge m:1 ym using `cpi', keep(master match) keepusing(cpi_u) nogen
rename cpi_u cpi_rent

capture confirm string variable renteqvx
if !_rc destring renteqvx, replace force
replace renteqvx = renteqvx * (cpi_base / cpi_rent) ///
    if iv_no == 5 & !missing(renteqvx) & !missing(cpi_rent)
drop ym cpi_rent

*-------------------------------------------------------------------------------
* 5. Aggregate to one row per CU
*    For each cuid we need:
*      - sum of the 3-month expenditures across the 4 interviews
*        (-> true 12-month annual totals, named <stem>_ann)
*      - count of interviews (we keep CUs with all 4)
*      - whether any reference period touches calendar 2010
*      - 5th-interview values: weight, income, taxes, transfers, tenure,
*        rental equivalence, age
*-------------------------------------------------------------------------------

* Build the list of expenditure variables to sum
local sumvars
foreach s of local stems {
    local sumvars `sumvars' `s'_q
}

tempfile cu_exp cu_5th

* merge MS vehicle service flow at the interview level (on newid)
merge 1:1 newid using "$data2010/ms_vflow_2010.dta", ///
      keep(master match) keepusing(n_tot_vflow1)
tab _merge
replace n_tot_vflow1 = 0 if missing(n_tot_vflow1)
drop _merge

* deflate the vehicle flow to constant 2010 dollars
gen int ym = qintrvyr*12 + qintrvmo
merge m:1 ym using `cpi', keep(master match) keepusing(cpi_u) nogen
replace n_tot_vflow1 = n_tot_vflow1 * (cpi_base / cpi_u) if !missing(cpi_u)
drop ym cpi_u

* (a) Sum quarterly expenditures across interviews
preserve
    collapse                                                  ///
        (sum)  `sumvars'                                      ///
		(sum)  vehicle_flow = n_tot_vflow1                    ///
        (sum)  n_months_in_2010 = touches_2010                ///
        (count) n_interviews = iv_no                          ///
        , by(cuid)
    gen byte cu_touches_2010 = (n_months_in_2010 > 0)
    save "`cu_exp'", replace
restore

* (b) 5th-interview values (one row per CU that completed the 5th interview).
* Indeed, income variables are collected in the 5th-interview 
*         and refer to the past 12 months.
preserve
    keep if iv_no == 5
    keep cuid newid finlwt21 fsalarym fnonfrmm ffrmincm           ///
              fssixm unemplxm compensm welfarem foodsmpm          ///
              chdothxm aliothxm tottxpdm                          ///
              cutenure renteqvx age_ref                           ///
              fam_size perslt18  
    save "`cu_5th'", replace
restore

* Combine: one row per CU
use "`cu_exp'", clear
merge 1:1 cuid using "`cu_5th'"
keep if _merge == 3
drop _merge

* Rename the summed _q variables to _ann (they are now 12-month totals)
foreach s of local stems {
    rename `s'_q `s'_ann
}


*-------------------------------------------------------------------------------
* 6. Apply sample restrictions
*-------------------------------------------------------------------------------

* (a) All 4 expenditure interviews completed
keep if n_interviews == 4

* (b) At least one reference month in calendar 2010
keep if cu_touches_2010 == 1
* The only CUs left to drop are those whose 5th interview is in January 2010 
* (or alternatively, those who were interviewed the first time in April 2009)

* (c) Reference-person age 25-60
destring age_ref, replace force
keep if inrange(age_ref, 25, 60)


*-------------------------------------------------------------------------------
* 7. Build the calendar-year 2010 population weight
*    ????
*-------------------------------------------------------------------------------

gen double annual_wgt = finlwt21 * 1

* check
total annual_wgt

*-------------------------------------------------------------------------------
* 8. Impute rent for owners
*    Tenure indicator (tenure_end: 1 = owner, 2 = renter).
*    2010 FMLY contains RENTEQVX (monthly rental equivalence, self-reported).
*    Annualise: x 12. 
*-------------------------------------------------------------------------------

destring cutenure, replace
gen byte tenure_end = .
replace  tenure_end = 1 if inlist(cutenure, 1, 2, 3)   // owner
replace  tenure_end = 2 if cutenure == 4               // renter
label define ten_lab 1 "Owner" 2 "Renter"
label values tenure_end ten_lab

gen double imputed_rent = renteqvx * 12 if tenure_end == 1
replace    imputed_rent = 0             if tenure_end == 2
label var  imputed_rent "Imputed annual rent for owners (RENTEQVX x 12)"

* Distribution diagnostic
tabstat rntxrp_ann   if tenure_end == 2 & rntxrp_ann > 0,   stat(mean median sd min p10 p25 p75 p90 max)
tabstat imputed_rent if tenure_end == 1 & imputed_rent > 0, stat(mean median sd min p10 p25 p75 p90 max)

* to be improved! 67 obs dropped
drop if tenure_end == 1 & missing(imputed_rent)
drop if missing(tenure_end)


*-------------------------------------------------------------------------------
* 9. CLM CLASSIFICATION (Comin-Lashkari-Mestieri, ECMA 2021)
* Built on Aguiar-Bils (2015) intermediate categories. 
* The AB SAS file groups CEX summary variables into 22 categories 
* (lines 408-439 and 754-762); 
* CLM then collapses these into (agric / manuf / serv)
*-------------------------------------------------------------------------------

* VEHPCH = cartkn + cartku + othveh + vehfin + vrntlo + vehin
* MS substitution: the service flow REPLACES new + used vehicle purchases
* (cartkn, cartku), other vehicles (othveh = caro), and vehicle finance charges
* (vehfin). We keep only vehicle rental (vrntlo) and vehicle insurance (vehins).
gen double vehpch_ab   = vehicle_flow + vrntlo_ann + vehins_ann
gen double vehopr_ab   = gasmo_ann + mainrp_ann
gen double oppub_ab    = vehopr_ab + pubtra_ann
gen double adultcl_ab  = mensix_ann + womsix_ann
gen double shoesoth_ab = footwr_ann + othapl_ann
gen double furnsh_ab   = textil_ann + furntr_ann + flrcvr_ann
gen double equpmt_ab   = majapp_ann + smlapp_ann + misceq_ann + teleph_ann
gen double chldrn_ab   = boyfif_ann + grlfif_ann + chldrn_ann

gen double util_ab     = ntlgas_ann + elctrc_ann + fuloil_ann   ///
                       + othfls_ann + watrps_ann
gen double shelt_ab    = rendwe_ann + othlod_ann + imputed_rent
gen double health_ab   = hlthin_ann + medsrv_ann + predrg_ann + medsup_ann
gen double tvrdot_ab   = tvrdio_ann + pettoy_ann + othent_ann
gen double feeard_ab   = feeadm_ann + read_ann
gen double housop_ab   = dmsxcc_ann + bbyday_ann
                       // NB: OTHHEX is dropped by AB, why?

* CLM macro categories
gen double agric_clm = fdhome_ann + alcbev_ann + 1

gen double manuf_clm = vehpch_ab + oppub_ab + adultcl_ab   ///
                     + shoesoth_ab + furnsh_ab + equpmt_ab + chldrn_ab  ///
                     + persca_ann + tobacc_ann + 1

gen double serv_clm  = shelt_ab + util_ab + health_ab + fdaway_ann      ///
                     + tvrdot_ab + feeard_ab + housop_ab + educa_ann    ///
                     + cashco_ann + 1
					 // CLM uses +1

gen double totexp_clm = agric_clm + manuf_clm + serv_clm

gen double share_agric_clm = agric_clm / totexp_clm
gen double share_manuf_clm = manuf_clm / totexp_clm
gen double share_serv_clm  = serv_clm  / totexp_clm

label var agric_clm        "CLM: agriculture"
label var manuf_clm        "CLM: manufactured goods"
label var serv_clm         "CLM: services"
label var totexp_clm       "CLM: total expenditure (sum of three buckets)"
label var share_agric_clm  "Share of food at home in total expenditure (CLM)"
label var share_manuf_clm  "Share of manufactured goods in total expenditure (CLM)"
label var share_serv_clm   "Share of services in total expenditure (CLM)"

* Sanity check
sum agric_clm manuf_clm serv_clm totexp_clm
sum share_agric_clm share_manuf_clm share_serv_clm

*-------------------------------------------------------------------------------
* 10. INCOME: 
*    Pre-tax-and-transfer earned income = wages/salary + non-farm self-employment + farm income
*
*    Variables (using the imputed "M" versions, which BLS imputes for missing
*    answers and which match the construction of fincbtxm):
*      FSALARYM = wage and salary income
*      FNONFRMM = non-farm self-employment / business / professional practice
*      FFRMINCM = farm income
*
*    We exclude rental, interest, dividends, transfers
*      INTEARNM  Interest on savings accounts or bonds 
*      FININCXM  Dividends, royalties, estates, or trusts
*      INCLOSAM  Net income or loss was received from roomers or boarders
*      INCLOSBM  Net income or loss was received from payments from other rental units
*      OTHRINCM  Cash scholarships and fellowships, ...
*
*    Post-tax-and-transfer income:
*     Transfers — we exclude:
*      FRRETIRM  Social Security  and Railroad Retirement
*      PENSIONM  Pensions  
*
*    Components included (all are BLS multiply-imputed "M" variables):
*      FSSIXM    Supplemental Security Income
*      UNEMPLXM  Unemployment compensation
*      COMPENSM  Workers' compensation + veterans' benefits
*      WELFAREM  Public assistance / welfare
*      FOODSMPM  Food stamps / EBT
*      CHDOTHXM  Child support received
*      ALIOTHXM  Alimony received
*
*    Taxes: TOTTXPDM (BLS-built net total = federal+state withheld and paid
*    + property + miscellaneous taxes, minus refunds).
*-------------------------------------------------------------------------------

gen double inc_pre = fsalarym + fnonfrmm + ffrmincm
label var  inc_pre "Pre-tax-and-transfer income"

* Replace missings with zero in the transfer components
foreach v in fssixm unemplxm compensm welfarem foodsmpm chdothxm aliothxm {
    replace `v' = 0 if missing(`v')
}

* Total non-OASI transfers
gen double transfers_nonOASI = fssixm + unemplxm + compensm + welfarem ///
                             + foodsmpm + chdothxm + aliothxm
label var transfers_nonOASI "Total transfers excl. Social Security/Railroad"


gen double inc_post_tax_tr = inc_pre + transfers_nonOASI - tottxpdm
label var inc_post_tax_tr    "Post-tax-and-transfer income"

*-------------------------------------------------------------------------------
* 11. $5,000 threshold in 2016 dollars
*    Threshold in 2010 dollars: $4542.49
*-------------------------------------------------------------------------------

gen byte below_thr = (inc_pre < 4542.49)
label var below_thr "1 = earned income < \$5000 in 2016 dollars"

* Mass of CUs below threshold (weighted), then drop them
di as txt _newline "*** Share of U.S. consumer units below the income threshold ***"
sum below_thr [aw=annual_wgt]
di as txt "Weighted share of CUs below threshold: " %5.3f r(mean)

di as txt _newline "Unweighted count and share:"
count if below_thr == 1
count

_pctile inc_pre [pw=annual_wgt], p(50)

scalar med_inc_2010 = r(r1)
scalar ratio_2010 = 4542.49 / med_inc_2010
di "Threshold/median, ratio weighted = " ratio_2010

drop if below_thr == 1
di as txt _newline "After dropping, remaining sample:"
count

_pctile inc_pre [pw=annual_wgt], p(50)

scalar med_inc_2010 = r(r1)
scalar ratio_2010 = 4542.49 / med_inc_2010
di "Threshold/median, ratio weighted = " ratio_2010

* at the moment, we use the weighted threshold
* note: since for 2010 we constructed the sample following different criteria 
*       compared to BLS, weights are not perfect as before


*-------------------------------------------------------------------------------
* 12. Equivalized expenditure (OECD Oxford scale) and expenditure measures:
*      1.0 first adult, 0.7 each further person 14+, 0.5 each child under 14.
*    NB: the dataset only has an under-18 count (PERSLT18),
*       so we use under-18 as the child threshold (no under-14 available); 
*-------------------------------------------------------------------------------

* household composition (under-18 used as the child count)
capture confirm string variable fam_size
if !_rc destring fam_size, replace force
capture confirm string variable perslt18
if !_rc destring perslt18, replace force

gen double n_child = perslt18
gen double n_adult = fam_size - perslt18
replace    n_adult = 0 if n_adult < 0
label var  n_child "Children (persons under 18)"
label var  n_adult "Adults (fam_size - persons under 18)"

gen double eqsc_oecd = 1 + 0.7*max(n_adult-1,0) + 0.5*n_child
replace    eqsc_oecd = 1 if eqsc_oecd < 1
label var  eqsc_oecd "OECD equivalence factor (1/0.7/0.5; child = under 18)"
* to get modified OECD change the factors to 0.5 and 0.3.

* expenditure measures (CLM total)
gen double exp_raw  = totexp_clm
gen double exp_oecd = totexp_clm / eqsc_oecd
label var  exp_raw  "Raw CLM total expenditure ($)"
label var  exp_oecd "Equivalized CLM expenditure, OECD ($)"


*-------------------------------------------------------------------------------
* 13. Log-expenditure moments
*-------------------------------------------------------------------------------

gen double log_exp_raw = log(exp_raw) if exp_raw > 0
sum log_exp_raw [aw=annual_wgt], detail

preserve
    clear
    set obs 1
    gen mean_log_exp = r(mean)
    gen var_log_exp  = r(Var)
    gen sd_log_exp   = r(sd)
    gen p10_log_exp  = r(p10)
    gen p25_log_exp  = r(p25)
    gen p50_log_exp  = r(p50)
    gen p75_log_exp  = r(p75)
    gen p90_log_exp  = r(p90)
    save "$oldoutput/2010_moments_log_exp_raw.dta", replace
restore

gen double log_exp_oecd = log(exp_oecd) if exp_oecd > 0
sum log_exp_oecd [aw=annual_wgt], detail

preserve
    clear
    set obs 1
    gen mean_log_exp = r(mean)
    gen var_log_exp  = r(Var)
    gen sd_log_exp   = r(sd)
    gen p10_log_exp  = r(p10)
    gen p25_log_exp  = r(p25)
    gen p50_log_exp  = r(p50)
    gen p75_log_exp  = r(p75)
    gen p90_log_exp  = r(p90)
    save "$oldoutput/2010_moments_log_exp_OECD.dta", replace
restore

*-------------------------------------------------------------------------------
* 14. Expenditure/Income deciles and quintiles
*-------------------------------------------------------------------------------

xtile exp_quin_raw  = exp_raw  [aw=annual_wgt], nq(5)
xtile exp_quin_oecd = exp_oecd [aw=annual_wgt], nq(5)
label var exp_quin_raw  "Raw expenditure quintile (1=bottom)"
label var exp_quin_oecd "OECD-equivalized expenditure quintile (1=bottom)"

* CLM quintiles
capture program drop _save_clm_shares
program define _save_clm_shares
    args byvar outfile
    preserve
        collapse                                                    ///
            (mean) mean_share_food_clm=share_agric_clm             ///
                   mean_share_goods_clm=share_manuf_clm             ///
                   mean_share_serv_clm=share_serv_clm               ///
            (sum)  sum_food_clm=agric_clm                       ///
                   sum_goods_clm=manuf_clm                    ///
                   sum_serv_clm=serv_clm                        ///
                   sum_total_clm=totexp_clm                        ///
            [aw=annual_wgt], by(`byvar')
        gen double agg_share_food_clm  = sum_food_clm  / sum_total_clm
        gen double agg_share_goods_clm = sum_goods_clm / sum_total_clm
        gen double agg_share_serv_clm  = sum_serv_clm  / sum_total_clm
        keep `byvar' mean_share_food_clm mean_share_goods_clm mean_share_serv_clm ///
                     agg_share_food_clm agg_share_goods_clm agg_share_serv
        order `byvar' mean_share_food_clm mean_share_goods_clm mean_share_serv_clm ///
                      agg_share_food_clm agg_share_goods_clm agg_share_serv_clm
        save "`outfile'", replace
        list, noobs clean
    restore
end

_save_clm_shares exp_quin_oecd "$oldoutput/2010_CLM_by_exp_quin_OECD.dta"
_save_clm_shares exp_quin_raw  "$oldoutput/2010_CLM_by_exp_quin_raw.dta"


* total expenditure share by expenditure quintile/decile
preserve
    collapse (sum) exp_raw [aw=annual_wgt], by(exp_quin_raw)
    egen total_exp = total(exp_raw)
    gen exp_share = exp_raw / total_exp
    list exp_quin_raw exp_share, noobs clean
    save "$oldoutput/2010_expshare_quin_raw.dta", replace
restore

preserve
    collapse (sum) exp_oecd [aw=annual_wgt], by(exp_quin_oecd)
    egen total_exp = total(exp_oecd)
    gen exp_share = exp_oecd / total_exp
    list exp_quin_oecd exp_share, noobs clean
    save "$oldoutput/2010_expshare_quin_OECD.dta", replace
restore

*-------------------------------------------------------------------------------
* 15. Income shares by income quintile
*-------------------------------------------------------------------------------

xtile inc_pre_quin  = inc_pre         [aw=annual_wgt], nquantiles(5)
xtile inc_post_quin = inc_post_tax_tr [aw=annual_wgt], nquantiles(5)
label var inc_pre_quin  "Pre-tax-and-transfer income quintile (1=bottom)"
label var inc_post_quin "Post-tax-and-transfer income quintile (1=bottom)"
capture program drop _save_inc_shares
program define _save_inc_shares
    args incvar byvar outfile
    preserve
        collapse (sum) inc=`incvar' [aw=annual_wgt], by(`byvar')
        egen total_inc = total(inc)
        gen inc_share = inc / total_inc
        keep `byvar' inc inc_share
        save "`outfile'", replace
        list, noobs clean
    restore
end

_save_inc_shares inc_pre         inc_pre_quin      "$oldoutput/2010_incshare_pre_quin.dta"
_save_inc_shares inc_post_tax_tr      inc_post_quin  "$oldoutput/2010_incshare_post_quin.dta"

*-------------------------------------------------------------------------------

order cuid newid finlwt21 annual_wgt age_ref tenure_end ///
      inc_pre inc_post_tax_tr exp_raw exp_oecd

compress
save "$data2010/fmly_2010.dta", replace




