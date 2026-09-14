********************************************************************************************************
/* CEX 2010 - CLEAN VERSION

   Sample: quarterly interviews as the unit of observation (variant C). Every
   quarterly interview is its own observation - no collapse by CU. Quarterly
   consumption is used as-is (the inequality statistics are scale-invariant).

   Expenditure: OECD-equivalized, CU weight (FINLWT21).

   Two measures of log expenditure:
     - clm     : AB/CLM categorization + MS vehicle flow + imputed rent
     - cex_tot : the CEX total expenditure variable (TOTEXP), with vehicle
                 purchases replaced by the MS service flow and owner-occupied
                 housing outlays replaced by imputed rent. No other exclusions,
                 so this is larger in levels than the CLM measure.

   Survey year 2010: the four 2010 quarterly files. No deflation.*/
*******************************************************************************************************

clear all
set more off
do "../globalpaths.do"
capture mkdir "$cleanoutput"

* modify this if more years are needed
local yr    2010                                 // tags the output files
local qfiles fmli101x fmli102 fmli103 fmli104   // add other years' quarters here
local srvyears 110                              //  MS srv_year (109=2009, 110=2010, ...)

scalar cutoff_2010 = 5000        // income cut, 2010 dollars

*-------------------------------------------------------------------------------
* PROGRAMS
*-------------------------------------------------------------------------------

* CLM tot exp + CEX tot exp
capture program drop build_totexp
program define build_totexp
    gen double vehpch_ab   = vehicle_flow + vrntlo + vehins
    gen double vehopr_ab   = gasmo + mainrp
    gen double oppub_ab    = vehopr_ab + pubtra
    gen double adultcl_ab  = mensix + womsix
    gen double shoesoth_ab = footwr + othapl
    * furnsh/equpmt/housop carry AB's OTHHEX reallocations (SAS L754-756)
    gen double furnsh_ab   = textil + furntr + flrcvr + furns2
    gen double equpmt_ab   = majapp + smlapp + misceq + teleph + equpm2
    gen double chldrn_ab   = boyfif + grlfif + chldrn
    gen double util_ab     = ntlgas + elctrc + fuloil + othfls + watrps
    gen double shelt_ab    = rendwe + othlod + imputed_rent_q
    gen double health_ab   = hlthin + medsrv + predrg + medsup
    gen double tvrdot_ab   = tvrdio + pettoy + othent
    gen double feeard_ab   = feeadm + read
    gen double housop_ab   = dmsxcc + dmsxc2 + bbyday

    gen double agric_clm = fdhome + alcbev //+ 1
    gen double manuf_clm = vehpch_ab + oppub_ab + adultcl_ab + shoesoth_ab ///
                         + furnsh_ab + equpmt_ab + chldrn_ab + persca + tobacc //+ 1
    gen double serv_clm  = shelt_ab + util_ab + health_ab + fdaway + tvrdot_ab ///
                           + feeard_ab + housop_ab + educa + cashco_adj //+ 1
    gen double totexp_clm = agric_clm + manuf_clm + serv_clm
	* CLM-total zero-expenditure screen (replaces the +1 guards).
    * NB Stata treats missing as +inf, so `<= 0` alone would KEEP a missing total
    * (any missing component -> missing total -> missing shares).
    count if missing(totexp_clm)
    di as txt "CLM total missing (some component missing): " r(N)
    drop if totexp_clm <= 0 | missing(totexp_clm)

    * CEX total, only the two substitutions
    gen double totexp_cex = totexp - cartkn - cartku - othveh - vehfin - owndwe ///
                          + vehicle_flow + imputed_rent_q
						  
	* totexp_cex net of cash contributions, personal insurance, or both
	gen double totexp_nogifts = totexp_cex - cashco
	gen double totexp_noins   = totexp_cex - perins
	gen double totexp_noboth  = totexp_cex - cashco - perins
	
end

* equiv scale + weight
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

    gen double exp_clm_oecd     = totexp_clm / eqsc_oecd
    gen double exp_cex_oecd = totexp_cex / eqsc_oecd
	gen double exp_nogifts_oecd = totexp_nogifts / eqsc_oecd
    gen double exp_noins_oecd   = totexp_noins   / eqsc_oecd
    gen double exp_noboth_oecd  = totexp_noboth  / eqsc_oecd
    gen double weight_u     = finlwt21          // (U) CU weight
end

