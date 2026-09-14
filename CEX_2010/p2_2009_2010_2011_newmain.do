********************************************************************************************************
/* We replicate our analysis for 2009, 2010 and 2011.

We have variation in how we construct the sample to benchmark against Aguiar-Bils, Meyer-Sullivan, and Heathcote-Perri-Violante-Zhang:

   Sample variants  — annualization / unit of observation (3 options)
    - (A) Complete + sum. Keep only CUs present in all four quarterly interviews. Sum the four quarters into one annual consumption figure → one observation per CU. Assign it to the calendar year of the fifth interview (that's the AB convention).
    - (B) Incomplete + average×4. Keep all CUs, including those with fewer than four interviews. For each CU, take the mean of its available quarterly consumption and multiply by 4 → one annualized observation per CU. Assign it to the year of the last  interview. (Note: for a CU with all four quarters this equals option A; A and B differ only in whether partial CUs are kept and scaled up.).
    - (C) Quarters. Keep every quarterly interview as its own observation — do not collapse by CU. A CU with fewer quarters just contributes fewer observations. Use the quarterly consumption value as-is (no ×4 needed; the inequality statistics are scale-invariant). Assign each observation to its survey year (that's HPVZ; MS shift to match the time period when the consumption actually happened, we don't care about that).

   We compute moments of log expenditure and sectoral share moments by quintile
   (AB/CLM categorization + MS vehicle flow), using OECD equivalization and CU weight 
   (FINLWT21). */
*******************************************************************************************************

clear all
set more off
do "../globalpaths.do"
capture mkdir "$newoutput"

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

    gen double exp_oecd = totexp_clm / eqsc_oecd
    gen double weight_u = finlwt21              // (U) CU weight
end

