For this 2010 study we combine three ICPSR releases: 29984 (2009), 32483 (2010), and 34441 (2011). The download contains several groups of files covering different aspects of the Interview Survey. We restrict attention to the Family Characteristics and Income (FMLY) files, which are the household-level summary files. We use 11 quarterly Stata files in total: fmli092 through fmli094 (2009Q2-Q4), fmli101x through fmli104 (2010Q1-Q4), and fmli111 through fmli114 (2011Q1-Q4). The 2009Q1 and 2012Q1 files are excluded because their interviews contain no reference months in calendar 2010. Each file has roughly 7,000 consumer units (CUs) and 896 variables. We extend the sample backward and forward beyond the four 2010 quarters in order to keep every household with at least one reference month in calendar 2010: because each interview reports the three months prior to itself, a CU whose 5th interview is in (say) Feb 2010 has its first interview as early as May 2009, while a CU whose 5th interview is in Dec 2011 has its first interview as recent as Mar 2010. Including the 2009Q2-Q4 and 2011Q1-Q4 files captures both ends of this rolling window. The documentation is split into two PDFs: the User's Guide (Interview_User_s_documentation_-_2010.pdf) covers sample design, weighting, and annualization; the Data Dictionary (Interview_Data_Dictionary.pdf) lists every variable with its composition. We use the Data Dictionary up to page 121, which covers the full FMLY section (FSUM, Summary Expenditure Data). We use the FMLY file because it already contains household-level summary expenditure variables aggregated by BLS using the official Universal Classification Code (UCC) groupings.

---

The unit of observation in 2010 is the consumer unit. The definition is given on page 101 (Appendix 1) of the user's documentation:

Consumer unit  (CU):

A consumer unit comprises either: (1) all members of a particular household who are related by 
blood, marriage, adoption, or other legal arrangements; (2) a person living alone or sharing a 
household with others or living as a roomer in a private home or lodging house or in permanent living 
quarters in a hotel or motel, but who is financially independent; or (3) two or more persons living 
together who use their income to make joint expenditures.  Financial independence is determined by 
the three major expense categories: housing, food, and other living expenses.  To be considered 
financially independent, at least two of the three major expense categories have to be provided 
entirely or in part by the respondent.

Reference person:

The first member mentioned by the respondent when asked to "Start with the name of the person or 
one of the persons who owns or rents the home."  It is with respect to this person that the relationship 
of other CU members is determined. 

---

The 2010 CEX Interview Survey is a rotating panel. Each CU is interviewed up to five times overfifteen months, once per quarter. The first interview is a bounding interview and produces no expenditure data; interviews 2-5 each ask about the previous three months of spending. Because reference periods straddle calendar boundaries, capturing all calendar-year 2010 expenditure requires five quarter files: the four 2010 quarters (fmli101x through fmli104) plus the first quarter of 2011 (fmli111), which collects late-2010 spending reported by CUs interviewed in Jan-Mar 2011. Each interview's reference period is split into two pieces on the file: PQ ("previous quarter") and CQ ("current quarter"), where "current" is the calendar quarter of the interview itself. For an interview in May 2010 reporting February-April, PQ holds Feb + Mar expenditure and CQ holds April expenditure. To get the full 3-month reference total for any category we always add PQ + CQ.

We build annual expenditure at the household level by summing across each CU's four interview rows directly. After appending the 11 quarterly files, each CU appears up to four times in the panel (once per completed interview, interviews 2-5). For each expenditure stem we compute (PQ + CQ) per interview row, then collapse to one row per CU summing across that CU's four interviews. We restrict the sample to CUs that completed all four interviews so that this sum is a clean annual aggregate. The CU-level weight is FINLWT21 from the 5th interview, taken directly with no rescaling.

The FMLY file contains two total-expenditure variables, TOTEXP and TOTEX4. We use TOTEX4 because it incorporates a sampling correction for items asked only in the fifth interview. The User's Guide (page 25) explains that more carefully. The resulting TOTEX4 matches BLS published estimates.

---

For rent imputation we use the 2010 FMLY variable RENTEQVX directly, in contrast to the 1960 approach that applies the Davis et al. 5.6% price-to-rent ratio to bracketed home values. RENTEQVX is the owner's self-reported answer to the question "If someone were to rent your home today, how much do you think it would rent for monthly, unfurnished and without utilities?"

