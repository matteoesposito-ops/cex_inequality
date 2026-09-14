/*=====================================================================
  Consumer Expenditure Survey, 1960-1961 (ICPSR 09035) - CLEAN VERSION

  SOURCE FILE: 09035-0001-Data.txt
    Fixed-width, 1748 characters per record, 13728 observations.
    Column layout documented on pages 16-22 of the PDF codebook.
    Code values for categorical variables on pages 155-183 of the PDF  codebook.

  SCALING RULES (apply to all dollar variables):
    Expenditure and income fields: 10 characters, IMP DEC=2 -> divide by 100
    Survey weight (cols 58-62):    5 characters, IMP DEC=1 -> divide by 10
    Household size (cols 28-30):   3 characters, IMP DEC=1 -> divide by 10
	
	Produces log-expenditure moments and CLM sectoral shares by expenditure quintile,
	using Oxford-OECD equivalized, survey weight.
=====================================================================*/

* you need to put all_cons_data_for_stata_80_17.dta in the datafolder
* since it's too heavy to have on github

clear all
set more off

do "../globalpaths.do"

global datapath "$data1960/09035-0001-Data.txt"
capture mkdir "$cleanoutput"
*──────────────────────────────────────────────────────────────────────

infix                                                                         ///
 /*DEMOGRAPHICS*/ ///
 location_size       1-1     ///  location and size of place (CC-24)
  urbanization        2-2     ///  urbanization group (CC-48)
  area_class          3-3     ///  area classification (CC-49)
  smsa_state          4-5     ///  SMSA or state code (CC-25a or 25b)
  cu_number           6-9     ///  consumer unit schedule number
  region              10-10   ///  CC-22c: 1=NE 2=NC 3=S 4=W
  farm_status         11-11   ///  CC-50
  survey_year         12-12   ///  CC-21: last digit of survey year (9=1959 0=1960 1=1961)
  stratum             13-13   ///  CC-23: 1=A(≥1.4M) 2=B 3=C 4=D(urban) 6=rural nonfarm 7=rural farm
  sex_head            14-14   ///  CC-1:  1=male 2=female
  race_head           15-15   ///  CC-2:  1=white 2=negro 3=other
  educ_code           16-16   ///  CC-3 second digit
  educ_yrs            17-18   ///  actual years of education of head
  age_code            19-19   ///  CC-8 first digit
  age_yrs             20-22   ///  actual age of head in years
  occupation          23-25   ///  CC-13a/13b: 3-digit occupation code
  industry            26-26   ///  CC-14a: 1=agric 2=mining 3=constr 4=manuf 5=transport 6=trade 7=finance 8=services 9=public admin
  class_work          27-27   ///  CC-14b: 1=private 2=government
  num_persons_raw     28-30   ///  average persons in household (÷10)
  num_under18         31-31   ///  number of persons under 18
  num_65plus          32-32   ///  number of persons 65 and over
  part_year           33-33   ///  CC-9a: part-year membership
  relationship        34-34   ///  CC-9b: relationship of family members
  age_children        35-35   ///  CC-9c: age of children of head
  num_earners         36-36   ///  CC-11a: total number of earners
  earner_comp         37-37   ///  CC-12: earner composition
  inc_before_code     38-39   ///  CC-15a: family income before taxes (bracket code)
  inc_after_code      40-41   ///  CC-15b: family income after taxes (bracket code)
  inc_chg_sy_sy1      42-42   ///  CC-17a: income change between SY and SY-1
  inc_chg_sy1_sy2     43-43   ///  CC-17b: income change between SY-1 and SY-2
  inc_chg_sy1_sy      44-44   ///  CC-17c: income change between SY+1 and SY
  reason_chg_sy_sy1   45-45   ///  CC-18: reason for change SY to SY-1
  reason_chg_sy1_sy   46-46   ///  CC-18: reason for change SY+1 to SY
  housekeeping        47-47   ///  CC-33: 1=housekeeping 2=non-housekeeping
  inc_savings_ratio   48-48   ///  CC-19: 1=savings≥10% … 5=dissavings≥10% 6=other
  tenure_end          49-49   ///  CC-29b: tenure at end of SY (1=owner 2=renter)
  tenure_all          50-50   ///  CC-29a: tenure all year (1=owner 2=renter 3=other)
  occ_change          51-51   ///  CC-29c: change in occupancy status and type of rental
  yr_home_purch       52-52   ///  CC-29d: year of home purchase
  home_value          53-54   ///  CC-30: market value of owner-occupied housing (bracket code)
  monthly_rent        55-56   ///  CC-31: monthly rent paid (bracket code)
  num_autos           57-57   ///  CC-46: number of autos owned at end of survey year
  weight_raw          58-62   ///  expansion factor / survey weight (÷10)
  /* EXPENDITURES FOR CURRENT CONSUMPTION*/ ///
  /* FOOD */ ///
  exp_total_raw       63-72   ///  total current consumption expenditure
  food_total_raw      73-82   ///  food, total
  food_home_raw       83-92   ///  food prepared at home
  food_away_raw       93-102  ///  food away from home
  /* ALCOHOL AND TOBACCO  */ ///
  alcohol_raw        103-112  ///  alcoholic beverages
  tobacco_raw        113-122  ///  tobacco
  /* HOUSING  */ ///
  housing_total_raw  123-132  ///  housing, total
  shelter_total_raw  133-142  ///  shelter, total
  rent_dwell_raw     143-152  ///  rented dwelling
  owned_total_raw    153-162  ///  owned dwelling, total
  owned_mortg_raw    163-172  ///  interest on mortgages
  owned_taxes_raw    173-182  ///  taxes due in survey year
  owned_propins_raw  183-192  ///  property insurance
  owned_repairs_raw  193-202  ///  repairs and replacements
  owned_other_raw    203-212  ///  other expenses (owned dwelling)
  vacation_home_raw  213-222  ///  owned vacation home, cabin, etc.
  lodging_out_raw    223-232  ///  lodging out of home city
  other_reale_raw    233-242  ///  other real estate
  /* FUEL AND UTILITIES */ ///
  bills_total_raw     243-252  ///  fuel, light, refrigeration and water, total
  bills_solid_raw     253-262  ///  solid and petroleum fuels
  bills_gaselec_raw   263-272  ///  gas and electricity
  bills_water_raw     273-282  ///  water, sewage, garbage and trash collection
  bills_other_raw     283-292  ///  ice, water softening, freezer rentals, etc.
  /* HOUSEHOLD OPERATIONS */ ///
  hh_ops_total_raw   293-302  ///  household operations, total
  phone_raw          303-312  ///  telephone and telegraph
  hh_svc_raw         313-322  ///  other household services
  hh_suppl_raw       323-332  ///  household supplies
  /* HOUSEFURNISHINGS AND EQUIPMENT */ ///
  furnish_total_raw  333-342  ///  housefurnishings and equipment, total
  hh_textiles_raw    343-352  ///  household textiles
  furn_total_raw     353-362  ///  furniture, total
  furn_living_raw    363-372  ///  furniture - living room
  furn_dining_raw    373-382  ///  furniture - dining room
  furn_bedroom_raw   383-392  ///  furniture - bedroom
  furn_kitchen_raw   393-402  ///  furniture - kitchen, porch, garden, other
  floor_cover_raw    403-412  ///  floor coverings
  major_app_raw      413-422  ///  major appliances, total
  app_refrig_raw     423-432  ///  refrigerators, home freezers
  app_washing_raw    433-442  ///  washing machines, clothes dryers, combinations
  app_other_raw      443-452  ///  all other major appliances
  small_app_raw      453-462  ///  small appliances
  housewares_raw     463-472  ///  housewares, total
  furnish_ins_raw    473-482  ///  insurance on furnishings, equipment, and apparel
  furnish_other_raw  483-492  ///  other housefurnishings
  /* CLOTHING */ ///
  cloth_total_raw    493-502  ///  clothing, clothing materials, and services, total
  cloth_men_raw      503-512  ///  men and boys 18 years and over, total
  cloth_men_out_raw  513-522  ///  men 18+ outerwear
  cloth_men_und_raw  523-532  ///  men 18+ underwear, nightwear, hosiery
  cloth_men_ft_raw   533-542  ///  men 18+ footwear
  cloth_men_ht_raw   543-552  ///  men 18+ hats, gloves, accessories
  cloth_men_oth_raw  553-562  ///  men 18+ expenditures not allocated
  cloth_boy1617_raw  563-572  ///  boys 16 and 17 years, total
  cloth_b17_out_raw  573-582  ///  boys 16-17 outerwear
  cloth_b17_und_raw  583-592  ///  boys 16-17 underwear, nightwear, hosiery
  cloth_b17_ft_raw   593-602  ///  boys 16-17 footwear
  cloth_b17_ht_raw   603-612  ///  boys 16-17 hats, gloves, accessories
  cloth_b17_oth_raw  613-622  ///  boys 16-17 expenditures not allocated
  cloth_boy215_raw   623-632  ///  boys 2 through 15 years, total
  cloth_b15_out_raw  633-642  ///  boys 2-15 outerwear
  cloth_b15_und_raw  643-652  ///  boys 2-15 underwear, nightwear, hosiery
  cloth_b15_ft_raw   653-662  ///  boys 2-15 footwear
  cloth_b15_ht_raw   663-672  ///  boys 2-15 hats, gloves, accessories
  cloth_b15_oth_raw  673-682  ///  boys 2-15 expenditures not allocated
  cloth_wom_raw      683-692  ///  women and girls 18 years and over, total
  cloth_wom_out_raw  693-702  ///  women 18+ outerwear
  cloth_wom_und_raw  703-712  ///  women 18+ underwear, nightwear, hosiery
  cloth_wom_ft_raw   713-722  ///  women 18+ footwear
  cloth_wom_ht_raw   723-732  ///  women 18+ hats, gloves, accessories
  cloth_wom_oth_raw  733-742  ///  women 18+ expenditures not allocated
  cloth_grl1617_raw  743-752  ///  girls 16 and 17 years, total
  cloth_g17_out_raw  753-762  ///  girls 16-17 outerwear
  cloth_g17_und_raw  763-772  ///  girls 16-17 underwear, nightwear, hosiery
  cloth_g17_ft_raw   773-782  ///  girls 16-17 footwear
  cloth_g17_ht_raw   783-792  ///  girls 16-17 hats, gloves, accessories
  cloth_g17_oth_raw  793-802  ///  girls 16-17 expenditures not allocated
  cloth_grl215_raw   803-812  ///  girls 2 through 15 years, total
  cloth_g15_out_raw  813-822  ///  girls 2-15 outerwear
  cloth_g15_und_raw  823-832  ///  girls 2-15 underwear, nightwear, hosiery
  cloth_g15_ft_raw   833-842  ///  girls 2-15 footwear
  cloth_g15_ht_raw   843-852  ///  girls 2-15 hats, gloves, accessories
  cloth_g15_oth_raw  853-862  ///  girls 2-15 expenditures not allocated
  cloth_under2_raw   863-872  ///  children under 2 years
  cloth_mater_raw    873-882  ///  clothing materials
  cloth_upkeep_raw   883-892  ///  clothing upkeep
  /* TRANSPORTATION */ ///
  transp_total_raw   893-902  ///  transportation, total
  auto_pur_raw       903-912  ///  automobile purchase
  auto_ops_raw       913-922  ///  automobile operation, total
  auto_gas_raw       923-932  ///  gasoline, motor oil, lubrication, washing
  auto_tires_raw     933-942  ///  tires, tubes, batteries, other equipment
  auto_unalloc_raw   943-952  ///  operating expenses not allocated
  auto_repairs_raw   953-962  ///  repairs and parts not covered by insurance
  auto_ins_raw       963-972  ///  automobile insurance
  auto_reg_raw       973-982  ///  registration and other
  pub_trans_raw      983-992  ///  public transportation, car pools, other
  /* MEDICAL CARE */ ///
  medical_raw        993-1002 ///  medical care, total
  med_prepaid_raw   1003-1012 ///  prepaid care (premiums / health insurance)
  med_direct_raw    1013-1022 ///  direct expenses, total
  med_hospital_raw  1023-1032 ///  for hospitalized illness
  med_phys_raw      1033-1042 ///  physicians' services outside hospital
  med_dental_raw    1043-1052 ///  dental services
  med_eye_raw       1053-1062 ///  eye care, including glasses
  med_othpract_raw  1063-1072 ///  other practitioners
  med_drugs_raw     1073-1082 ///  drugs and medicines
  med_applia_raw    1083-1092 ///  medical appliances, supplies, other
  /* PERSONAL CARE */ ///
  perscare_raw      1093-1102 ///  personal care, total
  perscare_svc_raw  1103-1112 ///  personal care services
  perscare_sup_raw  1113-1122 ///  personal care supplies
  /* RECREATION */ ///
  recreat_raw       1123-1132 ///  recreation, total
  recreat_tv_raw    1133-1142 ///  television
  recreat_radio_raw 1143-1152 ///  radio, phonographs, musical instruments, etc.
  recreat_adm_raw   1153-1162 ///  spectator admissions
  recreat_spt_raw   1163-1172 ///  participant sports (equipment, fees, dues)
  recreat_oth_raw   1173-1182 ///  club dues, hobbies, pets, toys, recreation out of city, other
  /* READING */ ///
  reading_raw       1183-1192 ///  reading, total
  /* EDUCATION */ ///
  educ_raw          1193-1202 ///  education, total
  educ_tuition_raw  1203-1212 ///  tuition and fees
  educ_books_raw    1213-1222 ///  school books, supplies, equipment
  educ_other_raw    1223-1232 ///  music and other special lessons, other
  /* MISCELLANEOUS */ ///
  misc_raw          1233-1242 ///  miscellaneous personal consumption (may be negative)
  /* PERSONAL INSURANCE */ ///
  pers_ins_raw      1243-1252 ///  personal insurance, total
  pins_vet_raw      1253-1262 ///  life/endowment/annuity - veterans
  pins_group_raw    1263-1272 ///  life/endowment/annuity - group (deducted from pay)
  pins_life_raw     1273-1282 ///  life/endowment/annuity - other
  pins_mutual_raw   1283-1292 ///  mutual aid
  pins_disab_raw    1293-1302 ///  disability income
  pins_other_raw    1303-1312 ///  other personal insurance
  pins_ss_raw       1313-1322 ///  social security, railroad and government retirement
  pins_retire_raw   1323-1332 ///  private retirement
  /* GIFTS AND CONTRIBUTIONS */ ///
  gifts_raw         1333-1342 ///  gifts and contributions, total (cash, goods, services)
  gifts_pers_raw    1343-1352 ///  to persons not in consumer unit
  gifts_orgs_raw    1353-1362 ///  to organizations
  /* NET CHANGE IN ASSETS AND LIABILITIES */ ///
  net_assets_raw    1363-1372 ///  net change in assets and liabilities, total
  net_asschg_raw    1373-1382 ///  net change in assets
  cash_bank_raw     1383-1392 ///  cash in bank, on hand, money owed to family
  ass_owndw_raw     1393-1402 ///  purchase/improvement/sale of own dwelling
  ass_othprop_raw   1403-1412 ///  other real property
  ass_business_raw  1413-1422 ///  investment in business
  ass_stocks_raw    1423-1432 ///  stocks and bonds
  ass_personal_raw  1433-1442 ///  sale of personal property
  ass_ins_raw       1443-1452 ///  settlement or surrender of insurance policies
  ass_other_raw     1453-1462 ///  other assets
  net_liab_raw      1463-1472 ///  net change in liabilities
  liab_mortdw_raw   1473-1482 ///  mortgage on own dwelling
  liab_mortoth_raw  1483-1492 ///  mortgage on other real property
  liab_banks_raw    1493-1502 ///  money owed to banks, insurance companies, etc.
  liab_auto_raw     1503-1512 ///  money owed on automobile purchase
  liab_furnish_raw  1513-1522 ///  money owed on housefurnishings and equipment
  liab_othgds_raw   1523-1532 ///  money owed on other goods and services
  liab_renttax_raw  1533-1542 ///  money owed on rent, taxes, and other liabilities
  acct_balance_raw  1543-1552 ///  account balancing difference (negative = disbursements > receipts)
  /* INCOME */ ///
  inc_after_raw     1553-1562 ///  money income after personal taxes, total
  inc_before_raw    1563-1572 ///  money income before personal taxes, total
  wages_raw         1573-1582 ///  wage and salary earnings
  selfemp_raw       1583-1592 ///  self-employment income
  inc_rent_raw      1593-1602 ///  income from rent, roomers, boarders
  inc_invest_raw    1603-1612 ///  interest, dividends, profits from stocks/bonds
  inc_unemps_raw    1613-1622 ///  public unemployment or social security benefits
  inc_pension_raw   1623-1632 ///  private pensions, retirement, insurance annuities
  inc_assist_raw    1633-1642 ///  public social assistance and private relief
  inc_gifts_raw     1643-1652 ///  receipt of cash gifts
  inc_military_raw  1653-1662 ///  military allotments, pensions, etc.
  inc_other_raw     1663-1672 ///  other money income
  pers_taxes_raw    1673-1682 ///  personal taxes (shown as negative)
  oth_money_raw     1683-1692 ///  other money receipts
  nonmoney_raw      1693-1702 ///  value of items received without expense
  homefood_raw      1703-1712 ///  value of home-produced food
  marital_status    1713-1721 ///  marital status of head
  famsize_code      1722-1730 ///  family size code
  fulltime_earn     1731-1739 ///  number of full-time earners
  reason_inc_chg    1740-1748 ///  reason for income change between SY-1 and SY-2 [1740-1749 typo in codebook; checked PG]
  using "$datapath"
  
