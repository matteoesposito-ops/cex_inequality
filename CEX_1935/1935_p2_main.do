/*=====================================================================
  Study of Consumer Purchases, 1935-1936 (ICPSR 08908)
  Parts 3 (urban) and 4 (rural): income AND expenditure families

  INPUT: cex_1935_import.dta

  SCALING: the ICPSR .dta already applied implied decimals.

  WEIGHTS: NONE. ICPSR 08908 is a self-weighting sample (equal
           probability of selection; codebook pp. XI-XII). All
           moments/quintiles/shares below are therefore UNWEIGHTED.
           A weight hook (`local w`) is left at the top so an external
           weight can be slotted in later without touching the body.
=====================================================================*/

clear all
set more off

do "../globalpaths.do"


* weight hook: empty = unweighted. To weight, set e.g. local w "[aw=myweight]"
local w ""

use "$data1935/cex_1935_import.dta", clear
di "Loaded cex_1935_import.dta records: " _N
tab part_no urban_rural, missing

*──────────────────────────────────────────────────────────────────────
* 1. handling missing values
*──────────────────────────────────────────────────────────────────────

* (a) household size: integer count; MD = 99
gen hhsize = hhsize_raw
replace hhsize = . if hhsize_raw == 99
label var hhsize "No. in economic family"

* (b) ages. Husband/wife = integer years (MD 0/99). Roster + clothing ages
*   are stored in years (e.g. 14.0); their MD code 9999 appears as 99.99, so we
*   strip codes via the original integer code: round(age*100) in {0,9999}.
replace husb_age = . if inlist(husb_age,0,99)
replace wife_age = . if inlist(wife_age,0,99)
foreach m in 3 4 5 6 7 8 9 10 {
    capture confirm variable age`m'_raw
    if !_rc {
        gen double age`m' = age`m'_raw
        replace age`m' = . if inlist(round(age`m'*100),0,9999)
        drop age`m'_raw
    }
}
foreach m in m3 m4 m5 m6 m7 m8 {
    replace clage_`m' = . if inlist(round(clage_`m'*100),0,9999)
}
replace clage_wife = . if inlist(clage_wife,0,99)
replace clage_husb = . if inlist(clage_husb,0,99)

* (c) income
local mdcodes 9999, 99999, 999999, 9999999, 99999999
foreach v of varlist emp1_tot emp2_tot emp3_tot emp4_tot emp5_tot           ///
                     emp6_tot emp7_tot emp8_tot emp9_tot                    ///
                     inc_housework inc_profits inc_farming farm_op_exp {
    replace `v' = . if inlist(round(`v'*100), `mdcodes')                  
}

*──────────────────────────────────────────────────────────────────────
* 2. DEMOGRAPHICS: reference-person age, child counts
*──────────────────────────────────────────────────────────────────────

* Reference person: husband if present, else wife.                       
gen double age_ref = husb_age
replace    age_ref = wife_age if missing(age_ref)
label var  age_ref "Reference-person age (husband; wife if husband missing)"

* Children under 18 / under 14 from the member roster (members 3..10).
* Husband & wife are treated as adults. This is an UNDER-18 count built
* directly from member ages, paralleling the 1960 under-18 proxy.        
gen byte n_u18 = 0
gen byte n_u14 = 0
foreach m in 3 4 5 6 7 8 9 10 {
    capture confirm variable age`m'
    if !_rc {
        replace n_u18 = n_u18 + (age`m' < 18 & !missing(age`m'))
        replace n_u14 = n_u14 + (age`m' < 14 & !missing(age`m'))
    }
}
label var n_u18 "Members under 18 (roster)"
label var n_u14 "Members under 14 (roster)"
* cross-check against the survey's NO.ADULT.CHILDREN field
sum n_adult_child n_u18 n_u14

*──────────────────────────────────────────────────────────────────────
* 3. AGE RESTRICTION  (reference person 25-60)
*──────────────────────────────────────────────────────────────────────
count
keep if inrange(age_ref, 25, 60)
di "After age restriction (25-60): " _N

*──────────────────────────────────────────────────────────────────────
* 4. INCOME using the paper definition
*──────────────────────────────────────────────────────────────────────
gen double inc_farm_net = cond(missing(inc_farming),0,inc_farming) ///
                        - cond(missing(farm_op_exp),0,farm_op_exp)
label var inc_farm_net "Net farm income (V234 - V247)"

gen double inc_bus_net = cond(missing(inc_profits),0,inc_profits) ///
                       - cond(missing(inc_bus_loss),0,inc_bus_loss)
label var inc_bus_net "Net business income (V199 - V203)"

* in p0_check we conclude that adding V192 and V193 would double count 
* village and farm income even if the codebook says otherwise
egen double inc_pre = rowtotal(emp1_tot emp2_tot emp3_tot emp4_tot emp5_tot ///
                               emp6_tot emp7_tot emp8_tot emp9_tot          ///
                               inc_housework inc_bus_net inc_farm_net)           