We adjust total expenditure for owners using the same approach as in the 1960 script: adding imputed rent adnd subtracting owned dwellings.

--- 

We have two main types of income variables on the FMLY file: X variables hold raw reported values and M variables hold BLS multiply-imputed values. We use the M versions. BLS imputes missing income responses techniques described in the User's Guide. The income variables on FMLY are already 12-month totals collected in the 5th interview.

Pre-tax-and-transfer earned income is constructed as inc_earned = FSALARYM + FNONFRMM + FFRMINCM, where FSALARYM is wage and salary income for all CU members, FNONFRMM is non-farm self-employment, business, and professional practice income, and FFRMINCM is farm income or loss. We use the imputed M versions, which match the construction of BLS's own total-income variable FINCBTXM. We exclude rental income, interest, dividends, and other receipts: INTEARNM (interest on savings accounts or bonds), FININCXM (dividends, royalties, estates, trusts), INCLOSAM (net rental income from roomers or boarders), INCLOSBM (net income from other rental units), and OTHRINCM (scholarships, fellowships, other).

Post-tax-and-transfer income adds non-OASI transfers to earned income and subtracts taxes. We exclude Social Security and Railroad Retirement (FRRETIRM) and pensions (PENSIONM) from the transfer component. The included transfer components, all BLS multiply-imputed M variables, are FSSIXM (Supplemental Security Income), UNEMPLXM (unemployment compensation), COMPENSM (workers' compensation and veterans' benefits), WELFAREM (public assistance and welfare), FOODSMPM (food stamps and EBT), CHDOTHXM (child support received), and ALIOTHXM (alimony received). Taxes are TOTTXPDM, the BLS-built net total of federal and state taxes withheld and paid, property and miscellaneous taxes, minus refunds.

---

We have adjusted for inflation using CPI-U (BLS series CUUR0000SA0). The adjustment differs by variable type: expenditure variables are deflated by the average CPI across the three specific reference months they cover; income variables are deflated by the average CPI across the twelve months of the income reference period; and the rental equivalence variable (RENTEQVX) is deflated by the CPI of the interview month itself, since it is a point-in-time valuation.

---

The current categorization is:

food at home: fdhome

goods:      alcbev_ann                                             ///  alcohol   <br>
          + tobacc_ann                                             ///  tobacco    <br>
          + houseq_ann                                             ///  housefurnishings and equipment <br>
          + appar_ann                                              ///  apparel + footwear   <br>
          + cartkn_ann + cartku_ann + othveh_ann +  vrntlo_ann     ///  vehicle purchases and rental  <br>
          + tvrdio_ann + pettoy_ann                                ///  TV/radio/sound equip  <br>
          + read_ann                                                //   reading  <br>
		  
* decide if to keep otheqp_ann in goods or split in pettoy_ann in goods and othent_ann in services?

services =   imputed_rent                                            ///  imputed rent   <br>
            + rendwe_ann + othlod_ann                                 ///  actual rent, other lodging  <br>
		    + fdaway_ann                                              ///  food away  <br>
            + util_ann + housop_ann                                   ///  utilities + housekeeping  <br>
            + gasmo_ann + vehfin_ann + mainrp_ann + vehins_ann        ///  vehicle operations  <br>
            + pubtra_ann                                              ///  public transit  <br>
            + health_ann                                              ///  all health  <br>
            + persca_ann + feeadm_ann + othent_ann                    ///  personal care, entertainment  <br>
            + educa_ann                                               ///  education  <br>
		    + miscx4_ann                                               //   misscellaneous  <br>

we exclude owndwe_ann (owned dwellings) and we have robustness check using cashco_ann (cash contributions) and perins_ann (personal insurance and pensions)

--- 

The income threshold from the project specification is $5,000 in 2016 dollars. The 2010-dollar equivalent is $4,542.70. We drop CUs with inc_pre < $4,542.70. Conditional on completing all four interviews, having at least one reference month in 2010, and having a reference person aged 25-60, the weighted share of CUs below this threshold is 0.103 (10.3% of qualifying U.S. consumer units in 2010).

---

We have constructed moments of log expenditures and two measures of shares (mean of household shares, and aggregate share) by both expenditure deciles/quintiles and income deciles/quintiles.Deciles and quintiles are weighted by annual_wgt. 

-----