gen long ms_newid = 999900000 + _n

di "Records loaded: " _N

* Raw-field completeness check: reports only variables that HAVE missing values.
* Currently prints "(variables nonmissing or string)" - i.e. no blank in any of
* the 212 infix fields, all 13,728 records. So any missing downstream is
* CONSTRUCTED by this file (home_value_mid, merge results), never inherited.
misstable summarize

*──────────────────────────────────────────────────────────────────────
* Scaling

* Survey weight (1 implied decimal)
gen weight = weight_raw / 10
drop weight_raw
label variable weight "Survey expansion factor (weight)"

* Household size (1 implied decimal)
gen hhsize = num_persons_raw / 10
drop num_persons_raw
label variable hhsize "Average household size during survey year"

* All dollar variables (2 implied decimal places)
local dollarlist                                                                ///
  exp_total food_total food_home food_away alcohol tobacco                      ///
  housing_total shelter_total rent_dwell owned_total                            ///
  owned_mortg owned_taxes owned_propins owned_repairs owned_other               ///
  vacation_home lodging_out other_reale                                         ///
  bills_total bills_solid bills_gaselec bills_water bills_other                      ///
  hh_ops_total phone hh_svc hh_suppl                                            ///
  furnish_total hh_textiles furn_total                                           ///
  furn_living furn_dining furn_bedroom furn_kitchen floor_cover                  ///
  major_app app_refrig app_washing app_other small_app housewares               ///
  furnish_ins furnish_other                                                      ///
  cloth_total cloth_men cloth_men_out cloth_men_und cloth_men_ft                 ///
  cloth_men_ht cloth_men_oth                                                     ///
  cloth_boy1617 cloth_b17_out cloth_b17_und cloth_b17_ft cloth_b17_ht           ///
  cloth_b17_oth                                                                  ///
  cloth_boy215 cloth_b15_out cloth_b15_und cloth_b15_ft cloth_b15_ht            ///
  cloth_b15_oth                                                                  ///
  cloth_wom cloth_wom_out cloth_wom_und cloth_wom_ft cloth_wom_ht               ///
  cloth_wom_oth                                                                  ///
  cloth_grl1617 cloth_g17_out cloth_g17_und cloth_g17_ft cloth_g17_ht           ///
  cloth_g17_oth                                                                  ///
  cloth_grl215 cloth_g15_out cloth_g15_und cloth_g15_ft cloth_g15_ht            ///
  cloth_g15_oth                                                                  ///
  cloth_under2 cloth_mater cloth_upkeep                                          ///
  transp_total auto_pur auto_ops auto_gas auto_tires auto_unalloc               ///
  auto_repairs auto_ins auto_reg pub_trans                                       ///
  medical med_prepaid med_direct med_hospital med_phys med_dental               ///
  med_eye med_othpract med_drugs med_applia                                      ///
  perscare perscare_svc perscare_sup                                             ///
  recreat recreat_tv recreat_radio recreat_adm recreat_spt recreat_oth          ///
  reading                                                                        ///
  educ educ_tuition educ_books educ_other                                        ///
  misc                                                                           ///
  pers_ins pins_vet pins_group pins_life pins_mutual pins_disab                  ///
  pins_other pins_ss pins_retire                                                 ///
  gifts gifts_pers gifts_orgs                                                    ///
  net_assets net_asschg cash_bank                                                ///
  ass_owndw ass_othprop ass_business ass_stocks ass_personal ass_ins ass_other   ///
  net_liab liab_mortdw liab_mortoth liab_banks liab_auto                         ///
  liab_furnish liab_othgds liab_renttax                                          ///
  acct_balance                                                                   ///
  inc_after inc_before wages selfemp inc_rent inc_invest                         ///
  inc_unemps inc_pension inc_assist inc_gifts inc_military inc_other             ///
  pers_taxes oth_money nonmoney homefood