label var inc_pre "Pre-tax-and-transfer LABOR income (wages+self-empl+business+net farm)"

* income distribution check
count if inc_pre <= 0
count if inc_pre > 0 & inc_pre < 100
sum inc_pre `w', detail

* POST-TAX INCOME: to be added later. V285 (TOTAL_INCOME) is gross/pre-tax
*  and taxes are recorded separately as an expenditure (V858)

*──────────────────────────────────────────────────────────────────────
* 5.  Impute rent for owners
*   renters -> actual annual rent paid (rent_present, = V359);
*   owners  -> owner-reported rental value x 12 (rental_value_m, = V89, monthly;
*              "Q.IV 2a monthly rental value of the first home"). 99% of owners
*              report it, so it is the primary owner measure.
*   instead of dropping the ~1% of owners with no reported rental value: 
*   house value (house_value, = V254) x rent-to-price ratio. 
*   Ratio 8.29 from Lyons, Shertzer, Gray & Agorastos, 
*   "The Price of Housing in the United States, 1890-2006", Table 2.
*──────────────────────────────────────────────────────────────────────
  
scalar rent_price_ratio = 8.29      // annual rent / house value  orientation

* tenure: owner if months-as-owner > 0 (owner_months, = V87); renter if rent paid.
gen byte owner_hh  = (owner_months > 0 & !missing(owner_months))
gen byte renter_hh = (rent_dwe  > 0 & !missing(rent_dwe))

* imputed annual rent for owners
gen double imp_rent = .
replace imp_rent = rental_value_m * 12              if owner_hh & rental_value_m > 0 & !missing(rental_value_m)
replace imp_rent = house_value * rent_price_ratio   if owner_hh & missing(imp_rent) & house_value > 0 & !missing(house_value)

*──────────────────────────────────────────────────────────────────────
* 6. AB INTERMEDIATE CATEGORIES  
*    Built to mirror 2010 AB intermediates with 1935-36 fields.
*──────────────────────────────────────────────────────────────────────

* VEHPCH = cartkn + cartku + othveh + vehfin + vrntlo + vehins (2010)
*   where MS substitute cartkn + cartku + othveh + vehfin with vehicle flow
*   compared to 2010, we also have motorcycle + horse + other_vehicle  
gen double vehpch_ab = auto_netprice + auto_license + auto_ins + motorcycle + horse + other_vehicle

* VEHOPR = gasmo + mainrp (2010)
* note that there is a problem in the codebook as auto_gas and auto_other have the same description
*   but they have different values; we leave auto_fines out.
* we include parking space and garage rent here               
gen double vehopr_ab = auto_gas + auto_oil + auto_tires + auto_repairs + auto_tolls + auto_accessories + auto_other + parking_garage

* OPPUB = vehopr + pubtra (2010)
gen double oppub_ab = vehopr_ab + transit_bus + transit_rail + transit_interurban + other_travel
label var oppub_ab "AB operations + public transit"


* SHOESOTH: footwr + othapl (2010)
* no separate footwear line 

* FURNSH = textil + furntr + flrcvr (2010)
* EQUPMT = majapp + smlapp + misceq + teleph (2010)
* we use the survey furnishings & equipment total (V1333). 
* It is the schedule recap covering furniture, floor covering,
*   linen, glass/china, and equipment.
gen double furnsh_equpmt_ab = furnish_total        
label var furnsh_equpmt_ab "AB furnishings & equipment"

* UTIL = ntlgas + elctrc + fuloil + othfls + watrps (2010)
* UTIL = fuel/light/refrigeration total (V559). Use the recorded parent
gen double util_ab = fuel_total     
label var util_ab "AB utilities"

* HOUSOP = dmsxcc + bbyday  (domestic service + babysitting/day care) (2010)
* HOUSOP = household operations EXCLUDING fuel = domestic help (V621) + other
*   household (V638)  [ = V639 - V559 ].
gen double housop_ab = hh_ops_tot + other_hh_total
label var housop_ab "AB household operations excl. fuel"

* SHELT = rendwe + othlod + imputed rent (2010)
* SHELT = rent paid (actual + imputed + other) + value of housing received as gift + vacation home + rent at school 
*   We exclude owner housing outlays on primary house, owned_dwe, becuase we compute rental equivalence
*   but  we keep housing outlays on other owned properties, owned_dwe_other, since we don't compute rental equivalence for them.
gen double shelt_ab = rent_dwe + imp_rent + rent_dwe_other + owned_dwe_other + vacation_tot + rent_at_school + rent_gift
label var shelt_ab "AB shelter"

* FEEARD = feeadm + read (2010)
* TVRDOT = tvrdio + otheqp (2010)
* we put them together since we can't split the recreation subvariables
gen double feeard_tvrdot_ab = rec_total + reading_tot
label var feeard_tvrdot_ab "AB recreation + reading"

*FDAWAY, we add food for board at school even if not present in 2010
gen double fdaway_ab = food_away_y + food_board_school_y
label var fdaway_ab "AB food away from home"

* CASHCO (2010) = we drop TAXES V858 dropped from V860 gifts_total
gen double gifts_excl_tax = gifts_friends + gifts_relatives + gifts_other + gifts_community + gifts_church + gifts_mixed

* Identities used directly in CLM below:
* HEALTH  = medical_tot
* PERSCA  = perscare_tot
* EDUCA   = education_tot
* TOBACC  = tobacco_tot
* FDHOME  = food_home_y   

* for clothing, we use directly the parent and do not implement a kid/adult split        

* we exclude occ_exp_tot (occupational)

*──────────────────────────────────────────────────────────────────────
* 7. CLM MACRO CATEGORIES (Comin-Lashkari-Mestieri)
*──────────────────────────────────────────────────────────────────────

* Agriculture: food at home only (alcohol is included in food away in 1935).  
gen double agric_clm = food_home_y + 1
label var  agric_clm "CLM: agriculture (food at home)"

* Manufacturing
gen double manuf_clm = vehpch_ab    ///  vehicle purchase
                     + oppub_ab     ///  vehicle operations + transit
					 + cloth_tot     /// clothing total
                     + furnsh_equpmt_ab    ///  furnishings & equipment 
                     + perscare_tot ///  personal care
                     + tobacco_tot  ///  tobacco
                     + 1

label var manuf_clm "CLM: manufactured goods"

* Services
gen double serv_clm  = shelt_ab        ///  shelter
                     + util_ab         ///  utilities
                     + housop_ab       ///  household 
                     + medical_tot     ///  health
                     + feeard_tvrdot_ab     ///  recreation + reading
                     + education_tot   ///  education
                     + gifts_excl_tax   ///  cashco proxy (gifts excl. taxes)
                     + fdaway_ab       ///  food away
                     + 1
label var serv_clm "CLM: services"

gen double totexp_clm = agric_clm + manuf_clm + serv_clm

gen double share_agric_clm = agric_clm / totexp_clm
gen double share_manuf_clm = manuf_clm / totexp_clm
gen double share_serv_clm  = serv_clm  / totexp_clm
label var totexp_clm      "CLM: total expenditure (constructed)"
label var share_agric_clm "CLM share: food at home"
label var share_manuf_clm "CLM share: manufactured goods"
label var share_serv_clm  "CLM share: services"

sum agric_clm manuf_clm serv_clm totexp_clm
sum share_agric_clm share_manuf_clm share_serv_clm

* keep only consumer units with positive constructed total
drop if missing(totexp_clm) | totexp_clm <= 0
di "After dropping nonpositive total expenditure: " _N

*──────────────────────────────────────────────────────────────────────
* 8. SAMPLE RESTRICTION:
*──────────────────────────────────────────────────────────────────────
scalar ratio_2010 = 0.0954

* apply ratio and median BEFORE the cut
_pctile inc_pre, p(50)
scalar med_inc_1935 = r(r1)
scalar threshold_1935 = ratio_2010 * med_inc_1935
di as txt "1935 minimum income (cutoff): " %8.1f threshold_1935 " (1935 dollars)"
di as txt "                             ~ " %8.0f threshold_1935*17.5 " (2016 dollars)"

gen byte below_thr = (inc_pre < threshold_1935)
sum below_thr `w'
di as txt "Share below threshold: " r(mean)
drop if below_thr == 1
drop below_thr
di "Observations remaining: " _N