* sample restrictions + ratio
capture program drop restrict_sample
program define restrict_sample
    args yr
    gen double inc_pre = fsalarym + fnonfrmm + ffrmincm

    destring age_ref, replace force
    keep if inrange(age_ref, 25, 60)

    * ratio
    _pctile inc_pre [pw=weight_u], p(50)
    scalar med_c = r(r1)
    scalar rfg_c = cutoff_2010 / med_c
	* export the cutoff/median ratio for 1960_clean.do (run 2010 before 1960)
    file open ratiofile using "$cleanoutput/ratio_2010.do", write replace
    file write ratiofile "scalar ratio_2010 = " %12.0g (rfg_c) _n
    file close ratiofile
    di as txt "`yr' - median inc (wtd): " %10.1f med_c ///
              " ratio (cutoff/median): " %6.4f rfg_c

    * unweighted % of units dropped by the income cut
    quietly count
    local n0 = r(N)
    * NB Stata treats missing as +inf, so `< cutoff` alone would KEEP a missing
    * inc_pre (any missing income component -> missing inc_pre).
    count if missing(inc_pre)
    di as txt "`yr' - inc_pre missing (some income component missing): " r(N)
    drop if inc_pre < cutoff_2010 | missing(inc_pre)
    quietly count
    di as txt "`yr' - income cut: dropped " %5.2f 100*(1-r(N)/`n0') "%"
end

* log-expenditure moments
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

* sectoral share moments: aggregate (grp 0) and by quintile
capture program drop post_shares
program define post_shares
    gen double sh_food = agric_clm / totexp_clm
    gen double sh_good = manuf_clm / totexp_clm
    gen double sh_serv = serv_clm  / totexp_clm

    xtile qexp = exp_clm_oecd [aw=weight_u], nq(5)

    foreach grp in 0 1 2 3 4 5 {
        foreach sec in food good serv {
            if "`sec'"=="food" local catv agric_clm
            if "`sec'"=="good" local catv manuf_clm
            if "`sec'"=="serv" local catv serv_clm

            local ifq
            if `grp'>0 local ifq if qexp==`grp'

            quietly sum sh_`sec' [aw=weight_u] `ifq', detail
            local m = r(mean)
            local v = r(Var)
            local n = r(N)
            quietly sum `catv'     [aw=weight_u] `ifq'
            local mc = r(mean)
            quietly sum totexp_clm [aw=weight_u] `ifq'
            local mt = r(mean)
            post shares ("`sec'") (`grp') (`mc'/`mt') (`m') (`v') (`n')
        }
    }
    drop sh_food sh_good sh_serv qexp
end

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

*-------------------------------------------------------------------------------
* BUILD
*-------------------------------------------------------------------------------
* MS vehicle service flow
* you need to put all_cons_data_for_stata_80_17.dta in the datafolder
* since it's too heavy to have on github
tempfile msflow
use "$data/all_cons_data_for_stata_80_17.dta", clear
keep if inlist(srv_year, `srvyears')
keep newid n_tot_vflow1
capture confirm string variable newid
if !_rc destring newid, replace
isid newid          // newid uniquely identifies MS 2010 rows (was: duplicates drop ... force)
save "`msflow'", replace

* append quarters
local first : word 1 of `qfiles'
use "$data2010/`first'.dta", clear
foreach f of local qfiles {
    if "`f'"!="`first'" append using "$data2010/`f'.dta"
}

foreach s of local stems {
    gen double `s'_q = `s'pq + `s'cq
}

* merge MS vehicle service flow at the interview level (on newid)
merge 1:1 newid using "`msflow'", ///
      keep(master match) keepusing(n_tot_vflow1)
tab _merge
* Merge is 1:1 on newid and currently matches 100% (see tab _merge above), so
* nothing should be missing. Assert rather than zero-fill: an unmatched CU would
* otherwise get vehicle_flow = 0, understating vehpch_ab / manuf_clm / totexp_clm
* and quietly moving it into the left tail. Mirrors 1960's assert.
assert !missing(n_tot_vflow1)
drop _merge

* quarterly imputed rent (renteqvx per interview x 3 months)
destring cutenure renteqvx, replace force
tab cutenure, missing        // which codes exist; 5/6 etc. become missing tenure_end below
gen byte tenure_end = .
replace  tenure_end = 1 if inlist(cutenure,1,2,3)    // owner
replace  tenure_end = 2 if cutenure == 4             // renter
gen double imputed_rent_q = renteqvx*3 if tenure_end == 1
replace    imputed_rent_q = 0          if tenure_end == 2

foreach v in fsalarym fnonfrmm ffrmincm tottxpdm welfarem foodsmpm {
    capture confirm string variable `v'
    if !_rc destring `v', replace force
}

* if you need more transfers, add them here; they contain missing values
foreach v in welfarem foodsmpm {
    replace `v' = 0 if missing(`v')
}

gen double vehicle_flow = n_tot_vflow1
foreach s of local stems {
    rename `s'_q `s'
}

* Raw-field integrity: negatives across all stems, before anything is
* constructed from them. Prints only fields that have negative values.
foreach v in `stems' vehicle_flow imputed_rent_q {
  quietly count if `v' < 0
  if r(N) > 0 {
	  local nneg = r(N)
	  quietly sum `v'
	  di as txt "`v': " `nneg' " negative, min " %12.2f r(min)
  }
}

