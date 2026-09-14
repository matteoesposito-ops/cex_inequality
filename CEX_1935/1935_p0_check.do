*===============================================================
* 1935 expenditure categories check
*   (a) parent == sum(children)  for each category 
*   (b) constructed total = sum of ALL but EXCLUSIVELY the parents
* Run on RAW appended pt3+pt4 (variables still named V1..Vn).
* NOTE: ICPSR .dta already applied implied decimals (values in $).
*       $-expense lines are blank-when-zero (no all-9s MD codes), so
*       rowtotal()'s treat-missing-as-0 is correct here.
*===============================================================
clear all
set more off
do "../globalpaths.do"

tempfile p3 p4
use "$data1935/08908-0003-Data.dta", clear
gen byte _part=3
save `p3'
use "$data1935/08908-0004-Data.dta", clear
gen byte _part=4 
append using `p3'

*───────────────────────────────────────────────────────────────────────
*--- (a) parent vs sum-of-children reconciliation -----------------
* program: compare a recorded parent V to the sum of its children Vs
capture program drop _recon
program define _recon
    args parent label          // `label' just for display; children in $kids
    tempvar s d
    egen double `s' = rowtotal($kids)
    gen  double `d' = `parent' - `s'
    quietly count if abs(`d') > 0.005 & !missing(`parent')
    local nbad = r(N)
    quietly summarize `d' if !missing(`parent'), detail
    di as txt %-28s "`label'" ///
       "  mismatches=" as res %4.0f `nbad' ///
       as txt "  max|diff|=" as res %8.2f max(abs(r(min)),abs(r(max)))
    drop `s' `d'
end

di _n as txt "{hline 60}"
di as txt "PARENT = SUM(CHILDREN) reconciliation   (diff should be ~0)"
di as txt "{hline 60}"

* --- verified children ( mismatches = rounding) ---

global kids "V1074 V1075 V1076"
_recon V1077 "Food (1074+75+76)"

global kids "V833 V834 V835 V836"
_recon V837  "Education (6-9)"
* but we use the total

global kids "V853 V854 V855 V856 V857 V858 V859"
_recon V860  "Gifts/welfare/taxes (1-7)"

global kids "V1255 V1256 V1257 V1258 V1259 V1260 V1261"
_recon V1262 "Transport (1-6)"

global kids "V1114 V1135 V1136 V1138 V1139 V1140 V1141 V1142 V1143 V1144 V1145 V1146"
_recon V1147 "Automobile (7,16,17-26)"

global kids "V642 V646 V648 V650 V653 V657 V661 V665 V669 V673 V675 V677 V679 V681 V683 V685"
_recon V686  "Medical care"
* but we use the total

global kids "V1267 V1271 V1275 V1279 V1282 V1283 V1284 V1285 V1286 V1287"
_recon V1290 "Personal care"
* but we use the total

global kids "V559 V621 V638"
_recon V639  "Household operations (= fuel+help+other)"

* to summarize housing:
*   Rent (primary + other):
*     V359 V360  total rent
*     V361 V362  repairs on rented dwelling
*     V363 V364  renter total expenses  = contains V359-V362 (rent + repairs)
*   Owned dwellings:
*     V393 V394  total owned-dwelling expenses (outlays)
*   Family housing total:
*     V395 V396  = contains V393 V394 + V363 V364  (owner + renter)
*                  NOTE: V399 is a "fake" total.
*   Vacation & school:
*     V385  owned vacation home expenses
*     V386  rent & repairs, vacation home
*     V387  other lodging
*     V388  rent at school
*     V397  = contains V385-V387
gen double owned_dwelling = V391 + V392
global kids "V393 V394"
_recon owned_dwelling

global kids "V385 V386 V387"
_recon V397 "Vacation expenses"

gen double housing_total = V395 + V396
global kids "V363 V364 V393 V394"
_recon housing_total "Housing"

* --- parents not well unpacked yet ---
*   Clothing                  V1254

* we don't plan to unpack the following parents at the moment
*   Furnishings & equipment   V1333
*   Recreation                V789
*   Tobacco                   V798
*   Reading                   V812