*  which results in a cutoff of 162.7 (1935 dollars) × 17.5 ≈ 2847 (2016 dollars)

*──────────────────────────────────────────────────────────────────────
* 9. EQUIVALIZED EXPENDITURE  (modified OECD & Oxford, as in 1960.do)
*──────────────────────────────────────────────────────────────────────
gen double n_child = n_u18            //  under-18 proxy, as 1960 and 2010
gen double n_adult = hhsize - n_u18
replace    n_adult = 0 if n_adult < 0

gen double eqsc_mod = 1 + 0.5*max(n_adult-1,0) + 0.3*n_child
gen double eqsc_oxf = 1 + 0.7*max(n_adult-1,0) + 0.5*n_child
replace eqsc_mod = 1 if eqsc_mod < 1
replace eqsc_oxf = 1 if eqsc_oxf < 1

gen double exp_raw  = totexp_clm
gen double exp_mod  = totexp_clm / eqsc_mod
gen double exp_oecd = totexp_clm / eqsc_oxf
label var exp_raw  "Raw CLM total expenditure ($)"
label var exp_mod  "Equivalized CLM expenditure, modified OECD ($)"
label var exp_oecd "Equivalized CLM expenditure, Oxford OECD ($)"

*──────────────────────────────────────────────────────────────────────
* 10. CLM SHARES BY EXPENDITURE QUINTILE  (raw + OECD)
*──────────────────────────────────────────────────────────────────────
gen log_exp_raw = log(exp_raw) if exp_raw > 0
sum log_exp_raw `w', detail

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
    save "$oldoutput/1935_moments_log_exp_raw.dta", replace
restore

gen log_exp_oecd = log(exp_oecd) if exp_oecd > 0
sum log_exp_oecd `w', detail

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
    save "$oldoutput/1935_moments_log_exp_OECD.dta", replace