foreach v of local dollarlist {
    gen double `v' = `v'_raw / 100
    drop `v'_raw
}
	

* Raw-field integrity: negatives across ALL dollar fields, before anything is
* constructed from them. Prints only fields that have negative values, so silence
* means every dollar field in the file is non-negative.
foreach v of local dollarlist {
  quietly count if `v' < 0
  if r(N) > 0 {
	  local nneg = r(N)
	  quietly sum `v'
	  di as txt "`v': " `nneg' " negative, min " %12.2f r(min)
  }
}

* Negative annual food at home has no interpretation, unlike the insurance and
* tax refunds elsewhere in the file. Drop.
count if food_home < 0
di as txt "1960 - negative food_home, dropped: " r(N)
drop if food_home < 0

 *──────────────────────────────────────────────────────────────────────
  * RECONCILIATION SWEEP: every total-vs-components identity in the record.
  * Reports only identities that FAIL, with the number of records and the
  * worst deviation. Tolerance 1 cent. Catches columns read into the wrong
  * variable and component sets that do not exhaust their total.
  capture program drop recon
  program define recon
      syntax varlist(min=2), NAME(string)
      tokenize `varlist'
      local tot `1'
      macro shift
      tempvar s
      gen double `s' = 0
      while "`1'" != "" { 
          quietly replace `s' = `s' + `1'
          macro shift
      }
      tempvar d
      gen double `d' = `tot' - `s'
      quietly count if abs(`d') > 0.01
      local nbad = r(N)
      quietly sum `d'
      if `nbad' > 0 {
          di as err "recon `name': " `nbad' " records fail, dev min " %12.2f r(min) " max " %12.2f r(max)
      }
      else di as txt "recon `name': OK"
  end
  
  * food
  recon food_total food_home food_away, name(food)
  * housing
  * other_reale is inside housing_total but OUTSIDE shelter_total (both verified exact)
  recon housing_total shelter_total other_reale bills_total hh_ops_total furnish_total, name(housing)
  recon shelter_total rent_dwell owned_total vacation_home lodging_out, name(shelter)
  recon owned_total owned_mortg owned_taxes owned_propins owned_repairs owned_other, name(owned)
  recon bills_total bills_solid bills_gaselec bills_water bills_other, name(bills)
  recon hh_ops_total phone hh_svc hh_suppl, name(hh_ops) 
  recon furnish_total hh_textiles furn_total floor_cover major_app small_app housewares furnish_ins furnish_other, name(furnish)
  recon furn_total furn_living furn_dining furn_bedroom furn_kitchen, name(furniture)
  recon major_app app_refrig app_washing app_other, name(major_app)
  * clothing
  recon cloth_total cloth_men cloth_boy1617 cloth_boy215 cloth_wom cloth_grl1617 cloth_grl215 cloth_under2 cloth_mater cloth_upkeep, name(clothing)
  recon cloth_men cloth_men_out cloth_men_und cloth_men_ft cloth_men_ht cloth_men_oth, name(cloth_men)
  recon cloth_boy1617 cloth_b17_out cloth_b17_und cloth_b17_ft cloth_b17_ht cloth_b17_oth, name(cloth_b1617)
  recon cloth_boy215 cloth_b15_out cloth_b15_und cloth_b15_ft cloth_b15_ht cloth_b15_oth, name(cloth_b215)
  recon cloth_wom cloth_wom_out cloth_wom_und cloth_wom_ft cloth_wom_ht cloth_wom_oth, name(cloth_wom)
  recon cloth_grl1617 cloth_g17_out cloth_g17_und cloth_g17_ft cloth_g17_ht cloth_g17_oth, name(cloth_g1617)
  recon cloth_grl215 cloth_g15_out cloth_g15_und cloth_g15_ft cloth_g15_ht cloth_g15_oth, name(cloth_g215)
  * transport
  recon transp_total auto_pur auto_ops pub_trans, name(transport)
  recon auto_ops auto_gas auto_tires auto_unalloc auto_repairs auto_ins auto_reg, name(auto_ops)
  * medical, personal care, recreation, education
  recon medical med_prepaid med_direct, name(medical)
  recon med_direct med_hospital med_phys med_dental med_eye med_othpract med_drugs med_applia, name(med_direct)
  recon perscare perscare_svc perscare_sup, name(perscare)
  recon recreat recreat_tv recreat_radio recreat_adm recreat_spt recreat_oth, name(recreation)
  recon educ educ_tuition educ_books educ_other, name(education)
  * insurance, gifts
  * does not fully reconcile for a small number of records; cause unknown.
  * pers_ins is not used in any bucket.
  recon pers_ins pins_vet pins_group pins_life pins_mutual pins_disab pins_other pins_ss pins_retire, name(pers_ins)
  recon gifts gifts_pers gifts_orgs, name(gifts)
  * assets and liabilities
  recon net_assets net_asschg net_liab, name(net_assets)
  recon net_asschg cash_bank ass_owndw ass_othprop ass_business ass_stocks ass_personal ass_ins ass_other, name(assets)
  recon net_liab liab_mortdw liab_mortoth liab_banks liab_auto liab_furnish liab_othgds liab_renttax, name(liabilities)
  * income
  recon inc_after inc_before pers_taxes, name(inc_after)
  recon inc_before wages selfemp inc_rent inc_invest inc_unemps inc_pension inc_assist inc_gifts inc_military inc_other, name(inc_before)
  * THE ONE THAT SETTLES totexp_cex: what is inside exp_total?
  recon exp_total food_total alcohol tobacco housing_total cloth_total transp_total medical perscare recreat reading educ misc, name(exp_total)

