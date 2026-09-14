********************************************************************************************************
/*We need variation in three dimensions, with 3 times 2 times 2 variants, ie 12 versions to check against Aguiar-Bils, Meyer-Sullivan, and Heathcote-Perri-Violante-Zhang.: 

 Dimension 1 — annualization / unit of observation (3 options)
 - (A) Complete + sum. Keep only CUs present in all four quarterly interviews. Sum the four quarters into one annual consumption figure → one observation per CU. Assign it to the calendar year of the fifth interview (that's the AB convention).
  - (B) Incomplete + average×4. Keep all CUs, including those with fewer than four interviews. For each CU, take the mean of its available quarterly consumption and multiply by 4 → one annualized observation per CU. Assign it to the year of the last  interview. (Note: for a CU with all four quarters this equals option A; A and B differ only in whether partial CUs are kept and scaled up.)
  - (C) Quarters. Keep every quarterly interview as its own observation — do not collapse by CU. A CU with fewer quarters just contributes fewer observations. Use the quarterly consumption value as-is (no ×4 needed; the inequality statistics are scale-invariant). Assign each observation to its survey year (that's HPVZ; MS shift to match the time period when the consumption actually happened, we don't care about that)

  Dimension 2 — equivalization (2 options)
  - (E) Equivalized. Divide each observation's consumption by the OECD equivalence scale
  - (N) Not equivalized. Use raw CU consumption.

  Dimension 3 — weight (2 options)
  - (P) Person weight. weight = FINLWT21 × family_size.
  - (U) CU weight. weight = FINLWT21.
  - Application: for the collapsed variants (A, B) use the CU's FINLWT21 from the last available interview (× family size for the P-version). For the quarterly variant (C) use each quarter's own FINLWT21 (× that quarter's family size for P).*/
*******************************************************************************************************

*-------------------------------------------------------------------------------
* MAIN SETUP FOR ALL CHECKS
*-------------------------------------------------------------------------------

clear all
set more off

do "../globalpaths.do"

use "$data2010/fmli101x.dta", clear
gen long file_yq = 20101

append using "$data2010/fmli102.dta"
replace file_yq = 20102 if missing(file_yq)

append using "$data2010/fmli103.dta"
replace file_yq = 20103 if missing(file_yq)

append using "$data2010/fmli104.dta"
replace file_yq = 20104 if missing(file_yq)

append using "$data2010/fmli111x.dta"
replace file_yq = 20111 if missing(file_yq)

destring qintrvmo qintrvyr, replace

local stems ///
    totexp totex4 food fdhome fdaway alcbev ///
    hous shelt rendwe rntxrp othlod util ///
    elctrc ntlgas fuloil othfls teleph watrps ///
    housop domsrv dmsxcc bbyday ///
    houseq furntr majapp smlapp textil flrcvr misceq ///
    appar mensix womsix boyfif grlfif chldrn footwr othapl ///
    trans cartkn cartku othveh gasmo vehfin mainrp vehins vrntlo pubtra ///
    health hlthin medsrv predrg medsup ///
    entert feeadm tvrdio otheqp pettoy othent ///
    persca read educa tobacc ///
    owndwe mrtint proptx mrpins cashco perins miscx4

foreach s of local stems {
    gen double `s'_q = `s'pq + `s'cq
}

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

* merge MS vehicle service flow at the interview level (on newid)
merge 1:1 newid using "$data2010/ms_vflow_09_12.dta", ///
      keep(master match) keepusing(n_tot_vflow1)
tab _merge
replace n_tot_vflow1 = 0 if missing(n_tot_vflow1)
drop _merge

destring cutenure renteqvx, replace force
gen byte tenure_end = .
replace  tenure_end = 1 if inlist(cutenure,1,2,3)    // owner
replace  tenure_end = 2 if cutenure == 4             // renter
gen double imputed_rent_q = renteqvx*3 if tenure_end == 1   // quarterly (3 months)
replace    imputed_rent_q = 0          if tenure_end == 2

tempfile base
save "`base'", replace