*───────────────────────────────────────────────────────────────────────
* test V285 (pretax total income)
* from codebook: "Total Income of family for the           
*           schedule year. For urban families this should equal the             
*           total of V11, V121, V131, V141, V151, V161, V171, V181,             
*           V191, V194, V196, and V198-V203. for village income                 
*           schedules this should equal the total of V193, V206, and            
*           V284. For farm families this should equal the total of V192,        
*           V206, V234, and V284 less V247.                                     
*                                                                              
*          Users should note that, because of editorial changes on the         
*           original schedules, this variable does not always equal the         
*           sum of its parts.  ICPSR attempted, whenever possible, to           
*           retain the original amount entered on the schedules."
*
*  1. Dollar vars are FLOAT. Sentinels (all-9s at each field's width:
*     999.99 / 9999.99 / 99999.99) MUST be stripped via round(x*100) integer
*     comparison.
*  2. median residual = 0
*       urban  : per-member + V194 + V196 + V198..V203
*       village: V193 + V206 + V284
*       farm   : V192 + V206 + V234 + V284 - V247
*     Mismatches (~3-40%).

capture program drop _clean
program define _clean
    args new old
    gen double `new' = cond(missing(`old') | ///
        inlist(round(`old'*100), 99999, 999999, 9999999), 0, `old')
end

							   
capture drop c_*
_clean c_111 V111
_clean c_121 V121
_clean c_131 V131
_clean c_141 V141
_clean c_151 V151
_clean c_161 V161
_clean c_171 V171
_clean c_181 V181
_clean c_191 V191
_clean c_194 V194
_clean c_196 V196
_clean c_198 V198
_clean c_199 V199
_clean c_200 V200
_clean c_201 V201
_clean c_202 V202
_clean c_203 V203
_clean c_192 V192
_clean c_193 V193
_clean c_206 V206
_clean c_234 V234
_clean c_247 V247
_clean c_284 V284

egen double _permember = rowtotal(c_111 c_121 c_131 c_141 c_151 c_161 c_171 c_181 c_191)

* ---- URBAN: V285 = per-member + V194 + V196 + V198..V203 ----
capture drop f_urban d_urban
gen double f_urban = _permember + c_194 + c_196 + c_198 + c_199 + c_200 + c_201 + c_202 + c_203
gen double d_urban = V285 - f_urban if V14==1
count if abs(d_urban)>0.005 & !missing(d_urban)
sum d_urban, detail

* ---- VILLAGE: V285 = V193 + V206 + V284 ----
capture drop f_vill d_vill
gen double f_vill = c_193 + c_206 + c_284
gen double d_vill = V285 - f_vill if V14==2
count if abs(d_vill)>0.005 & !missing(d_vill)
sum d_vill, detail

* ---- FARM: V285 = V192 + V206 + V234 + V284 - V247 ----
capture drop f_farm d_farm
gen double f_farm = c_192 + c_206 + c_234 + c_284 - c_247
gen double d_farm = V285 - f_farm if V14==3
count if abs(d_farm)>0.005 & !missing(d_farm)
sum d_farm, detail

tabstat _permember c_192 c_193, by(V14) stat(mean p50 max n) col(stat)

* The previous table is strong evidence that the three variables  overlap, 
* even though from the codebook comment they appear to be disjoint

*───────────────────────────────────────────────────────────────────────
*--- (b) constructed total = sum of all the parents ----
* consumption parents only: excludes occupational expenses (V850), the tax line
* inside gifts (V858), other-family-expense financial items (V1341),
* and debt change (V1403/04).                            *** VERIFY exclusions

gen double housop_parent = V621 + V638    // help + other  (= V639 - V559)
gen double gifts_excl_tax = V853+V854+V855+V856+V857+V859   // drop taxes V858

egen double total_exp_parents = rowtotal(  ///
      V395          ///  housing
      V559          ///  fuel/light/refrigeration
      housop_parent ///  household operations EXCL. fuel  (avoids V639⊃V559)
      V686          ///  medical (incl. health insurance V683)
      V789          ///  recreation
      V798          ///  tobacco
      V812          ///  reading
      V837          ///  education
      V1077         ///  food
      V1147         ///  automobile
      V1254         ///  clothing
      V1262         ///  travel & transportation
      V1290         ///  personal care
      V1333         ///  furnishings & equipment
      gifts_excl_tax )
label var total_exp_parents "Constructed total expenditure (sum of consumption parents)"

summarize total_exp_parents, detail
