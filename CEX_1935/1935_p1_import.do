/*=====================================================================
  ICPSR 08908 (Study of Consumer Purchases, 1935-1936)
  STAGE 1 - ORGANIZE: subset + rename + append

  Input : the two ICPSR-provided Stata files
            Part 3 = Income & Expenditure, URBAN families
            Part 4 = Income & Expenditure, RURAL families

  Output: cex_1935_subset.dta  - the variables we actually use,
          renamed, labelled, with the two parts stacked.
=====================================================================*/

clear all
set more off
do "../globalpaths.do"


*──────────────────────────────────────────────────────────────────────
* program: open one part, subset+rename
*──────────────────────────────────────────────────────────────────────

* variables to keep (codebook VAR numbers = V-numbers)
global keepvars                                                              ///
  V3 V4 V8 V9 V11 V12 V14 V21 V24 V27 V29 V32 V34 V37 V39 V42 V44 V47 V49   ///
  V52 V54 V57 V59 V62 V64 V69 V87 V89                                             ///
  V111 V121 V131 V141 V151 V161 V171 V181 V191                              ///
  V192 V193 V194 V196 V198 V199 V201 V202 V203 V204 V247 V254                              ///
  V234 V285 V363 V364 V388 V393 V394 V395 V396 V397 V400                      ///
  V477 V531 V548 V553                                                          ///
  V558 V559 V621 V627 V630 V638 V639 V677 V686 V760 V776 V788 V789 V798               ///
  V812 V837 V845 V850 V853 V854 V855 V856 V857 V858 V859 V860 V1074 V1075 V1076 V1077 V1080 V1114     ///
  V1135 V1136 V1138 V1139 V1140 V1141 V1142 V1143 V1144 V1145 V1146 V1147 V1149 V1150 V1151 V1152 V1153 V1154 V1155   ///
  V1156 V1245 V1246 V1247 V1248 V1249 V1250 V1251 V1252 V1253 V1254 V1255 V1258 V1259 V1260 V1261 V1262   ///
  V1256 V1257 V1290 V1330 V1331 V1333 V2868