* Negative domestic services has no interpretation: the codebook flags medical
* UCCs as "net outlay" (negative when reimbursed), but the DMSXCC UCCs carry no
* such flag. Mirrors the 1960 negative-food drop. These records also account for
* the negative hous and totexp values.
count if dmsxcc < 0
di as txt "2010 - negative dmsxcc, dropped: " r(N)
drop if dmsxcc < 0

* verification: what negatives remain after the drop
foreach v in `stems' vehicle_flow imputed_rent_q {
  quietly count if `v' < 0
  if r(N) > 0 {
	  local nneg = r(N)
	  quietly sum `v'
	  di as txt "`v': " `nneg' " negative, min " %12.2f r(min)
  }
}



*-------------------------------------------------------------------------------
* Cash contributions, CLM-consistent, built from MTBI detail
* --- edit cc_keep to switch definition -------------------------------------
* (b) organizations only  (matches 1960 gifts_orgs): charities/religious/educ/political
local cc_keep 800821 800831 800841 800851
* (a) match AB (all cash contributions except alimony/child/college):
*local cc_keep 800811 800821 800831 800841 800851 800861
* old
*local cc_keep 800111 800121 800804 800811 800821 800831 800841 800851 800861
*-------------------------------------------------------------------------------
tempfile ccflow
preserve
local mtbifiles mtbi101x mtbi102 mtbi103 mtbi104
local firstm : word 1 of `mtbifiles'
use "$data2010/`firstm'.dta", clear
foreach f of local mtbifiles {
	  if "`f'"!="`firstm'" append using "$data2010/`f'.dta"
}
* cash contributions (definition set by cc_keep above)
gen byte _keep = 0
foreach u of local cc_keep {
	  replace _keep = 1 if ucc == "`u'"
}
gen double c_cashco = cost if _keep

* AB detail-file reallocations of OTHHEX (SAS L754-756):
*   FURNSH = FURNSH + FURNS2 ; EQUPMT = EQUPMT + EQUPM2 ; DMSXCC = DMSXCC + DMSXC2
* NB the rest of OTHHEX (330511 pest-control materials, 340510 moving/storage)
* goes to AB's OWNDW2, which enters NO consumption category - not added here.
gen double c_furns2 = cost if ucc == "340630"
gen double c_dmsxc2 = cost if ucc == "340915"
gen double c_equpm2 = cost if inlist(ucc,"340620","340901","340907","340908", ///
										 "690113","690114","690116","690310","990900")

collapse (sum) cashco_adj=c_cashco furns2=c_furns2 equpm2=c_equpm2 dmsxc2=c_dmsxc2, ///
		 by(newid)
save "`ccflow'", replace
restore
merge 1:1 newid using "`ccflow'", keep(master match) ///
	keepusing(cashco_adj furns2 equpm2 dmsxc2)
foreach v in cashco_adj furns2 equpm2 dmsxc2 {
  replace `v' = 0 if missing(`v')
}
drop _merge
label var cashco_adj "Cash contributions, CLM-consistent (see cc_keep)"
label var furns2     "AB FURNS2: furniture repair (UCC 340630)"
label var equpm2     "AB EQUPM2: appliance/equipment repair+rental, computer services"
label var dmsxc2     "AB DMSXC2: home security service fees (UCC 340915)"
sum cashco_adj furns2 equpm2 dmsxc2


* These are collapsed from MTBI cost, so they bypassed the stem scan.
foreach v in cashco_adj furns2 equpm2 dmsxc2 {
  quietly count if `v' < 0
  if r(N) > 0 {
	  di as txt "2010 - negative `v': " r(N)
	  sum `v' if `v' < 0
  }
}

* what do the non-owner/non-renter CUs (cutenure 5 = rent-free, 6 = student
* housing) actually report for shelter, before they are dropped?
tabstat rendwe othlod totexp [aw=finlwt21] if cutenure == 5, ///
	  stat(n mean p50 min max) columns(statistics)
tabstat rendwe othlod totexp [aw=finlwt21] if cutenure == 6, ///
	  stat(n mean p50 min max) columns(statistics)
count if inlist(cutenure,5,6) & rendwe > 0


* keep_norent: 0 = drop CUs that are neither owner nor cash renter (cutenure 5 =
*   occupied without payment of cash rent, 6 = student housing);
*   1 = keep them with no owner imputation. renteqvx is asked of owners only
*   (verified: 0 owners missing it, 0 renters and 0 code-5/6 CUs have it), so no
*   imputation is available for them. Matches how 1960 implicitly treats its own
*   rent-free households - unidentifiable there, entering with rent_dwell = 0.
*   They keep whatever rendwe/othlod they do report.
local keep_norent 1