* sample restrictions + ratio
capture program drop restrict_sample
program define restrict_sample
    args cfg yr
    gen double inc_pre = fsalarym + fnonfrmm + ffrmincm
	
	destring age_ref, replace force
    keep if inrange(age_ref, 25, 60)
	
		    * ratio
    _pctile inc_pre [pw=weight_u], p(50)
    scalar med_`cfg' = r(r1)
    scalar rfg_`cfg' = 5000 / med_`cfg'
    di as txt "`yr' `cfg' - median inc (wtd): " %10.1f med_`cfg' ///
              "   FG ratio (cutoff/median): " %6.4f rfg_`cfg'

    * unweighted % of units dropped by the income cut
    quietly count
    local n0 = r(N)
    drop if inc_pre < 5000
    quietly count
    di as txt "`yr' `cfg' - income cut: dropped " %5.2f 100*(1-r(N)/`n0') "%"
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
    args cfg
    gen double sh_food = agric_clm / totexp_clm
    gen double sh_good = manuf_clm / totexp_clm
    gen double sh_serv = serv_clm  / totexp_clm

    xtile qexp = exp_oecd [aw=weight_u], nq(5)

    foreach grp in 0 1 2 3 4 5 {
        foreach sec in food good serv {
            if "`sec'"=="food" local catv agric_clm
            if "`sec'"=="good" local catv manuf_clm
            if "`sec'"=="serv" local catv serv_clm

            if `grp'==0 {
                quietly sum sh_`sec' [aw=weight_u], detail
                local m = r(mean)
                local v = r(Var)
                local n = r(N)
                quietly sum `catv'      [aw=weight_u]
                local mc = r(mean)
                quietly sum totexp_clm  [aw=weight_u]
                local mt = r(mean)
            }
            else {
                quietly sum sh_`sec' [aw=weight_u] if qexp==`grp', detail
                local m = r(mean)
                local v = r(Var)
                local n = r(N)
                quietly sum `catv'      [aw=weight_u] if qexp==`grp'
                local mc = r(mean)
                quietly sum totexp_clm  [aw=weight_u] if qexp==`grp'
                local mt = r(mean)
            }
            local agg = `mc'/`mt'
            post shares ("`cfg'") ("`sec'") (`grp') (`agg') (`m') (`v') (`n')
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
* LOOP OVER YEARS
*-------------------------------------------------------------------------------
* CPI
preserve
    clear
    set obs 60
    gen int ym = ym(2008,1) + _n - 1     // 2008m1 ... 2012m12
    gen double cpi = .
    local cpivals ///
        211.080 211.693 213.528 214.823 216.632 218.815 ///
        219.964 219.086 218.783 216.573 212.425 210.228 ///
        211.143 212.193 212.709 213.240 213.856 215.693 ///
        215.351 215.834 215.969 216.177 216.330 215.949 ///
        216.687 216.741 217.631 218.009 218.178 217.965 ///
        218.011 218.312 218.439 218.711 218.803 219.179 ///
        220.223 221.309 223.467 224.906 225.964 225.722 ///
        225.922 226.545 226.889 226.421 226.230 225.672 ///
        226.665 227.663 229.392 230.085 229.815 229.478 ///
        229.104 230.379 231.407 231.317 230.221 229.601
    local i = 0
    foreach v of local cpivals {
        local ++i
        quietly replace cpi = `v' in `i'
    }
    tempfile cpilook
    save "`cpilook'", replace
restore
 
* open year loop
* MODIFY HERE TO ADD MORE YEARS
* note, you also need to add those years in p0_flow.do
foreach yr in 2009 2010 2011 { 

    * five quarterly files: the four survey quarters + the following year's Q1
    if "`yr'"=="2009" local qfiles fmli091x fmli092 fmli093 fmli094
	if "`yr'"=="2010" local qfiles fmli101x fmli102 fmli103 fmli104
    if "`yr'"=="2011" local qfiles fmli111x fmli112 fmli113 fmli114
	* i have download fmli121 if downloaded from 2011 survey, 
	* o/w use fmli121x if downloaded from 2012 survey

    local first : word 1 of `qfiles'
    use "$data2010/`first'.dta", clear
    local q = 1
    gen long file_yq = real("`yr'0`q'")
    foreach f of local qfiles {
        if "`f'"!="`first'" {
            local ++q
            append using "$data2010/`f'.dta"
            replace file_yq = real("`yr'0`q'") if missing(file_yq)   
        }
    }

    destring qintrvmo qintrvyr, replace

    foreach s of local stems {
        gen double `s'_q = `s'pq + `s'cq
    }

    gen byte iv_no = mod(newid, 10)           // 2, 3, 4, or 5

    * merge MS vehicle service flow at the interview level (on newid)
merge 1:1 newid using "$data2010/ms_vflow_09_12.dta", ///
      keep(master match) keepusing(n_tot_vflow1)
    tab _merge
    replace n_tot_vflow1 = 0 if missing(n_tot_vflow1)
    drop _merge

    * quarterly imputed rent (renteqvx per interview x 3 months)
    destring cutenure renteqvx, replace force
    gen byte tenure_end = .
    replace  tenure_end = 1 if inlist(cutenure,1,2,3)    // owner
    replace  tenure_end = 2 if cutenure == 4             // renter
    gen double imputed_rent_q = renteqvx*3 if tenure_end == 1
    replace    imputed_rent_q = 0          if tenure_end == 2

    * CPI deflation to constant 2010 dollars (2010 annual avg CPI-U = 218.056),
    * done at the MONTHLY level: each interview is deflated by the mean CPI of
    * its own three reference months.
    forvalues k = 1/3 {
        gen int ym = ym(qintrvyr - (qintrvmo-`k' < 1), ///
                        qintrvmo - `k' + 12*(qintrvmo-`k' < 1))
        merge m:1 ym using "`cpilook'", keep(master match) nogen
        rename cpi cpi`k'
        drop ym
    }
    egen double cpi_ref = rowmean(cpi1 cpi2 cpi3)
    gen double defl_i   = 218.056 / cpi_ref
    quietly count if missing(defl_i)
    di as txt "`yr' - rows with missing deflator: " r(N)
    quietly sum defl_i
    di as txt "`yr' - monthly CPI deflator to 2010 dollars: mean " %6.4f r(mean) ///
              "  min " %6.4f r(min) "  max " %6.4f r(max)
    drop cpi1 cpi2 cpi3 cpi_ref

    foreach s of local stems {
        quietly replace `s'_q = `s'_q * defl_i
    }
    quietly replace n_tot_vflow1   = n_tot_vflow1   * defl_i
    quietly replace imputed_rent_q = imputed_rent_q * defl_i

    foreach v in fsalarym fnonfrmm ffrmincm fssixm unemplxm compensm ///
                 welfarem foodsmpm chdothxm aliothxm tottxpdm {
        capture confirm variable `v'
        if !_rc {
            capture confirm string variable `v'
            if !_rc destring `v', replace force
            quietly replace `v' = `v' * defl_i
        }
    }
    drop defl_i
	
    tempfile base
    save "`base'", replace

*-------------------------------------------------------------------------------
* OPEN THE SHARED OUTPUT TABLES
*-------------------------------------------------------------------------------
    capture postclose moments
    postfile moments str12 tag ///
        double(mean var sd p10 p25 p50 p75 p90 nobs) ///
        using "$newoutput/log_moments_`yr'.dta", replace 

    capture postclose shares
    postfile shares str4 sample str4 sector byte quintile ///
        double(agg_share mean_share var_share) long nobs ///
        using "$newoutput/shares_moments_`yr'.dta", replace 

*-------------------------------------------------------------------------------
* (A)
*-------------------------------------------------------------------------------
    use "`base'", clear

    local sumvars
    foreach s of local stems { 
		local sumvars `sumvars' `s'_q 
		}

    tempfile cu_exp cu_5th

    preserve
        collapse                                              ///
            (sum)  `sumvars'                                  ///
            (sum)  vehicle_flow = n_tot_vflow1                ///
            (sum)  imputed_rent_q                             ///
            (max)  tenure_end                                 ///
            (count) n_interviews = iv_no                      ///
            , by(cuid)
        save "`cu_exp'", replace
    restore

    preserve
        keep if iv_no == 5
        keep cuid newid finlwt21 fsalarym fnonfrmm ffrmincm  ///
                  fssixm unemplxm compensm welfarem foodsmpm ///
                  chdothxm aliothxm tottxpdm                 ///
                  age_ref fam_size perslt18
        save "`cu_5th'", replace
    restore

    use "`cu_exp'", clear
    merge 1:1 cuid using "`cu_5th'"
    keep if _merge == 3
    drop _merge
    foreach s of local stems { 
		rename `s'_q `s' 
		}

    drop if tenure_end == 1 & missing(imputed_rent_q)
    drop if missing(tenure_end)

    build_totexp
    build_scales

    keep if n_interviews == 4
	
    restrict_sample a "`yr'"

    destring age_ref, replace force
    keep if inrange(age_ref, 25, 60)

    post_moments exp_oecd weight_u a_exp_oecd
	post_moments inc_pre  weight_u a_inc_pre 
    post_shares a

*-------------------------------------------------------------------------------
* (B)
*-------------------------------------------------------------------------------
    use "`base'", clear

    local sumvars
    foreach s of local stems { 
		local sumvars `sumvars' `s'_q 
		}

    collapse (mean) `sumvars' (mean) vehicle_flow = n_tot_vflow1 ///
             (mean) imputed_rent_q (max) tenure_end, by(cuid)
    foreach s of local stems {
		rename `s'_q `s' 
		}
    foreach s of local stems {
		replace `s' = `s'*4 
		}
    replace vehicle_flow   = vehicle_flow*4
    replace imputed_rent_q = imputed_rent_q*4

    preserve
        use "`base'", clear
        bysort cuid (iv_no): keep if _n == _N
        keep cuid finlwt21 fsalarym fnonfrmm ffrmincm ///
             age_ref fam_size perslt18 qintrvyr iv_no
        tempfile last
        save "`last'", replace
    restore
    merge 1:1 cuid using "`last'", keep(match) nogen

    drop if tenure_end == 1 & missing(imputed_rent_q)
    drop if missing(tenure_end)

    build_totexp
    build_scales
	
    restrict_sample b "`yr'"
	
    post_moments exp_oecd weight_u b_exp_oecd
	post_moments inc_pre   weight_u b_inc_pre 
    post_shares b

*-------------------------------------------------------------------------------
* (C)
*-------------------------------------------------------------------------------
    use "`base'", clear

    gen double vehicle_flow = n_tot_vflow1
    foreach s of local stems { 
		rename `s'_q `s' 
		}

    drop if tenure_end == 1 & missing(imputed_rent_q)
    drop if missing(tenure_end)

    build_totexp
    build_scales
	
	restrict_sample c "`yr'"
	
    post_moments exp_oecd weight_u c_exp_oecd
	post_moments inc_pre   weight_u c_inc_pre 
    post_shares c

*-------------------------------------------------------------------------------
* CLOSE AND WRITE THE TABLES
*-------------------------------------------------------------------------------
    postclose moments
    postclose shares

    preserve
        use "$newoutput/log_moments_`yr'.dta", clear
    restore
    preserve
        use "$newoutput/shares_moments_`yr'.dta", clear
    restore

}   // end year loop