* hh_ops is the one two-sided failure: components sometimes EXCEED the total.
  tempvar d_hhops
  gen double `d_hhops' = hh_ops_total - (phone + hh_svc + hh_suppl)
  count if `d_hhops' < -0.01
  count if `d_hhops' >  0.01
  sum `d_hhops' if abs(`d_hhops') > 0.01, detail
  list cu_number hh_ops_total phone hh_svc hh_suppl if `d_hhops' < -100, clean noobs


*──────────────────────────────────────────────────────────────────────
*Labels

* Demographics
label variable location_size  "Location and size of place (CC-24)"
label variable urbanization   "Urbanization group (CC-48)"
label variable area_class     "Area classification (CC-49)"
label variable smsa_state     "SMSA or state code (CC-25a/25b)"
label variable cu_number      "Consumer unit schedule number"
label variable region           "Region (CC-22c: 1=NE 2=NC 3=S 4=W)"
label variable farm_status      "Farm operator status (CC-50)"
label variable survey_year      "Year of survey (CC-21, last digit: 9=1959 0=1960 1=1961)"
label variable stratum          "Stratum size (CC-23)"
label variable sex_head         "Sex of head (1=male 2=female)"
label variable race_head        "Race of head (1=white 2=negro 3=other)"
label variable educ_code        "Education of head (code, CC-3 second digit)"
label variable educ_yrs         "Education of head (actual years)"
label variable age_code         "Age of head (code, CC-8 first digit)"
label variable age_yrs          "Age of head (actual years)"
label variable occupation       "Occupation of head (3-digit, CC-13a/13b)"
label variable industry         "Industry group, head (CC-14a)"
label variable class_work       "Class of work, head (CC-14b: 1=private 2=govt)"
label variable hhsize           "Average household size during survey year"
label variable num_under18      "Number of persons under 18"
label variable num_65plus       "Number of persons 65 and over"
label variable part_year        "Part-year membership (CC-9a)"
label variable relationship     "Relationship of family members (CC-9b)"
label variable age_children     "Age of children of head (CC-9c)"
label variable num_earners      "Total number of earners (CC-11a)"
label variable earner_comp      "Earner composition (CC-12)"
label variable inc_before_code  "Family income before taxes, bracket code (CC-15a)"
label variable inc_after_code   "Family income after taxes, bracket code (CC-15b)"
label variable inc_chg_sy_sy1   "Income change SY vs SY-1 (CC-17a)"
label variable inc_chg_sy1_sy2  "Income change SY-1 vs SY-2 (CC-17b)"
label variable inc_chg_sy1_sy   "Income change SY+1 vs SY (CC-17c)"
label variable reason_chg_sy_sy1 "Reason for income change SY to SY-1 (CC-18)"
label variable reason_chg_sy1_sy "Reason for income change SY+1 to SY (CC-18)"
label variable housekeeping     "Housekeeping arrangement (CC-33: 1=housekeeping)"
label variable inc_savings_ratio "Income-savings ratio (CC-19)"
label variable tenure_end       "Tenure at end of survey year (CC-29b: 1=owner 2=renter)"
label variable tenure_all       "Tenure all year (CC-29a: 1=owner 2=renter 3=other)"
label variable occ_change       "Change in occupancy status and type of rental (CC-29c)"
label variable yr_home_purch    "Year of home purchase (CC-29d)"
label variable home_value       "Market value of owner-occupied housing, bracket code (CC-30)"
label variable monthly_rent     "Monthly rent paid, bracket code (CC-31)"
label variable num_autos        "Number of autos owned at end of survey year"
label variable weight           "Survey expansion factor (divide raw by 10)"
label variable marital_status   "Marital status of head"
label variable famsize_code     "Family size code"
label variable fulltime_earn    "Number of full-time earners"
label variable reason_inc_chg   "Reason for income change SY-1 to SY-2"

* Expenditures
label variable exp_total        "Total current consumption expenditure ($)"

* Food
label variable food_total       "Food, total ($)"  
label variable food_home        "Food prepared at home ($)" 
label variable food_away        "Food away from home ($)" 
label variable alcohol          "Alcoholic beverages ($)" 
label variable tobacco          "Tobacco ($)" 

* Housing
label variable housing_total    "Housing, total ($)" 
label variable shelter_total    "Shelter, total ($)"  
label variable rent_dwell       "Rented dwelling ($)"   
label variable owned_total      "Owned dwelling, total ($)" 
label variable owned_mortg      "Interest on mortgages ($)"
label variable owned_taxes      "Taxes due in survey year ($)"
label variable owned_propins    "Property insurance ($)"
label variable owned_repairs    "Repairs and replacements ($)"
label variable owned_other      "Other expenses - owned dwelling ($)"
label variable vacation_home    "Owned vacation home, cabin, etc. ($)"
label variable lodging_out      "Lodging out of home city ($)"
label variable other_reale      "Other real estate ($)"

* Bills
label variable bills_total       "Fuel, light, refrigeration and water, total ($)" 
label variable bills_solid       "Solid and petroleum fuels ($)"
label variable bills_gaselec     "Gas and electricity ($)"
label variable bills_water       "Water, sewage, garbage and trash collection ($)"
label variable bills_other       "Ice, water softening, freezer rentals, etc. ($)"

* Household operations
label variable hh_ops_total     "Household operations, total ($)"
label variable phone            "Telephone and telegraph ($)"
label variable hh_svc           "Other household services ($)"
label variable hh_suppl         "Household supplies ($)"

* Furnishings
label variable furnish_total    "Housefurnishings and equipment, total ($)"
label variable hh_textiles      "Household textiles ($)"
label variable furn_total       "Furniture, total ($)"
label variable furn_living      "Furniture - living room ($)"
label variable furn_dining      "Furniture - dining room ($)"
label variable furn_bedroom     "Furniture - bedroom ($)"
label variable furn_kitchen     "Furniture - kitchen, porch, garden, other ($)"
label variable floor_cover      "Floor coverings ($)"
label variable major_app        "Major appliances, total ($)"
label variable app_refrig       "Refrigerators, home freezers ($)"
label variable app_washing      "Washing machines, dryers, combinations ($)"
label variable app_other        "All other major appliances ($)"
label variable small_app        "Small appliances ($)"
label variable housewares       "Housewares, total ($)"
label variable furnish_ins      "Insurance on furnishings, equipment, apparel ($)"
label variable furnish_other    "Other housefurnishings ($)"

* Clothing
label variable cloth_total      "Clothing, total ($)"
label variable cloth_men        "Clothing - men and boys 18+, total ($)"
label variable cloth_men_out    "Clothing - men 18+ outerwear ($)"
label variable cloth_men_und    "Clothing - men 18+ underwear/nightwear/hosiery ($)"
label variable cloth_men_ft     "Clothing - men 18+ footwear ($)"
label variable cloth_men_ht     "Clothing - men 18+ hats/gloves/accessories ($)"
label variable cloth_men_oth    "Clothing - men 18+ not allocated ($)"
label variable cloth_boy1617    "Clothing - boys 16-17 years, total ($)"
label variable cloth_b17_out    "Clothing - boys 16-17 outerwear ($)"
label variable cloth_b17_und    "Clothing - boys 16-17 underwear/nightwear/hosiery ($)"
label variable cloth_b17_ft     "Clothing - boys 16-17 footwear ($)"
label variable cloth_b17_ht     "Clothing - boys 16-17 hats/gloves/accessories ($)"
label variable cloth_b17_oth    "Clothing - boys 16-17 not allocated ($)"
label variable cloth_boy215     "Clothing - boys 2-15 years, total ($)"
label variable cloth_b15_out    "Clothing - boys 2-15 outerwear ($)"
label variable cloth_b15_und    "Clothing - boys 2-15 underwear/nightwear/hosiery ($)"
label variable cloth_b15_ft     "Clothing - boys 2-15 footwear ($)"
label variable cloth_b15_ht     "Clothing - boys 2-15 hats/gloves/accessories ($)"
label variable cloth_b15_oth    "Clothing - boys 2-15 not allocated ($)"
label variable cloth_wom        "Clothing - women and girls 18+, total ($)"
label variable cloth_wom_out    "Clothing - women 18+ outerwear ($)"
label variable cloth_wom_und    "Clothing - women 18+ underwear/nightwear/hosiery ($)"
label variable cloth_wom_ft     "Clothing - women 18+ footwear ($)"
label variable cloth_wom_ht     "Clothing - women 18+ hats/gloves/accessories ($)"
label variable cloth_wom_oth    "Clothing - women 18+ not allocated ($)"
label variable cloth_grl1617    "Clothing - girls 16-17 years, total ($)"
label variable cloth_g17_out    "Clothing - girls 16-17 outerwear ($)"
label variable cloth_g17_und    "Clothing - girls 16-17 underwear/nightwear/hosiery ($)"
label variable cloth_g17_ft     "Clothing - girls 16-17 footwear ($)"
label variable cloth_g17_ht     "Clothing - girls 16-17 hats/gloves/accessories ($)"
label variable cloth_g17_oth    "Clothing - girls 16-17 not allocated ($)"
label variable cloth_grl215     "Clothing - girls 2-15 years, total ($)"
label variable cloth_g15_out    "Clothing - girls 2-15 outerwear ($)"
label variable cloth_g15_und    "Clothing - girls 2-15 underwear/nightwear/hosiery ($)"
label variable cloth_g15_ft     "Clothing - girls 2-15 footwear ($)"
label variable cloth_g15_ht     "Clothing - girls 2-15 hats/gloves/accessories ($)"
label variable cloth_g15_oth    "Clothing - girls 2-15 not allocated ($)"
label variable cloth_under2     "Clothing - children under 2 years ($)"
label variable cloth_mater      "Clothing materials ($)"
label variable cloth_upkeep     "Clothing upkeep ($)"

* Transportation
label variable transp_total     "Transportation, total ($)"
label variable auto_pur         "Automobile purchase ($)"
label variable auto_ops         "Automobile operation, total ($)"
label variable auto_gas         "Gasoline, motor oil, lubrication, washing ($)"
label variable auto_tires       "Tires, tubes, batteries, other equipment ($)"
label variable auto_unalloc     "Auto operating expenses not allocated ($)"
label variable auto_repairs     "Repairs and parts not covered by insurance ($)"
label variable auto_ins         "Automobile insurance ($)"
label variable auto_reg         "Registration and other ($)"
label variable pub_trans        "Public transportation, car pools, other ($)"

* Medical
label variable medical          "Medical care, total ($)"
label variable med_prepaid      "Prepaid care - premiums/health insurance ($)"
label variable med_direct       "Direct medical expenses, total ($)"
label variable med_hospital     "Hospitalized illness ($)"
label variable med_phys         "Physicians' services outside hospital ($)"
label variable med_dental       "Dental services ($)"
label variable med_eye          "Eye care, including glasses ($)"
label variable med_othpract     "Other practitioners ($)"
label variable med_drugs        "Drugs and medicines ($)"
label variable med_applia       "Medical appliances, supplies, other ($)"

* Personal care
label variable perscare         "Personal care, total ($)"
label variable perscare_svc     "Personal care services ($)"
label variable perscare_sup     "Personal care supplies ($)"

* Recreation
label variable recreat          "Recreation, total ($)"
label variable recreat_tv       "Television ($)"
label variable recreat_radio    "Radio, phonographs, musical instruments ($)"
label variable recreat_adm      "Spectator admissions ($)"
label variable recreat_spt      "Participant sports - equipment, fees, dues ($)"
label variable recreat_oth      "Club dues, hobbies, pets, toys, recreation out of city, other ($)"
label variable reading          "Reading ($)"

* Education
label variable educ             "Education, total ($)"
label variable educ_tuition     "Tuition and fees ($)"
label variable educ_books       "School books, supplies, equipment ($)"
label variable educ_other       "Music and other special lessons, other ($)"
label variable misc             "Miscellaneous personal consumption ($)"

* Personal insurance
label variable pers_ins         "Personal insurance, total ($)"
label variable pins_vet         "Life/endowment/annuity - veterans ($)"
label variable pins_group       "Life/endowment/annuity - group, deducted from pay ($)"
label variable pins_life        "Life/endowment/annuity - other ($)"
label variable pins_mutual      "Mutual aid ($)"
label variable pins_disab       "Disability income insurance ($)"
label variable pins_other       "Other personal insurance ($)"
label variable pins_ss          "Social Security, railroad and government retirement ($)"
label variable pins_retire      "Private retirement ($)"

* Gifts
label variable gifts            "Gifts and contributions, total ($)"
label variable gifts_pers       "Gifts to persons not in consumer unit ($)"
label variable gifts_orgs       "Gifts to organizations ($)"

* Assets and liabilities
label variable net_assets       "Net change in assets and liabilities ($)"
label variable net_asschg       "Net change in assets ($)"
label variable cash_bank        "Cash in bank, on hand, money owed to family ($)"
label variable ass_owndw        "Purchase/improvement/sale of own dwelling ($)"
label variable ass_othprop      "Other real property ($)"
label variable ass_business     "Investment in business ($)"
label variable ass_stocks       "Stocks and bonds ($)"
label variable ass_personal     "Sale of personal property ($)"
label variable ass_ins          "Settlement or surrender of insurance policies ($)"
label variable ass_other        "Other assets ($)"
label variable net_liab         "Net change in liabilities ($)"
label variable liab_mortdw      "Mortgage on own dwelling ($)"
label variable liab_mortoth     "Mortgage on other real property ($)"
label variable liab_banks       "Money owed to banks, insurance companies ($)"
label variable liab_auto        "Money owed on automobile purchase ($)"
label variable liab_furnish     "Money owed on housefurnishings and equipment ($)"
label variable liab_othgds      "Money owed on other goods and services ($)"
label variable liab_renttax     "Money owed on rent, taxes, other liabilities ($)"
label variable acct_balance     "Account balancing difference ($)"

* Income
label variable inc_after        "Money income after personal taxes ($)"
label variable inc_before       "Money income before personal taxes ($)"
label variable wages            "Wage and salary earnings ($)"
label variable selfemp          "Self-employment income ($)"
label variable inc_rent         "Income from rent, roomers, boarders ($)"
label variable inc_invest       "Interest, dividends, profits from stocks/bonds ($)"
label variable inc_unemps       "Public unemployment or Social Security benefits ($)"
label variable inc_pension      "Private pensions, retirement, insurance annuities ($)"
label variable inc_assist       "Public social assistance and private relief ($)"
label variable inc_gifts        "Receipt of cash gifts ($)"
label variable inc_military     "Military allotments, pensions, etc. ($)"
label variable inc_other        "Other money income ($)"
label variable pers_taxes       "Personal taxes - negative value ($)"
label variable oth_money        "Other money receipts ($)"
label variable nonmoney         "Value of items received without expense ($)"
label variable homefood         "Value of home-produced food ($)"


* No raw exp_total screen: the sample is cut on totexp_clm (see below), the
* measure the moments are built on, and 2010 has no raw screen either. Counted
* but not dropped here, since exp_total also feeds totexp_cex.
count if missing(exp_total) | exp_total <= 0
di as txt "1960 - raw exp_total missing or <= 0 (not dropped): " r(N)
di as txt "Observations at this point: " _N


*_____________________________________________________________________
* We take the variable vehicle service flow from Meyer & Sullivan (2023)

preserve
    use "$data/all_cons_data_for_stata_80_17.dta", clear
    drop if ref_year != 1961
    keep fincbtax fincatax sex_ref locat region age_ref n_tot_vflow1 newid
    rename fincatax     inc_after
    rename fincbtax     inc_before
    rename sex_ref      sex_head
    rename locat        location_size
    rename age_ref      age_yrs
    rename n_tot_vflow1 vehicle_flow

    replace inc_after  = round(inc_after,  0.01)
    replace inc_before = round(inc_before, 0.01)
    gen long inc_after_l  = round(inc_after  * 100)
    gen long inc_before_l = round(inc_before * 100)
    foreach v in inc_after inc_before sex_head location_size age_yrs region {
        gen double temp = `v'
        drop `v'
        rename temp `v'
    }
    save "$data1960/ms_cleaned.dta", replace