*-------------------------------------------------------------------------------
* PROGRAMS
*-------------------------------------------------------------------------------

* CLM tot exp
capture program drop build_totexp
program define build_totexp
    gen double vehpch_ab   = vehicle_flow + vrntlo + vehins
    gen double vehopr_ab   = gasmo + mainrp
    gen double oppub_ab    = vehopr_ab + pubtra
    gen double adultcl_ab  = mensix + womsix
    gen double shoesoth_ab = footwr + othapl
    gen double furnsh_ab   = textil + furntr + flrcvr
    gen double equpmt_ab   = majapp + smlapp + misceq + teleph
    gen double chldrn_ab   = boyfif + grlfif + chldrn
    gen double util_ab     = ntlgas + elctrc + fuloil + othfls + watrps
    gen double shelt_ab    = rendwe + othlod + imputed_rent_q
    gen double health_ab   = hlthin + medsrv + predrg + medsup
    gen double tvrdot_ab   = tvrdio + pettoy + othent
    gen double feeard_ab   = feeadm + read
    gen double housop_ab   = dmsxcc + bbyday

    gen double agric_clm = fdhome + alcbev + 1
    gen double manuf_clm = vehpch_ab + oppub_ab + adultcl_ab + shoesoth_ab ///
                         + furnsh_ab + equpmt_ab + chldrn_ab + persca + tobacc + 1
    gen double serv_clm  = shelt_ab + util_ab + health_ab + fdaway + tvrdot_ab ///
                         + feeard_ab + housop_ab + educa + cashco + 1
    gen double totexp_clm = agric_clm + manuf_clm + serv_clm
end


* equiv scale
capture program drop build_scales
program define build_scales
    capture confirm string variable fam_size
    if !_rc destring fam_size, replace force
    capture confirm string variable perslt18
    if !_rc destring perslt18, replace force

    gen double n_child = perslt18
    gen double n_adult = max(fam_size - perslt18, 0)
    gen double eqsc_oecd = 1 + 0.7*max(n_adult-1,0) + 0.5*n_child   // Oxford; child<18
    replace    eqsc_oecd = 1 if eqsc_oecd < 1

    gen double exp_raw  = totexp_clm
    gen double exp_oecd = totexp_clm / eqsc_oecd

    gen double weight_p = finlwt21 * fam_size   // (P) person weight
    gen double weight_u = finlwt21              // (U) CU weight
end

* moments of tot expenditure for all cases
capture program drop post_moments
program define post_moments
    args expvar wvar tag
    tempvar le
    quietly gen double `le' = log(`expvar') if `expvar' > 0
    quietly sum `le' [aw=`wvar'], detail
    post moments ("`tag'") (r(mean)) (r(Var)) (r(sd)) ///
                 (r(p10)) (r(p25)) (r(p50)) (r(p75)) (r(p90)) (r(N))
    drop `le'
end

*-------------------------------------------------------------------------------
* OPEN THE SHARED OUTPUT TABLES
*-------------------------------------------------------------------------------
capture postclose moments
postfile moments str12 tag ///
    double(mean var sd p10 p25 p50 p75 p90 nobs) ///
    using "$check/moments_all_2010.dta", replace

*-------------------------------------------------------------------------------
* DIMENSION 1: (A)
*-------------------------------------------------------------------------------
use "`base'", clear


 * Build the list of expenditure variables to sum
local sumvars
foreach s of local stems {
    local sumvars `sumvars' `s'_q
}

tempfile cu_exp cu_5th

* (a) Sum quarterly expenditures across interviews
preserve
    collapse                                                  ///
        (sum)  `sumvars'                                      ///
		(sum)  vehicle_flow = n_tot_vflow1                    ///
	    (sum)  imputed_rent_q                                 ///
        (max)  tenure_end                                     ///
        (count) n_interviews = iv_no                          ///
        , by(cuid)
    save "`cu_exp'", replace
restore