capture program drop _organize_part
program define _organize_part
    args infile

    use "`infile'", clear
	
	di "`infile'  (N=" _N ", vars=" c(k) ")"

    keep $keepvars

    *--- ids / structure ---
    rename V3   part_no
    rename V4   fam_id
    rename V8   id_no
    rename V14  urban_rural
    rename V11  county
    rename V12  state
    rename V9   hhsize_raw

    *--- demographics: head ages + member roster ---
    rename V21  husb_age
    rename V24  wife_age
    rename V27  rel3
    rename V29  age3_raw
    rename V32  rel4
    rename V34  age4_raw
    rename V37  rel5
    rename V39  age5_raw
    rename V42  rel6
    rename V44  age6_raw
    rename V47  rel7
    rename V49  age7_raw
    rename V52  rel8
    rename V54  age8_raw
    rename V57  rel9
    rename V59  age9_raw
    rename V62  rel10
    rename V64  age10_raw
    rename V69  n_adult_child

    *--- income ---
    rename V111 emp1_tot
    rename V121 emp2_tot
    rename V131 emp3_tot
    rename V141 emp4_tot
    rename V151 emp5_tot
    rename V161 emp6_tot
    rename V171 emp7_tot
    rename V181 emp8_tot
    rename V191 emp9_tot
    rename V192 emp_earn_exfarm
    rename V193 emp_earn_sub
    rename V194 inc_roomers
    rename V196 inc_housework
    rename V198 inc_interest
    rename V199 inc_profits
	rename V203 inc_bus_loss
    rename V201 inc_pensions
    rename V202 inc_gifts
    rename V204 inc_othmoney
    rename V234 inc_farming
	rename V247 farm_op_exp
    rename V285 inc_total

    *--- housing  ---
    rename V87  owner_months      
    rename V89  rental_value_m     
    rename V254 house_value       
    rename V363 rent_dwe
    rename V364 rent_dwe_other      // other means other houses (not primary residence)
    rename V393 owned_dwe    
    rename V394 owned_dwe_other  
    rename V395 housing_tot
    rename V396 housing_tot_other
    rename V397 vacation_tot     
    rename V388 rent_at_school  
	rename V400 rent_gift
	

    *--- fuel / utilities ---
    rename V477 fuel_kero
    rename V531 fuel_coal
    rename V548 fuel_elec
    rename V553 fuel_gas
    rename V558 fuel_ic
	rename V559 fuel_total


    *--- household operations ---
    rename V621  help_total
    rename V627 telephone_y
    rename V630 laundry_y
	rename V638  other_hh_total
    rename V639 hh_ops_tot

    *--- medical ---
    rename V677 medicines
    rename V686 medical_tot

    *--- recreation / reading / education / tobacco / personal care ---
    rename V760 rec_admissions
    rename V776 rec_games_sport
    rename V788 rec_other
	rename V789 rec_total
    rename V798 tobacco_tot
    rename V812 reading_tot
    rename V837 education_tot
    rename V1290 perscare_tot

    *--- occupational / contributions ---
    rename V845 union_dues
    rename V850 occ_exp_tot
	rename V853 gifts_friends
	rename V854 gifts_relatives
	rename V855 gifts_other
	rename V856 gifts_community
	rename V857 gifts_church
	rename V858 taxes_income_property
	rename V859 gifts_mixed
	rename V860 gifts_total

    *--- food ---
    rename V1074 food_home_y
    rename V1075 food_away_y
	rename V1076 food_board_school_y
    rename V1077 food_tot_y
    rename V1080 food_raised_val

    *--- automobile ---
    rename V1114 auto_netprice
    rename V1135 auto_gas
	rename V1136 auto_oil
    rename V1138 auto_tires
    rename V1139 auto_repairs
	rename V1140 parking_garage
    rename V1141 auto_license
    rename V1142 auto_fines     
    rename V1143 auto_ins
    rename V1144 auto_tolls    
    rename V1145 auto_accessories  
    rename V1146 auto_other       
	rename V1147 auto_tot
    rename V1255 transit_bus
    rename V1256 transit_rail
    rename V1257 transit_interurban
	rename V1258 other_travel
	rename V1259 motorcycle
	rename V1260 horse
	rename V1261 other_vehicle
	rename V1262 total_transportation

    *--- clothing ---
    rename V1149 clage_wife
    rename V1150 clage_husb
    rename V1151 clage_m3
    rename V1152 clage_m4
    rename V1153 clage_m5
    rename V1154 clage_m6
    rename V1155 clage_m7
    rename V1156 clage_m8
    rename V1245 cl_wife
    rename V1246 cl_husb
    rename V1247 cl_m3
    rename V1248 cl_m4
    rename V1249 cl_m5
    rename V1250 cl_m6
    rename V1251 cl_m7
    rename V1252 cl_m8
    rename V1253 cl_m9
    rename V1254 cloth_tot

    *--- furnishings / equipment ---
    rename V1330 floor_cover
    rename V1331 furniture
	rename V1333 furnish_total
    rename V2868 ff_furnish_tot
	
end

*──────────────────────────────────────────────────────────────────────
* run on both parts and append (urban + rural are disjoint families)
*──────────────────────────────────────────────────────────────────────
tempfile p3 p4
_organize_part "$data1935/08908-0003-Data.dta" 
di "Part 3 (urban) records: " _N
save `p3'

_organize_part "$data1935/08908-0004-Data.dta"
di "Part 4 (rural) records: " _N
save `p4'

use `p3', clear
append using `p4'
di "Appended Parts 3+4 records: " _N
tab part_no urban_rural, missing

* we use the original ICPSR labels
describe

compress
save "$data1935/cex_1935_import.dta", replace
di "Saved: cex_1935_import.dta  (N=" _N ", vars=" c(k) ")"