restore

replace inc_after  = round(inc_after,  0.01)
replace inc_before = round(inc_before, 0.01)
gen long inc_after_l  = round(inc_after  * 100)
gen long inc_before_l = round(inc_before * 100)
foreach v in inc_after inc_before sex_head location_size age_yrs region {
    gen double temp = `v'
    drop `v'
    rename temp `v'
}

merge 1:1 inc_after_l inc_before_l sex_head location_size age_yrs region ///
      using "$data1960/ms_cleaned.dta", keep(master match) keepusing(vehicle_flow newid)
count if ms_newid != newid
assert ms_newid == newid
	  
* match-rate check
tab _merge
assert !missing(vehicle_flow)
* Put 1959 and 1960 records in 1961 prices, following MS (CPI-U).
* Codes: 9 = 1959, 0 = 1960, 1 = 1961. Applied after the MS merge, whose key
* uses nominal income.
gen double pfac = 1
replace pfac = 1.028  if survey_year == 9
replace pfac = 1.0098 if survey_year == 0
foreach v of local dollarlist {
  replace `v' = `v' * pfac
}
* MS deflate at the aggregate level; the stored flow is own-year nominal.
replace vehicle_flow = vehicle_flow * pfac
sum vehicle_flow, detail
drop _merge
label var vehicle_flow "MS imputed automobile service flow ($)"