* (b) 5th-interview values (one row per CU that completed the 5th interview);
*            they refer to the past 12 months.
preserve
    keep if iv_no == 5
    keep cuid newid finlwt21 fsalarym fnonfrmm ffrmincm           ///
              fssixm unemplxm compensm welfarem foodsmpm          ///
              chdothxm aliothxm tottxpdm                          ///
              age_ref fam_size perslt18  
    save "`cu_5th'", replace
restore

* Combine: one row per CU
use "`cu_exp'", clear
merge 1:1 cuid using "`cu_5th'"
keep if _merge == 3
drop _merge

* Rename the summed _q variables to _ann (they are now 12-month totals)
foreach s of local stems {
    rename `s'_q `s'
}

****** need to improve max tenure_end ******
drop if tenure_end == 1 & missing(imputed_rent_q)
drop if missing(tenure_end)

build_totexp
build_scales

* Apply sample restrictions
* (a) All 4 expenditure interviews completed
keep if n_interviews == 4

* (b) income cut
gen double inc_pre = fsalarym + fnonfrmm + ffrmincm
label var  inc_pre "Pre-tax-and-transfer income"
gen byte below_thr = (inc_pre < 4542.49)
drop if below_thr == 1

* (c) Reference-person age 25-60
destring age_ref, replace force
keep if inrange(age_ref, 25, 60)

* Log-expenditure moments

post_moments exp_raw  weight_p a_raw_p
post_moments exp_raw  weight_u a_raw_u
post_moments exp_oecd weight_p a_oecd_p
post_moments exp_oecd weight_u a_oecd_u

*-------------------------------------------------------------------------------
* DIMENSION 1: (B)
*-------------------------------------------------------------------------------
use "`base'", clear

local sumvars
foreach s of local stems { 
	local sumvars `sumvars' `s'_q 
	}
* mean across available interviews, then x4
collapse (mean) `sumvars' (mean) vehicle_flow = n_tot_vflow1 ///
         (mean) imputed_rent_q (max) tenure_end    ///
         , by(cuid)
foreach s of local stems { 
	rename `s'_q `s' 
	}
foreach s of local stems { 
	replace `s' = `s'*4 
	}
replace vehicle_flow = vehicle_flow*4
replace imputed_rent_q = imputed_rent_q*4

preserve
    use "`base'", clear
    bysort cuid (iv_no): keep if _n == _N          // last interview per CU
    keep cuid finlwt21 fsalarym fnonfrmm ffrmincm  ///
         age_ref fam_size perslt18 qintrvyr iv_no
    tempfile last
    save "`last'", replace
restore
merge 1:1 cuid using "`last'", keep(match) nogen

****** need to improve max tenure_end ******
drop if tenure_end == 1 & missing(imputed_rent_q)
drop if missing(tenure_end)

build_totexp

gen double inc_pre = fsalarym + fnonfrmm + ffrmincm
drop if inc_pre < 4542.49         
destring age_ref, replace force
keep if inrange(age_ref, 25, 60)

build_scales
post_moments exp_raw  weight_p b_raw_p
post_moments exp_raw  weight_u b_raw_u
post_moments exp_oecd weight_p b_oecd_p
post_moments exp_oecd weight_u b_oecd_u


*-------------------------------------------------------------------------------
* DIMENSION 1: (C)
*-------------------------------------------------------------------------------

use "`base'", clear

gen double vehicle_flow = n_tot_vflow1           // per-interview quarterly flow
foreach s of local stems { 
	rename `s'_q `s' 
	}
	
drop if tenure_end == 1 & missing(imputed_rent_q)
drop if missing(tenure_end)

build_totexp

gen double inc_pre = fsalarym + fnonfrmm + ffrmincm
drop if inc_pre < 4542.49
destring age_ref, replace force
keep if inrange(age_ref, 25, 60)

build_scales
post_moments exp_raw  weight_p c_raw_p
post_moments exp_raw  weight_u c_raw_u
post_moments exp_oecd weight_p c_oecd_p
post_moments exp_oecd weight_u c_oecd_u


*-------------------------------------------------------------------------------
* CLOSE AND WRITE THE TABLES
*-------------------------------------------------------------------------------
postclose moments






