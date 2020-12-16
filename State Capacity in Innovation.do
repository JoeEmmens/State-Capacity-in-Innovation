***************************************************************************************************************************************************************************
***************************************************************************************************************************************************************************
***                                                                         State Capacity in Innovation                                                                              ***  
***                                                                                                                                                                                                 ***
***************************************************************************************************************************************************************************
***************************************************************************************************************************************************************************

/*
Data analysis and regression models for "State Capacity in Innovation Markets".

Author:
Joseph Emmens

Date:
16/12/2020
*/

	clear all
	set seed 13
	capture set more off


	cd"Set to your path"

	import delim using "Set to data file", clear

	
/*
Set the panel data structure and create the necessary variables
*/	
xtset id year

sort id year
by id: gen SB_lag1_norm = statebetnorm[_n-1]
by id: gen SB_lag2_norm = statebetnorm[_n-2]
by id: gen SB_lag3_norm = statebetnorm[_n-3]
by id: gen SB_lag4_norm = statebetnorm[_n-4]
by id: gen SB_lag1_std = statebetstd[_n-1]
by id: gen SB_lag2_std = statebetstd[_n-2]
by id: gen SB_lag3_std = statebetstd[_n-3]
by id: gen SB_lag4_std = statebetstd[_n-4]
by id: gen AD_lag1 = avgdeg[_n-1]
by id: gen AD_lag2 = avgdeg[_n-2]
by id: gen Pat_lag1 = patents[_n-1]
by id: gen Pat_lag2 = patents[_n-2]

replace SB_lag1_std = 0.00001 if SB_lag1_std == 0
replace SB_lag2_std = 0.00001 if SB_lag2_std == 0
replace SB_lag3_std = 0.00001 if SB_lag3_std == 0
replace SB_lag1_norm = 0.00001 if SB_lag1_norm == 0
replace SB_lag2_norm = 0.00001 if SB_lag2_norm == 0
replace SB_lag3_norm = 0.00001 if SB_lag3_norm == 0

replace AD_lag1 = 0.00001 if AD_lag1 == 0	
	
gen ln_patents = log(patents)
gen ln_patents_lag = log(Pat_lag1)
gen ln_statebetstd = log(statebetstd)
gen ln_avgdeg = log(avgdeg)
gen ln_SB_lag1_std = log(SB_lag1_std)
gen ln_SB_lag2_std = log(SB_lag2_std)
gen ln_SB_lag3_std = log(SB_lag3_std)
gen ln_SB_lag4_std = log(SB_lag4_std)
gen ln_AD_lag1 = log(AD_lag1)
gen ln_AD_lag2 = log(AD_lag2)

gen ln_SB_lag1_norm = log(SB_lag1_norm)
gen ln_SB_lag2_norm = log(SB_lag2_norm)
gen ln_SB_lag3_norm = log(SB_lag3_norm)


/* Create year dummies*/

tab(year), gen(y)

/**************************************************************************************************************************************************************************
Both patents and state betweeness are highly skewed. To deal with this take a log transformation.
The difference is displayed in the histograms.
***************************************************************************************************************************************************************************/
hist patents, nodraw name(histo1)
hist ln_patents, nodraw name(histo2)

hist avgdeg, nodraw name(histo3)
hist ln_avgdeg, nodraw name(histo4)

hist statebetstd, nodraw name(histo5)
hist ln_statebetstd, nodraw name(histo6)

graph combine histo1 histo2 histo3 histo4 histo5 histo6, rows(3) cols(2)

/**************************************************************************************************************************************************************************
Regression Analysis. OLS is biased due to the unobserved heterogeneity. Fixed county and time effects are introduced to the model. 

System GMM is used to produce a dynamic panel data model. The number of years is restricted under the system GMM model to 
satisfy the overidentifying restrictions due to the relatively large T on N.
**************************************************************************************************************************************************************************/

reg ln_patents ln_SB_lag1_std ln_SB_lag2_std, r

xtreg ln_patents ln_SB_lag1_std i.year, fe
estimates store col1

xtreg ln_patents ln_SB_lag1_std ln_SB_lag2_std i.year, fe
estimates store col2

xtreg ln_patents ln_SB_lag1_std ln_SB_lag2_std ln_AD_lag1 i.year, fe
estimates store col3

xtabond2 ln_patents ln_patents_lag ln_AD_lag1 ln_SB_lag1_std ln_SB_lag2_std ln_SB_lag3_std y31-y44 if year >= 2005, ///
gmmstyle(ln_patents_lag ln_AD_lag1 ln_SB_lag1_std ln_SB_lag2_std ln_SB_lag3_std) ///
ivstyle(i.year) ///
h(1) cluster(id) artests(3)
estimates store col4

esttab col1 col2 col3 col4 using Results.tex, se ar2 label nogaps compress title("Table 1") star(* 0.10 ** 0.05 *** 0.01 ) replace

xtabond2 ln_patents ln_patents_lag ln_SB_lag1_std ln_SB_lag2_std y31-y44 if year >= 2005, ///
gmmstyle(ln_patents_lag ln_SB_lag1_std ln_SB_lag2_std) ///
ivstyle(i.year) ///
h(1) cluster(id) artests(3)

/**************************************************************************************************************************************************************************
The model is repeated without using the log transformation on average degree. 
**************************************************************************************************************************************************************************/

xtreg ln_patents ln_SB_lag1_std ln_SB_lag2_std AD_lag1 i.year, fe
estimates store col5

xtabond2 ln_patents ln_patents_lag AD_lag1 ln_SB_lag1_std ln_SB_lag2_std ln_SB_lag3_std y31-y44 if year >= 2005, ///
gmmstyle(ln_patents_lag AD_lag1 ln_SB_lag1_std ln_SB_lag2_std ln_SB_lag3_std) ///
ivstyle(i.year) ///
h(1) cluster(id) artests(3)
estimates store col6

esttab col1 col2 col5 col6 using ResultsADnormal.tex, se ar2 label nogaps compress title("Table 1") star(* 0.10 ** 0.05 *** 0.01 ) replace	

/**************************************************************************************************************************************************************************
Robustness Checks

Beginning attempts to acknowledge endogeneity in the model. Santa Clara and Westchester County are by far the largest patent
producers, does excluding them from the results change much?
**************************************************************************************************************************************************************************/

xtreg ln_patents ln_SB_lag1_std i.year if id!= 27, fe
estimates store col7

xtreg ln_patents ln_SB_lag1_std ln_SB_lag2_std i.year  if id!= 27, fe
estimates store col8

xtreg ln_patents ln_SB_lag1_std ln_SB_lag2_std ln_AD_lag1 i.year  if id!= 27, fe
estimates store col9

xtabond2 ln_patents ln_patents_lag ln_AD_lag1 ln_SB_lag1_std ln_SB_lag2_std ln_SB_lag3_std y31-y44 if year >= 2005 &  id != 27, ///
gmmstyle(ln_patents_lag ln_AD_lag1 ln_SB_lag1_std ln_SB_lag2_std ln_SB_lag3_std) ///
ivstyle( y31-y44 ) ///
h(1) cluster(id) artests(3)
estimates store col10

esttab col7 col8 col9 col10 using Robusntness.tex, se ar2 label nogaps compress title("Robustness") star(* 0.10 ** 0.05 *** 0.01 ) replace

***************************************************************************************************************************************************************************
***************************************************************************************************************************************************************************


