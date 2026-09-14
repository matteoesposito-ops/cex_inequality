# 1960-expenditure

For the 1935-36 study (ICPSR 08908), the download contains 4 datasets and a codebook. The four datasets are named 08908-0001-Data.dta, 08908-0002-Data.dta, 08908-0003-Data.dta, and 08908-0004-Data.dta. All four are already in Stata .dta. 
Dataset 1 (5,975 observations, 242 variables) contains income data for all sampled urban families. Dataset 2 (5,310 observations, 332 variables) contains income data for urban and rural families who did not provide any expenditure data. Dataset 3 (3,100 observations, 2,869 variables) contains both income and expenditure data for urban families. Dataset 4 (3,034 observations, 2,869 variables) contains the same for rural families. Datasets 3 and 4 are the ones relevant for expenditure. The codebook that covers datasets 3 and 4 is a plain text file named 08908-0003-Codebook-MULTI.txt.

For the 1960-61 study (ICPSR 09035), the download contains a single dataset and a single codebook. The dataset is named 09035-0001-Data.txt and is a plain, non-delimited fixed-width text file with 13,728 observations and 212 variables. The codebook is provided only as a PDF file named 09035-0001-Codebook.pdf. 

---

The file 09035-0001-Data.txt has one household per row, with each row exactly 1,748 characters wide. Variables are identified by their character position within each row. The column layout is documented on pages 16-22 of the PDF codebook 09035. For categorical variables, those pages list a Classification Code number (CC-XX) next to each field; the actual code values are on pages 155-183.
More detailed description of each categories can be found on pages 27-38.

We use Stata’s infix command to parse the file. Some variables required scaling, as discussed in the do-file. All variables have been labeled. Many are specific expenditure subcategories, for which we have total expenditures. The do-file provides a clear overview of the dataset without requiring the reader to consult the codebook. However, the codebook remains necessary to understand the hierarchical structure of the variables, that is, which variables are sub-components of which aggregate totals.

---

The unit of observation in 1960-61 is the consumer unit. The definition is given on page 101 of the PDF codebook:

"Family or consumer unit refers to: (1) a group of 2 or more people usually living together who pooled their income and drew from a common fund for their major items of expense; or (2) a person living alone or in a household with others, but who was financially independent, i.e., his income and expenditures were not pooled."

Never-married children living with their parents are always considered members of the consumer unit regardless of age, even if they pay room and board. Persons temporarily away from home (students, travelers, those briefly hospitalized) remain members. Persons residing in military posts, institutions, or foreign countries for extended periods are excluded.

We also have an expansion factor (weight): it is an estimate of the number of consumer units in the universe per consumer unit in the sample.

---

We report here all the total expenditure categories, along with selected sub-categories the assignment to different groups requires disaggregation:

Food total (food at home, food away from home),<br>
alcoholic beverages,<br>
tobacco,<br>
housing total (rented dwelling, owned dwelling, owned vacation home, lodging out, other real estate total), bills total, household operations total (telephone and telegraph, other household services, household supplies), housefurnishings total(household textiles, furniture total, floor coverings, major appliances total, small appaliances, housewares, insurance on furnishing, other housefurnishing),<br>
clothing total,<br>
transportation total (automobile purchase, automobile operation, public transportation),<br>
medical care total,<br>
personal care total (services, supplies),<br>
recreation total (television, musical equipment, spectator admissions, participant sports, club dues),<br>
reading,<br>
education total (tutition, books, music lessons)<br>
miscellaneous personal consumption total

We also have personal insurance total and gifts total, but these were not included in the total expenditures variable from the survey.

Note that other real estate includes taxes and other expenses on property owned but not used for family business and not occupied or rented.

---

We checked whether annual rent divided by 12 falls within the monthly rent bracket reported in the survey (cols 55-56, CC-31). Of 5,328 renters, 70.4% pass this check. Of the remaining 26.4%, around 52.3% are only one bracket off. 

For owners, imputed rent is computed as the product of the midpoint of the home value bracket (cols 53-54, CC-30) and the national rent-to-price ratio of 5.6% from Davis, Lehnert, and Martin (2008). The 42 owners with missing home value (code 99) are dropped from the sample at this stage, to be revisited once data by region and stratum is available. The distribution of imputed rents (mean $740, median $630) is close to the distribution of actual rents paid by renters (mean $660, median $608), with imputed rents showing more dispersion in the upper tail.

We then adjusted expenditure for owners by adding imputed rent and removing out-of-pocket housing expenditure (owned dwelling total, cols 153-162).

---

We construct pre and post-tax-and-transfers income.

---

At the moment, the categorization is:

food at home = food at home<br>
goods = food away from home, alcoholic beverages, tobacco, household supplies, household textiles, furniture total, floor coverings, major appliances total, small appliances, housewares, other housefurnishings, clothing total, automobile purchase, personal care supplies, television, musical equipment, books<br>
services = imputed rent, rented dwelling, actual rent, owned vacation home, lodging out, bills total, telephone and telegraph, other household services, insurance on furnishings, automobile operation, public transportation, medical care total, personal care services, spectator admissions, participant sports, club dues, reading, tuition, music lessons, miscellaneous personal consumption total

We exclude owned dwelling

---

We have constructed moments of log expenditures and measures of expenditure shares by expenditure/income deciles and quintiles shares based on adjusted total expenditure using the expanding factor (weight) provided in the dataset.
 