if `keep_norent' {
  replace tenure_end     = 3 if missing(tenure_end) & inlist(cutenure,5,6)
  replace imputed_rent_q = 0 if tenure_end == 3
  label define tenure_lbl 1 "owner" 2 "renter" 3 "no cash rent / student housing", replace
  label values tenure_end tenure_lbl
  tab tenure_end, missing
}

drop if tenure_end == 1 & missing(imputed_rent_q)
drop if missing(tenure_end)


* Completeness check on the variables actually used (reports only variables that
* HAVE missing values). Counterpart to the 1960 check after the infix.
* Expect renteqvx (missing by design for renters); the imputed income means
* fsalarym/fnonfrmm/ffrmincm are complete by construction (BLS multiple
* imputation since 2004: the M-suffix variable is the mean of five imputations).
misstable summarize `stems' fsalarym fnonfrmm ffrmincm tottxpdm welfarem foodsmpm ///
				  renteqvx cutenure vehicle_flow cashco_adj imputed_rent_q finlwt21


build_totexp
build_scales

* Negative sector aggregates -> shares outside [0,1]. Report before deciding.
count if agric_clm < 0
count if manuf_clm < 0
count if serv_clm  < 0
count if agric_clm/totexp_clm < 0 | agric_clm/totexp_clm > 1
count if manuf_clm/totexp_clm < 0 | manuf_clm/totexp_clm > 1
count if serv_clm/totexp_clm  < 0 | serv_clm/totexp_clm  > 1

* positivity screen
count if totexp_cex    <= 0
count if totexp_nogifts <= 0
count if totexp_noins   <= 0
count if totexp_noboth  <= 0

* A negative sector aggregate makes the share vector unusable (share < 0 with
* the others summing above 1), even though the underlying medical negatives are
* the documented net-outlay convention. Drop.
count if agric_clm < 0 | manuf_clm < 0 | serv_clm < 0
di as txt "2010 - negative sector aggregate, dropped: " r(N)
drop if agric_clm < 0 | manuf_clm < 0 | serv_clm < 0


restrict_sample "`yr'"

*post-tax-and-transfer income (tottxpdm is mostly positive)
gen double inc_post_tax_tr = inc_pre - tottxpdm + welfarem + foodsmpm

count if missing(inc_pre)
count if missing(tottxpdm)
count if missing(welfarem)
tab qintrvmo if missing(inc_pre)
count if welfarem == 0
sum welfarem, detail

gen double inc_pre_oecd    = inc_pre          / eqsc_oecd
gen double inc_post_oecd = inc_post_tax_tr  / eqsc_oecd

sum totexp_clm totexp_cex inc_pre inc_post_tax_tr [aw=weight_u]
count if missing(inc_post_tax_tr) 

*-------------------------------------------------------------------------------
* Tax function
*-------------------------------------------------------------------------------

gen log_inc_pre = log(inc_pre)

* Guard: post-tax-and-transfer income can be <= 0 (tottxpdm is assessed on TOTAL
* income incl. capital, while inc_pre = salary + nonfarm + farm business only).
* log() of those is missing, so reg would silently drop exactly the high-tax units.
gen byte taxreg_ok = (inc_post_tax_tr > 0 & !missing(inc_post_tax_tr))
count if taxreg_ok == 0
di as txt "Dropped from tax regression (post-tax-and-transfer income <= 0 or missing): " r(N) " of " _N
label var taxreg_ok "In tax-regression sample (inc_post_tax_tr > 0)"

gen log_inc_post_tax_tr = log(inc_post_tax_tr) if taxreg_ok

reg log_inc_post_tax_tr log_inc_pre if taxreg_ok [aw=weight_u]


*-------------------------------------------------------------------------------
* OUTPUT TABLES
*-------------------------------------------------------------------------------
capture postclose moments
postfile moments str10 measure ///
    double(mean var sd p10 p25 p50 p75 p90 nobs) ///
    using "$cleanoutput/log_moments_`yr'.dta", replace

capture postclose shares
postfile shares str4 sector byte quintile ///
    double(agg_share mean_share var_share) long nobs ///
    using "$cleanoutput/shares_moments_`yr'.dta", replace

post_moments exp_clm_oecd     weight_u clm_tot
post_moments exp_cex_oecd weight_u cex_tot
post_moments exp_nogifts_oecd weight_u no_gifts
post_moments exp_noins_oecd   weight_u no_ins
post_moments exp_noboth_oecd  weight_u no_both
post_moments inc_pre     weight_u inc_pre    
   
post_shares

postclose moments
postclose shares

preserve
    use "$cleanoutput/log_moments_`yr'.dta", clear
    list, noobs clean
restore
preserve
    use "$cleanoutput/shares_moments_`yr'.dta", clear
    list, noobs clean
restore