restore



*──────────────────────────────────────────────────────────────────────
* 11. CLM SHARES BY EXPENDITURE QUINTILE  (raw + OECD)
*──────────────────────────────────────────────────────────────────────
xtile exp_quin_raw  = exp_raw  `w', nq(5)
xtile exp_quin_oecd = exp_oecd `w', nq(5)
label var exp_quin_raw  "Raw expenditure quintile (1=bottom)"
label var exp_quin_oecd "OECD-equivalized expenditure quintile (1=bottom)"

capture program drop _save_clm_shares
program define _save_clm_shares
    args byvar outfile wt
    preserve
        collapse                                                  ///
            (mean) mean_share_food_clm=share_agric_clm           ///
                   mean_share_goods_clm=share_manuf_clm          ///
                   mean_share_serv_clm=share_serv_clm            ///
            (sum)  sum_food_clm=agric_clm                        ///
                   sum_goods_clm=manuf_clm                       ///
                   sum_serv_clm=serv_clm                         ///
                   sum_total_clm=totexp_clm                      ///
            `wt', by(`byvar')
        gen double agg_share_food_clm  = sum_food_clm  / sum_total_clm
        gen double agg_share_goods_clm = sum_goods_clm / sum_total_clm
        gen double agg_share_serv_clm  = sum_serv_clm  / sum_total_clm
        keep `byvar' mean_share_food_clm mean_share_goods_clm mean_share_serv_clm ///
                     agg_share_food_clm  agg_share_goods_clm  agg_share_serv_clm
        order `byvar' mean_share_food_clm mean_share_goods_clm mean_share_serv_clm ///
                      agg_share_food_clm  agg_share_goods_clm  agg_share_serv_clm
        save "`outfile'", replace
        list, noobs clean
    restore
end

_save_clm_shares exp_quin_oecd "$oldoutput/1935_CLM_by_exp_quin_OECD.dta" "`w'"
_save_clm_shares exp_quin_raw  "$oldoutput/1935_CLM_by_exp_quin_raw.dta"  "`w'"

* total expenditure share by quintile
preserve
    collapse (sum) exp_raw `w', by(exp_quin_raw)
    egen total_exp = total(exp_raw)
    gen exp_share = exp_raw / total_exp
    list exp_quin_raw exp_share, noobs clean
    save "$oldoutput/1935_expshare_quin_raw.dta", replace
restore

preserve
    collapse (sum) exp_oecd `w', by(exp_quin_oecd)
    egen total_exp = total(exp_oecd)
    gen exp_share = exp_oecd / total_exp
    list exp_quin_oecd exp_share, noobs clean
    save "$oldoutput/1935_expshare_quin_OECD.dta", replace
restore

*──────────────────────────────────────────────────────────────────────
* 13. INCOME SHARES BY INCOME QUINTILE
*──────────────────────────────────────────────────────────────────────
xtile inc_pre_quin  = inc_pre         `w', nq(5)
*xtile inc_post_quin = inc_post_tax_tr `w', nq(5)
label var inc_pre_quin  "Pre-tax-and-transfer income quintile (1=bottom)"
*label var inc_post_quin "Post-tax-and-transfer income quintile (1=bottom)"

capture program drop _save_inc_shares
program define _save_inc_shares
    args incvar byvar outfile wt
    preserve
        collapse (sum) inc=`incvar' `wt', by(`byvar')
        egen total_inc = total(inc)
        gen inc_share = inc / total_inc
        keep `byvar' inc inc_share
        save "`outfile'", replace
        list, noobs clean
    restore
end

_save_inc_shares inc_pre         inc_pre_quin  "$oldoutput/1935_incshare_pre_quin.dta"  "`w'"
*_save_inc_shares inc_post_tax_tr inc_post_quin "$output/1935_incshare_post_quin.dta" "`w'"

*──────────────────────────────────────────────────────────────────────
compress
save "$data1935/cex_1935_clean.dta", replace
di "Saved: cex_1935_clean.dta  (N=" _N ")"