*──────────────────────────────────────────────────────────────────────
* We impute rent for owners using Davis et al. rent-price ratio (5.6%)

tab tenure_end, missing      // col 49 codes: only 1/2, or is there a third category?

* house-value bracket midpoints: closed brackets are true midpoints in both
* our version and MS's; the two open-ended ends are judgment calls.
* ms_ends 0 = ours (2500 / 60000), 1 = MS (3500 / 65000)
local ms_ends 1

gen home_value_mid = .
replace home_value_mid = cond(`ms_ends', 3500, 2500)   if home_value == 10
replace home_value_mid = 7500  if home_value == 20
replace home_value_mid = 11250 if home_value == 31
replace home_value_mid = 13750 if home_value == 32
replace home_value_mid = 16250 if home_value == 41
replace home_value_mid = 18750 if home_value == 42
replace home_value_mid = 21250 if home_value == 51
replace home_value_mid = 23750 if home_value == 52
replace home_value_mid = 30000 if home_value == 60
replace home_value_mid = 42500 if home_value == 71
replace home_value_mid = cond(`ms_ends', 65000, 60000) if home_value == 72

* Reported market value is own-year nominal, like the expenditure fields.
replace home_value_mid = home_value_mid * pfac

gen imputed_rent = home_value_mid * 0.056 if tenure_end == 1
replace imputed_rent = 0 if missing(imputed_rent)

label variable home_value_mid "Midpoint of home value bracket ($)"
label variable imputed_rent   "Imputed annual rent for owners (Davis 5.6%)"

*compare distributions of real vs imputed rents

tabstat rent_dwell   if tenure_end == 2 & rent_dwell > 0,        stat(mean median sd min p10 p25 p75 p90 max)
tabstat imputed_rent if tenure_end == 1 & !missing(imputed_rent), stat(mean median sd min p10 p25 p75 p90 max)

* 42 owners have missing home value (code 99) - dropped for now
drop if tenure_end == 1 & missing(home_value_mid)

*──────────────────────────────────────────────────────────────────────
* CLM CLASSIFICATION (Comin-Lashkari-Mestieri, ECMA 2021) 
*   Built to reproduce, as closely as the 1960 CEX allows, the original Aguiar-Bils (2015) 
*   (lines 408-438 and 754-762 from their original SAS data cleaning file) intermediate categories
*   and the CLM (ECMA 2021) macro buckets.

* Intermediate aggregates

* VEHPCH = cartkn + cartku + othveh + vehfin + vrntlo + vehins (2010)
*   where MS substitute cartkn + cartku + othveh + vehfin with vehicle flow
gen double vehpch_ab = vehicle_flow + auto_ins + auto_reg
* We adopt the MS framework and replace automobile purchases with the imputed service flow;
*    auto registration is also placed here.

* VEHOPR = gasmo + mainrp (2010)
* Start from the transport block total so the unallocated remainder is kept;
* auto purchases are replaced by the MS flow, insurance and registration move
* to vehpch_ab.
gen double vehopr_ab = transp_total - auto_pur - pub_trans - auto_ins - auto_reg

* OPPUB = vehopr + pubtra (2010)
gen double oppub_ab = vehopr_ab + pub_trans
label var  oppub_ab "AB operations + public transit"

* ADULTCL = mensix + womsix (2010)
* we put chloting for 16-17 years old here since MENSIX is defined as "Men, 16 and over".
* Built from the clothing block total less the pieces routed to chldrn_ab and
* shoesoth_ab, so the unallocated remainder is kept. All three are goods.
gen double adultcl_ab = cloth_total - cloth_boy215 - cloth_grl215 - cloth_under2 ///
					- cloth_mater - cloth_upkeep
label var  adultcl_ab "AB adult clothing"

* CHLDRN = boyfif + grlfif + chldrn (2010)
gen double chldrn_ab = cloth_boy215 + cloth_grl215 + cloth_under2
label var  chldrn_ab "AB children's clothing"

* SHOESOTH = footwr + othapl (2010)
*  no separate footwear line; we put clothing materials and upkeep here.
gen double shoesoth_ab = cloth_mater + cloth_upkeep
label var  shoesoth_ab "AB footwear/other apparel proxy"

* FURNSH = textil + furntr + flrcvr (2010)
  *    add "other housefurnishings" (furnish_other) -- a furnishing good.
  *    furnish_ins (contents insurance) EXCLUDED to match AB: insurance is not a goods item, and
  *    AB drop owner contents ins with the owned dwelling (renter's ins they keep in shelter).
gen double furnsh_ab = furnish_total - furnish_ins - major_app - small_app - housewares
label var  furnsh_ab "AB furnishings"

* EQUPMT = majapp + smlapp + misceq + teleph (2010)
*    we add "housewares" here
*    even if not explicitely present in the original AB categorization 
*    as a proxy for hh misceq.
* gen double equpmt_ab = major_app + small_app + housewares + hh_suppl + phone   // v1: supplies IN
gen double equpmt_ab = major_app + small_app + housewares + phone                 // v2: supplies OUT
label var  equpmt_ab "AB equipment"

* UTIL = ntlgas + elctrc + fuloil + othfls + watrps (util - teleph) (2010)
* Use the block total: its components can leave an unallocated remainder, and
* nothing in this block is excluded.
gen double util_ab = bills_total
label var  util_ab "AB utilities"

* SHELT = rendwe + othlod + imputed rent (2010); 1960 othlod = lodging_out + vacation_home.
*    other_reale (outlays on property not occupied or rented) EXCLUDED to match AB/CLM/2010,
*    which have no other-real-estate category -- it's investment, not consumption.
gen double shelt_ab = rent_dwell + lodging_out + vacation_home + imputed_rent
label var  shelt_ab "AB shelter"

* FEEARD = feeadm + read (2010)
gen double feeard_ab = recreat_adm + reading
label var  feeard_ab "AB fees/admissions + reading"

 * TVRDOT = tvrdio + otheqp (2010)
* Use the block total less admissions, which goes to feeard_ab: the recreation
* components can leave an unallocated remainder, and nothing else is excluded.
gen double tvrdot_ab = recreat - recreat_adm

label var  tvrdot_ab "AB entertainment"

* HOUSOP = dmsxcc + bbyday  (domestic service + babysitting/day care) (2010)
* 1960 identity: housop = hh_svc (other household services). Used directly below.

* HEALTH = health (2010)
* 1960 identity: health = medical. Used directly below.

* PERSCA = persca (2010)
* 1960 identity: persca = perscare. Used directly below.

* EDUCA = educa (2010)
* 1960 identity: educa = educ. Used directly below.

* TOBACC = tobacc (2010)
* 1960 identity: tobacc = tobacco. Used directly below.

* ALCBEV = alcbev (2010)
* 1960 identity: alcbev = alcohol. Used directly below.

* FDHOME = fdhome (2010)
* 1960 identity: fdhome = food_home. Used directly below.

* FDAWAY = fdaway (2010)
* 1960 identity: fdaway = food_away. Used directly below.

* Cash contributions = ORGANIZATIONS ONLY, both years (charities/religious/educ/political).
* 1960: gifts_orgs.  2010: cashco_adj with cc_keep = the 4 org UCCs (see 2010_clean.do).
* Excludes alimony/child/college + gifts to persons + securities (1960 has no separate
*   lines for these, so gifts_pers is dropped). Used directly below.


* there are some excluded subcategories:
*   owned_total (from 1960 housing), since we follow the imputed rent structure;
*   hh_suppl (from 1960 hh operations), since AB leaves out OTHHEX;
         
* there are also some categories that are entirely excluded:
*   pers_ins, misc, explicitely excluded by choice in 2010 AB.

* Buckets built as block total less exclusions go negative when a record's
* components exceed its own total. Report before deciding.
foreach v in vehpch_ab vehopr_ab oppub_ab adultcl_ab chldrn_ab shoesoth_ab ///
		   furnsh_ab equpmt_ab util_ab shelt_ab feeard_ab tvrdot_ab {
  quietly count if `v' < 0
  if r(N) > 0 {
	  local nneg = r(N)
	  quietly sum `v'
	  di as txt "negative `v': " `nneg' ", min " %12.2f r(min)
  }
}

* A bucket built as block total less exclusions can only go negative if a
* record's components exceed its own total, i.e. the record contradicts itself.
* Tolerance of one cent so subtraction rounding does not trigger it.
count if adultcl_ab < -0.01 | furnsh_ab < -0.01 | tvrdot_ab < -0.01 | vehopr_ab < -0.01
di as txt "1960 - self-contradicting records, dropped: " r(N)
drop if adultcl_ab < -0.01 | furnsh_ab < -0.01 | tvrdot_ab < -0.01 | vehopr_ab < -0.01



* CLM macro categories

* Agriculture: food at home
*gen double agric_clm = food_home + alcohol + 1
replace homefood = 0 if missing(homefood)
gen double agric_clm = food_home + homefood + alcohol //+ 1
label var  agric_clm "CLM: agriculture"

* Manufacturing
gen double manuf_clm = vehpch_ab     ///  vehicle flow
                     + oppub_ab      ///  vehicle operations + public transit
                     + adultcl_ab    ///  adult clothing
                     + shoesoth_ab   ///  footwear / other apparel proxy
                     + furnsh_ab     ///  furnishings
                     + equpmt_ab     ///  equipment 
                     + chldrn_ab     ///  children's clothing
                     + perscare      ///  persca
                     + tobacco       //  tobacc
                     //+ 1
label var manuf_clm "CLM: manufactured goods"

* Services
gen double serv_clm  = shelt_ab      ///  shelter 
                     + util_ab       ///  utilities
                     + hh_svc        ///  housop
                     + medical       ///  health
                     + feeard_ab     ///  fees/admissions + reading
                     + tvrdot_ab     ///  entertainment
                     + educ          ///  educa
                     + gifts_orgs    ///  cashco proxy 
                     + food_away     //  fdaway
                     //+ 1
label var serv_clm "CLM: services"

gen double totexp_clm = agric_clm + manuf_clm + serv_clm


* Coverage check: every dollar of the file's own current-consumption total is
* either in totexp_clm or on the exclusion list below. Additions from outside
* exp_total: home-produced food, vehicle service flow, imputed rent, contributions to orgs.
* Exclusions: auto purchases, owned dwelling, other real estate, miscellaneous,
* insurance on furnishings, and household supplies (the household-operations
* block is replaced by phone + services).
gen double check_clm = exp_total + homefood + vehicle_flow + imputed_rent + gifts_orgs ///
				   - auto_pur - owned_total - other_reale - misc - furnish_ins ///
				   - hh_ops_total + phone + hh_svc
gen double d_clm = totexp_clm - check_clm
count if abs(d_clm) > 0.10
di as txt "1960 - coverage check failures: " r(N)
assert abs(d_clm) <= 0.10
drop check_clm d_clm




* CLM-total zero-expenditure screen (replaces the +1 guards).
* NB Stata treats missing as +inf, so `<= 0` alone would KEEP a missing total
* (any missing component -> missing total -> missing shares).
count if missing(totexp_clm)
di as txt "CLM total missing (some component missing): " r(N)
drop if totexp_clm <= 0 | missing(totexp_clm)
  
gen double share_agric_clm = agric_clm / totexp_clm
gen double share_manuf_clm = manuf_clm / totexp_clm
gen double share_serv_clm  = serv_clm  / totexp_clm

label var totexp_clm       "CLM: total expenditure"
label var share_agric_clm  "CLM share: food at home / CLM total"
label var share_manuf_clm  "CLM share: manufactured goods / CLM total"
label var share_serv_clm   "CLM share: services / CLM total"

* Negative sector aggregates -> shares outside [0,1]. Report before deciding.
count if agric_clm < 0
count if manuf_clm < 0
count if serv_clm  < 0
count if share_agric_clm < 0 | share_agric_clm > 1
count if share_manuf_clm < 0 | share_manuf_clm > 1
count if share_serv_clm  < 0 | share_serv_clm  > 1


* Sanity check
sum agric_clm manuf_clm serv_clm totexp_clm
sum share_agric_clm share_manuf_clm share_serv_clm

*──────────────────────────────────────────────────────────────────────
* pre-tax-and-transfer income
* we include: wages + self-employment + business&farm income
* we exclude: rental income (inc_rent) and imputed rent, 
*             investment income (inc_invest),
*             all transfers (inc_unemps, inc_pension, inc_assist, inc_gifts, 
*             inc_military, inc_other) and taxes (pers_taxes)

gen inc_pre = wages + selfemp
label variable inc_pre "Pre-tax-and-transfer income: wages + self-employment ($)"

* post-tax-and-transfer income (pers_taxes is negative)
gen double inc_post_tax_tr = inc_pre + pers_taxes + inc_assist
label variable inc_post_tax_tr "Post-tax-and-transfer income ($)"

 * age restriction
keep if inrange(age_yrs, 25, 60)

*──────────────────────────────────────────────────────────────────────
* cutoff/median ratio, imported from 2010_clean.do (RUN 2010 BEFORE 1960)
do "$cleanoutput/ratio_2010.do"
assert ratio_2010 > 0 & ratio_2010 < 1


* apply ratio and median BEFORE the cut
_pctile inc_pre [pw=weight], p(50)
scalar med_inc_1960 = r(r1)
scalar threshold_1960 = ratio_2010 * med_inc_1960
di as txt "1960 minimum income (cutoff): " %8.1f threshold_1960 " (1960 dollars)"
di as txt "                             ~ " %8.0f threshold_1960*8.1 " (2016 dollars)"

* apply the cut
gen byte below_thr = (inc_pre < threshold_1960)
sum below_thr [aw=weight]
di as txt "Weighted share below threshold: " r(mean)
drop if below_thr == 1
drop below_thr
di as txt "Observations remaining: " _N

*income distribution check

count if inc_pre <= 0
count if inc_pre > 0 & inc_pre < 1000
sum inc_pre inc_post_tax_tr [aw=weight], detail
sum pers_taxes inc_assist [aw=weight]
count if missing(inc_post_tax_tr)

*──────────────────────────────────────────────────────────────────────
* Equivalization: Oxford OECD (1 / 0.7 / 0.5), under-18 proxy for under-14

gen double n_child = num_under18
*gen double n_adult = hhsize - num_under18
gen double n_adult = round(hhsize) - num_under18
replace    n_adult = 0 if n_adult < 0          // part-year CUs: round(annual-avg hhsize) < point-in-time num_under18

gen double eqsc_oecd = 1 + 0.7*max(n_adult-1,0) + 0.5*n_child
replace    eqsc_oecd = 1 if eqsc_oecd < 1
label var  eqsc_oecd "Oxford OECD equivalence factor (under-18 proxy)"

gen double exp_clm_oecd = totexp_clm / eqsc_oecd
label var  exp_clm_oecd "Equivalized CLM expenditure, Oxford OECD ($)"

* CEX total-expenditure measure: raw total current consumption, with auto
* purchases replaced by the MS service flow and owned-dwelling outlays
* * replaced by imputed rent. No other CLM exclusions.
* gen double totexp_cex = exp_total - auto_pur - owned_total ///
*                       + vehicle_flow + imputed_rent
* replaced by imputed rent, plus home-produced food. No other CLM exclusions.
gen double totexp_cex = exp_total - auto_pur - owned_total ///
                      + vehicle_flow + imputed_rent + homefood
					  
count if totexp_cex <= 0
					  
gen double exp_cex_oecd = totexp_cex / eqsc_oecd
label var  totexp_cex   "CEX total expenditure, vehicle flow + imputed rent ($)"
label var  exp_cex_oecd "Equivalized CEX total expenditure, Oxford OECD ($)"

sum totexp_clm totexp_cex [aw=weight]

*──────────────────────────────────────────────────────────────────────
* Tax function

gen log_inc_pre = log(inc_pre)

* Guard: post-tax-and-transfer income can be <= 0 (taxes are assessed on TOTAL
* income incl. capital, while inc_pre = wages + selfemp only). log() of those
* is missing, so reg would silently drop exactly the high-tax units.
gen byte taxreg_ok = (inc_post_tax_tr > 0 & !missing(inc_post_tax_tr))
count if taxreg_ok == 0
di as txt "Dropped from tax regression (post-tax-and-transfer income <= 0 or missing): " r(N) " of " _N
label var taxreg_ok "In tax-regression sample (inc_post_tax_tr > 0)"

gen log_inc_post_tax_tr = log(inc_post_tax_tr) if taxreg_ok

reg log_inc_post_tax_tr log_inc_pre if taxreg_ok [aw=weight]

* save HSV tax-function parameters (slope = 1-tau, cons = log lambda)
capture postclose taxparams
postfile taxparams double(slope se_slope cons nobs r2) using "$cleanoutput/tax_params_1960.dta", replace
post taxparams (_b[log_inc_pre]) (_se[log_inc_pre]) (_b[_cons]) (e(N)) (e(r2))
postclose taxparams


*──────────────────────────────────────────────────────────────────────
* OUTPUT TABLES

capture postclose moments
postfile moments str10 measure ///
    double(mean var sd p10 p25 p50 p75 p90 nobs) ///
    using "$cleanoutput/log_moments_1960.dta", replace

capture postclose shares
postfile shares str4 sector byte quintile ///
    double(agg_share mean_share var_share) long nobs ///
    using "$cleanoutput/shares_moments_1960.dta", replace

* log-expenditure moments
capture program drop post_moments
program define post_moments
    args expvar wvar tag
    tempvar le
    quietly gen double `le' = log(`expvar') if `expvar' > 0
    quietly sum `le' [aw=`wvar'], detail
    post moments ("`tag'") (r(mean)) (r(Var)) (r(sd)) ///
                 (r(p10)) (r(p25)) (r(p50)) (r(p75)) (r(p90)) (r(N))
end

post_moments exp_clm_oecd     weight clm_tot
post_moments exp_cex_oecd weight cex_tot
post_moments inc_pre     weight inc_pre   


* sectoral share moments: aggregate (grp 0) and by quintile
gen double sh_food = agric_clm / totexp_clm
gen double sh_good = manuf_clm / totexp_clm
gen double sh_serv = serv_clm  / totexp_clm

xtile qexp = exp_clm_oecd [aw=weight], nq(5)

foreach grp in 0 1 2 3 4 5 {
    foreach sec in food good serv {
        if "`sec'"=="food" local catv agric_clm
        if "`sec'"=="good" local catv manuf_clm
        if "`sec'"=="serv" local catv serv_clm

        local ifq
        if `grp'>0 local ifq if qexp==`grp'

        quietly sum sh_`sec' [aw=weight] `ifq', detail
        local m = r(mean)
        local v = r(Var)
        local n = r(N)
        quietly sum `catv'     [aw=weight] `ifq'
        local mc = r(mean)
        quietly sum totexp_clm [aw=weight] `ifq'
        local mt = r(mean)
        post shares ("`sec'") (`grp') (`mc'/`mt') (`m') (`v') (`n')
    }
}

postclose moments
postclose shares

preserve
    use "$cleanoutput/log_moments_1960.dta", clear
    list, noobs clean
restore
preserve
    use "$cleanoutput/shares_moments_1960.dta", clear
    list, noobs clean
restore

*──────────────────────────────────────────────────────────────────────

compress
save "$data1960/cex_1960_clean.dta", replace
di "Saved: cex_1960_clean.dta  (N=" _N ")"
