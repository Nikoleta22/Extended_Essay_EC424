clear 
version 17
set more off
capture log close
log using an2, replace


*Path name here cd ""  

*import delimited "S&P 500 Historical Data Kopie.csv", delimiters(";") varnames(1) numericcols(3)  clear






********************** IV-Local Projection********************

********************** Baseline Regression********************



import excel "Historical_Data",  firstrow clear

*set TS variable
gen date=ym(year,month)
format date %tm
drop month year
tsset date


drop Open High Low Vol Change

*Instruments
rename ff4_tc ff4
rename ed2_tc ed2
rename ed3_tc ed3
rename ed4_tc ed4

drop if ed4==.

* ln asset variables
gen lnSP500 = ln(SP500)
gen lnyield_2y= ln(aver_yield_2y)
gen lnyield_5y= ln(aver_yield_5y)
gen lnyield_10y= ln(aver_yield_10y)
gen lnyield_30y= ln(aver_yield_30y)
gen lnyield_3m= ln(aver_yield_3m)
gen lnyield_6m= ln(aver_yield_6m)
gen lnAAA=ln(AAA)
gen lnBAA=ln(BAA)

*use Federal Funds Rate as interest rate
*First difference of the Federal Funds Rate
gen ffchange=D.ff
gen ff_exp1yrchange=D.ff_exp1yr
gen gs1change=D.gs1



*Number of periods
local hmax= 15
*Number of lags
local lmax= 4

*generate leads of the assets
local asset=   " lnSP500 lnyield_2y lnyield_5y lnyield_10y lnyield_30y lnyield_6m lnyield_3m lnAAA lnBAA "
foreach a of local asset {
forvalues h=0/`hmax'{
gen `a'`h'=F`h'.`a'

}
}



******* LP-IV  *******

*Instrument: ed4

local rate= "ff "	
foreach r of local rate {
 local asset=   " lnSP500 lnyield_2y lnyield_5y lnyield_10y lnyield_30y lnyield_6m lnyield_3m lnAAA lnBAA "
foreach a of local asset {
*Number of periods
local hmax= 15
*Number of lags
local lmax= 4



  
eststo clear
cap drop beta upperbound lowerbound Months Zero
gen Months = _n-1 if _n<=`hmax'+1
gen Zero = 0 if _n<=`hmax'+1
gen beta=0
gen upperbound=0
gen lowerbound= 0
	
	

 quietly forv h = 0/`hmax' {
 ivregress gmm `a'`h' l(1/`lmax').`r' l(1/`lmax').`a'   (`r'change = ed4) , vce(hac nwest) 

replace beta= _b[`r'change] if _n == `h'+1
*95% CI
replace upperbound= _b[`r'change] + 1.96* _se[`r'change] if _n==`h'+1
replace lowerbound= _b[`r'change] - 1.96* _se[`r'change] if _n==`h'+1
eststo
}
	
*summary of the LP coefficients	
nois esttab, se nocons keep(`r'change)

twoway(rarea upperbound lowerbound Months, fcolor(blue%15) lw(none) lpattern(solid)) (line beta Months, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Months, lcolor(back)), legend(off) ytitle("Percent") note("Notes: 95% confidence bands")  graphregion(color(white)) plotregion(color(white))

*title("Response of the S&P 500 to a monetary shock", color(black) size(med))

graph export IR_`a'_ed4_`r'.pdf ,replace                                    

}	
}

	
	
	
	
	
*Instrument ff4

drop if ff4==.	
local rate= "ff "	
foreach r of local rate {
 local asset=   " lnSP500 lnyield_2y lnyield_5y lnyield_10y lnyield_30y lnyield_6m lnyield_3m lnAAA lnBAA "
foreach a of local asset {
*Number of periods
local hmax= 15
*Number of lags
local lmax= 4



  
eststo clear
cap drop beta upperbound lowerbound Months Zero
gen Months = _n-1 if _n<=`hmax'+1
gen Zero = 0 if _n<=`hmax'+1
gen beta=0
gen upperbound=0
gen lowerbound= 0
	
	

 quietly forv h = 0/`hmax' {
 ivregress gmm `a'`h' l(1/`lmax').`r' l(1/`lmax').`a'  (`r'change = ff4) , vce(hac nwest) 

replace beta= _b[`r'change] if _n == `h'+1
*95% CI
replace upperbound= _b[`r'change] + 1.96* _se[`r'change] if _n==`h'+1
replace lowerbound= _b[`r'change] - 1.96* _se[`r'change] if _n==`h'+1
eststo
}
	
*summary of the LP coefficients	
nois esttab, se nocons keep(`r'change)

twoway(rarea upperbound lowerbound Months, fcolor(blue%15) lw(none) lpattern(solid)) (line beta Months, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Months, lcolor(back)), legend(off) ytitle("Percent") note("Notes: 95% confidence bands")  graphregion(color(white)) plotregion(color(white))

*title("Response of the S&P 500 to a monetary shock", color(black) size(med))

graph export IR_`a'_ff4_`r'.pdf ,replace                                    

}	
}


 
 

 
 

**********************Regression with dummies for expasions and contractions********************


import excel "Historical_Data",  firstrow clear

*set TS variable
gen date=ym(year,month)
*format date %tm
format date  %tmnn/CCYY
drop month year
tsset date

drop Open High Low Vol Change

*Instruments
rename ff4_tc ff4
rename ed2_tc ed2
rename ed3_tc ed3
rename ed4_tc ed4

drop if ff4==.

*based on NBER data on US business cycle contractions and expansions
* dummy=1 if expansions and =0 if contractions
gen business_cycle=1 
*Contractions (recessions) start at the peak of a business cycle and end at the trough
*Contractions in the sample: 
*01.1980 - 07.1980 : lines 7- 13 --> date between 240- 246
replace business_cycle=0 if date>=240 & date<=246
*07.1981 - 11.1982: lines lines 25-41 --> date between 258- 274
replace business_cycle=0 if date>=258 & date<=274
*07.1990 - 03.1991 : lines 133-141 --> date between 366 - 374
replace business_cycle=0 if date>=366 & date<=374
*03.2001 - 11.2001 : lines 261-269 --> date between 494 - 502
replace business_cycle=0 if date>=494 & date<=502
*12.2007 - 06.2009 : lines 342- 360 --> date between 575 - 593
replace business_cycle=0 if date>=575 & date<=593
 
 *lag one period
gen expansionstm1=l.business_cycle

gen contractions=0
replace contractions=1 if business_cycle==0
*lag one period
gen   contractionstm1=l.contractions
 
 
*use Federal Funds Rate as interest rate
*First difference of the Federal Funds Rate
gen ffchange=D.ff
gen ff_exp1yrchange=D.ff_exp1yr
gen gs1change=D.gs1

 
*Probability of recession INDPRO, recessions, change in ff and instrument ff4
twoway (area contractions date, fcolor(gs13) lcolor(gs13%50) lpattern(solid)) (line pr_recession_indpro date, lcolor(black))  (line ffchange date, lcolor(red) ) (bar ff4 date, fcolor(ebblue) lcolor(ebblue))  , ytitle("Percent") graphregion(color(white)) plotregion(color(white)) xlabel(#5) legend(order(1 "Recession" 2 "Probability of recession" 3 "FFR change" 4 "FFF4" ))
graph export prob_recession_indpro_change.pdf ,replace 

*Probability of recession INDPRO, change in ff and instrument ff4
twoway (area contractions date, fcolor(gs13) lcolor(gs13%50) lpattern(solid)) (line pr_recession_gdp date, lcolor(black))  (line ffchange date, lcolor(red) ) (bar ff4 date, fcolor(ebblue) lcolor(ebblue)) , ytitle("Percent") graphregion(color(white)) plotregion(color(white)) xlabel(#5) legend(order(1 "Recession" 2 "Probability of recession" 3 "FFR change" 4 "FFF4" ))
graph export prob_recession_gdp_change.pdf ,replace 


 



* ln asset variables
gen lnSP500 = ln(SP500)
gen lnyield_2y= ln(aver_yield_2y)
gen lnyield_5y= ln(aver_yield_5y)
gen lnyield_10y= ln(aver_yield_10y)
gen lnyield_30y= ln(aver_yield_30y)
gen lnyield_3m= ln(aver_yield_3m)
gen lnyield_6m= ln(aver_yield_6m)
gen lnAAA=ln(AAA)
gen lnBAA=ln(BAA)


*generate dummies
gen ed4e =ed4*expansionstm1

gen ed4c=ed4*contractionstm1

gen ff_exp1yrchangee=ff_exp1yrchange*expansionstm1

gen ff_exp1yrchangec=ff_exp1yrchange*contractionstm1

gen ff4e =ff4*expansionstm1

gen ff4c=ff4*contractionstm1

gen ffchangee=ffchange*expansionstm1

gen ffchangec=ffchange*contractionstm1

gen gs1changee=gs1change*expansionstm1

gen gs1changec=gs1change*contractionstm1



*Number of periods
local hmax= 15
*Number of lags
local lmax= 4

*generate leads of the assets
local asset=   " lnSP500 lnyield_2y lnyield_5y lnyield_10y lnyield_30y lnyield_6m lnyield_3m lnAAA lnBAA "
foreach a of local asset {
forvalues h=0/`hmax'{
gen `a'`h'=F`h'.`a'

}
}



*Instrument ff4				 


local rate= "ff  "	
foreach r of local rate {
 local asset=   " lnSP500 lnyield_2y lnyield_5y lnyield_10y lnyield_30y lnyield_6m lnyield_3m lnAAA lnBAA "
foreach a of local asset {
*Number of periods
local hmax= 15
*Number of lags
local lmax= 4



  
eststo clear
cap drop be bc ue uc de dc  Months Zero
gen Months = _n-1 if _n<=`hmax'+1
gen Zero = 0 if _n<=`hmax'+1
gen be=0
gen bc=0
gen ue=0
gen uc=0
gen de= 0
gen dc= 0



 quietly forv h = 0/`hmax' {
 ivregress gmm `a'`h' l(1/`lmax').`r' l(1/`lmax').`a' (`r'changee `r'changec = ff4e ff4c) , vce(hac nwest) 

 
*expansion
replace be= _b[`r'changee] if _n == `h'+1
*95% CI
replace ue= _b[`r'changee] + 1.96* _se[`r'changee] if _n==`h'+1
replace de= _b[`r'changee] - 1.96* _se[`r'changee] if _n==`h'+1
*contraction
replace bc= _b[`r'changec] if _n == `h'+1
*95% CI
replace uc=_b[`r'changec] + 1.96* _se[`r'changec] if _n==`h'+1
replace dc=_b[`r'changec] - 1.96* _se[`r'changec] if _n==`h'+1

 
eststo
}
	
*summary of the LP coefficients	
nois esttab, se nocons keep(`r'changee `r'changec)

twoway(rarea ue de Months, fcolor(blue%15) lcolor(gs13) lw(none) lpattern(solid))(line be Months, lcolor(blue) lpattern(solid) lwidth(thick)) (rarea uc dc Months,fcolor(red%15) lcolor(gs13) lw(none) lpattern(solid))(line bc Months, lcolor(red) lpattern(dash) lwidth(thick)) (line Zero Months, lcolor(back)), legend(off)  note("Notes: 95% confidence bands") ytitle("Percent") graphregion(color(white)) plotregion(color(white))


graph export IR_`a'_ff4_`r'_NBER.pdf ,replace 
                              

}	
}

	




***************************************Probability of recession based on the industrial production index***************************************
 

import excel "Historical_Data",  firstrow clear




*set TS variable
gen date=ym(year,month)
*format date %tm
format date  %tmnn/CCYY
drop month year
tsset date





*use Federal Funds Rate as interest rate
*First difference of the Federal Funds Rate
gen ffchange=D.ff
gen ff_exp1yrchange=D.ff_exp1yr
gen gs1change=D.gs1

drop if ff4_tc==.



drop Open High Low Vol Change 


rename pr_recession_indpro prob_recession
*variable 1-prob(recession)
gen prob_norecession=1-prob_recession

*lag one periods
gen prob_recessiontm1=l.prob_recession
gen prob_norecessiontm1= l.prob_norecession
 

*Instruments
rename ff4_tc ff4
rename ed2_tc ed2
rename ed3_tc ed3
rename ed4_tc ed4



* ln asset variables
gen lnSP500 = ln(SP500)
gen lnyield_2y= ln(aver_yield_2y)
gen lnyield_5y= ln(aver_yield_5y)
gen lnyield_10y= ln(aver_yield_10y)
gen lnyield_30y= ln(aver_yield_30y)
gen lnyield_3m= ln(aver_yield_3m)
gen lnyield_6m= ln(aver_yield_6m)
gen lnAAA=ln(AAA)
gen lnBAA=ln(BAA)

*Number of periods
local hmax= 15
*Number of lags
local lmax= 4

*generate leads of the assets
local asset=   " lnSP500 lnyield_2y lnyield_5y lnyield_10y lnyield_30y lnyield_6m lnyield_3m lnAAA lnBAA "
foreach a of local asset {
forvalues h=0/`hmax'{
gen `a'`h'=F`h'.`a'

}
}





*generate dummies
gen ed4h =ed4*prob_norecessiontm1

gen ed4l=ed4*prob_recessiontm1

gen ff_exp1yrchangeh=ff_exp1yrchange*prob_norecessiontm1

gen ff_exp1yrchangel=ff_exp1yrchange*prob_recessiontm1

gen ff4h =ff4*prob_norecessiontm1

gen ff4l=ff4*prob_recessiontm1

gen ffchangeh=ffchange*prob_norecessiontm1

gen ffchangel=ffchange*prob_recessiontm1

gen gs1changeh=gs1change*prob_norecessiontm1

gen gs1changel=gs1change*prob_recessiontm1


	
	
	
*Instrument ff4				 

drop if ff4==.	

local rate= "ff "	
foreach r of local rate {	
local asset= " lnSP500 lnyield_2y lnyield_5y lnyield_10y lnyield_30y lnyield_6m lnyield_3m lnAAA lnBAA "
 quietly foreach a of local asset {
	
*Number of periods
local hmax= 15
*Number of lags
local lmax= 4 




eststo clear
cap drop bh bl uh ul dh dl Months Zero
gen Months = _n-1 if _n<=`hmax'+1
gen Zero = 0 if _n<=`hmax'+1
gen bh=0
gen bl=0
gen uh=0
gen ul=0
gen dh= 0
gen dl= 0




 quietly forv h = 0/`hmax' {
 ivregress gmm `a'`h' l(1/`lmax').`r' l(1/`lmax').`a' (`r'changeh `r'changel = ff4h ff4l) , vce(hac nwest) 

*positive
replace bh= _b[`r'changeh] if _n == `h'+1
*95% CI
replace uh= _b[`r'changeh] + 1.96* _se[`r'changeh] if _n==`h'+1
replace dh= _b[`r'changeh] - 1.96* _se[`r'changeh] if _n==`h'+1
*negative
replace bl= _b[`r'changel] if _n == `h'+1
*95% CI
replace ul=_b[`r'changel] + 1.96* _se[`r'changel] if _n==`h'+1
replace dl=_b[`r'changel] - 1.96* _se[`r'changel] if _n==`h'+1

eststo
}
	

*summary of the LP coefficients	
nois esttab, se nocons keep(`r'changeh `r'changel)

twoway(rarea uh dh Months, fcolor(blue%15) lcolor(gs13) lw(none) lpattern(solid))(line bh Months, lcolor(blue) lpattern(solid) lwidth(thick)) (rarea ul dl Months,fcolor(red%15) lcolor(gs13) lw(none) lpattern(solid))(line bl Months, lcolor(red) lpattern(dash) lwidth(thick)) (line Zero Months, lcolor(back)), legend(off) ytitle("Percent") note("Notes: 95% confidence bands") graphregion(color(white)) plotregion(color(white))

*title("Response of the S&P 500 to a monetary shock", color(black) size(med))

graph export IR_`a'_ff4_`r'_INDPRO.pdf ,replace


}	
}	




********************** Table for coefficients at t+1 for a shock at time t, comparing the different approaches********************




import excel "Historical_Data",  firstrow clear

*set TS variable
gen date=ym(year,month)
format date %tm
drop month year
tsset date




drop Open High Low Vol Change 



*Instruments
rename ff4_tc ff4
rename ed2_tc ed2
rename ed3_tc ed3
rename ed4_tc ed4

drop if ff4==.

* ln asset variables
gen lnSP500 = ln(SP500)
gen lnyield_2y= ln(aver_yield_2y)
gen lnyield_5y= ln(aver_yield_5y)
gen lnyield_10y= ln(aver_yield_10y)
gen lnyield_30y= ln(aver_yield_30y)
gen lnyield_3m= ln(aver_yield_3m)
gen lnyield_6m= ln(aver_yield_6m)
gen lnAAA=ln(AAA)
gen lnBAA=ln(BAA)

*use Federal Funds Rate as interest rate
*First difference of the Federal Funds Rate
gen ffchange=D.ff



*generate one period lead of the assets
local asset=   " lnSP500 lnyield_2y lnyield_5y lnyield_10y lnyield_30y lnyield_6m lnyield_3m lnAAA lnBAA "
foreach a of local asset {

gen `a'1=F1.`a'

}






*define matrix to save the results

matrix C=J(9,10,.)
 matrix stars= J(9,10,.)

*******Baseline regression
	
*Instrument ff4	
 local i=1 //row index
 local asset= " lnSP500  lnyield_3m lnyield_6m lnyield_2y lnyield_5y lnyield_10y lnyield_30y  lnAAA lnBAA "
foreach a of local asset {

*Number of lags
local lmax= 4

ivregress gmm `a'1 l(1/`lmax').ff l(1/`lmax').`a'  (ffchange = ff4) , vce(hac nwest) 
 
 
 
matrix C[`i',1]= _b[ffchange]
matrix C[`i',2]= _se[ffchange]
*add stars for significant coefficients
matrix stars[`i',2]=0
matrix stars[`i',1]=(abs(_b[ffchange]/_se[ffchange])>invttail(`e(N)'- `e(rank)',0.1/2))+(abs(_b[ffchange]/_se[ffchange])>invttail(`e(N)'- `e(rank)',0.05/2))+(abs(_b[ffchange]/_se[ffchange])>invttail(`e(N)'- `e(rank)',0.01/2))
 
 
local ++i

}
	


**********************Regression with dummies for expasions and contractions


*based on NBER data on US business cycle contractions and expansions
* dummy=1 if expansions and =0 if contractions
gen business_cycle=1 
*Contractions (recessions) start at the peak of a business cycle and end at the trough
*Contractions in the sample: 
*01.1980 - 07.1980 : lines 7- 13 --> date between 240- 246
replace business_cycle=0 if date>=240 & date<=246
*07.1981 - 11.1982: lines lines 25-41 --> date between 258- 274
replace business_cycle=0 if date>=258 & date<=274
*07.1990 - 03.1991 : lines 133-141 --> date between 366 - 374
replace business_cycle=0 if date>=366 & date<=374
*03.2001 - 11.2001 : lines 261-269 --> date between 494 - 502
replace business_cycle=0 if date>=494 & date<=502
*12.2007 - 06.2009 : lines 342- 360 --> date between 575 - 593
replace business_cycle=0 if date>=575 & date<=593
 

 
 *lag one period
gen expansionstm1=l.business_cycle
gen contractions=0
replace contractions=1 if business_cycle==0
*lag one period
gen   contractionstm1=l.contractions
 

*generate dummies


gen ff4e =ff4*expansionstm1

gen ff4c=ff4*contractionstm1

gen ffchangee=ffchange*expansionstm1

gen ffchangec=ffchange*contractionstm1





	
*Instrument ff4	
 local i=1 //row index			 
 local asset=   " lnSP500  lnyield_3m lnyield_6m lnyield_2y lnyield_5y lnyield_10y lnyield_30y  lnAAA lnBAA "
foreach a of local asset {

*Number of lags
local lmax= 4



ivregress gmm `a'1 l(1/`lmax').ff l(1/`lmax').`a' (ffchangee ffchangec = ff4e ff4c) , vce(hac nwest) 
 
 matrix C[`i',3]= _b[ffchangec]
matrix C[`i',4]= _se[ffchangec]
*add stars for significant coefficients
matrix stars[`i',4]=0
matrix stars[`i',3]=(abs(_b[ffchangec]/_se[ffchangec])>invttail(`e(N)'- `e(rank)',0.1/2))+(abs(_b[ffchangec]/_se[ffchangec])>invttail(`e(N)'- `e(rank)',0.05/2))+(abs(_b[ffchangec]/_se[ffchangec])>invttail(`e(N)'- `e(rank)',0.01/2))

matrix C[`i',5]= _b[ffchangee]
matrix C[`i',6]= _se[ffchangee]
*add stars for significant coefficients
matrix stars[`i',6]=0
matrix stars[`i',5]=(abs(_b[ffchangee]/_se[ffchangee])>invttail(`e(N)'- `e(rank)',0.1/2))+(abs(_b[ffchangee]/_se[ffchangee])>invttail(`e(N)'- `e(rank)',0.05/2))+(abs(_b[ffchangee]/_se[ffchangee])>invttail(`e(N)'- `e(rank)',0.01/2))
 
  

 
 
 
local ++i
}
	

***************************************Probability of recession based on the industrial production index



rename pr_recession_indpro prob_recession
*variable 1-prob(recession)
gen prob_norecession=1-prob_recession

*lag one periods
gen prob_recessiontm1=l.prob_recession
gen prob_norecessiontm1= l.prob_norecession


*generate dummies
gen ff4h =ff4*prob_norecessiontm1

gen ff4l=ff4*prob_recessiontm1

gen ffchangeh=ffchange*prob_norecessiontm1

gen ffchangel=ffchange*prob_recessiontm1





*Instrument ff4				 
local i=1 //row index	
local asset= " lnSP500  lnyield_3m lnyield_6m lnyield_2y lnyield_5y lnyield_10y lnyield_30y  lnAAA lnBAA "
 quietly foreach a of local asset {
	

*Number of lags
local lmax= 4 


ivregress gmm `a'1 l(1/`lmax').ff l(1/`lmax').`a' (ffchangeh ffchangel = ff4h ff4l) , vce(hac nwest) 

  
matrix C[`i',7]= _b[ffchangel]
matrix C[`i',8]= _se[ffchangel]
*add stars for significant coefficients
matrix stars[`i',8]=0
matrix stars[`i',7]=(abs(_b[ffchangel]/_se[ffchangel])>invttail(`e(N)'- `e(rank)',0.1/2))+(abs(_b[ffchangel]/_se[ffchangel])>invttail(`e(N)'- `e(rank)',0.05/2))+(abs(_b[ffchangel]/_se[ffchangel])>invttail(`e(N)'- `e(rank)',0.01/2))
 
 
 
matrix C[`i',9]= _b[ffchangeh]
matrix C[`i',10]= _se[ffchangeh]
*add stars for significant coefficients
matrix stars[`i',10]=0
matrix stars[`i',9]=(abs(_b[ffchangeh]/_se[ffchangeh])>invttail(`e(N)'- `e(rank)',0.1/2))+(abs(_b[ffchangeh]/_se[ffchangeh])>invttail(`e(N)'- `e(rank)',0.05/2))+(abs(_b[ffchangeh]/_se[ffchangeh])>invttail(`e(N)'- `e(rank)',0.01/2))
 

 
local ++i


}
	
	
*save table
frmttable using table_coeff.doc, statmat(C) substat(1) sdec(4)  annotate(stars) asymbol(*,**,***)  note(Standard errors in parentheses and stars) 




********************************************Robustness********************************************




***************************************Probability of recession based on the interpolated GDP***************************************
*Path name here cd ""  

import excel "Historical_Data",  firstrow clear

*set TS variable
gen date=ym(year,month)
format date %tm
drop month year
tsset date

drop if ed4==.

drop Open High Low Vol Change 


rename pr_recession_gdp prob_recession
*variable 1-prob(recession)
gen prob_norecession=1-prob_recession

*lag one periods
gen prob_recessiontm1=l3.prob_recession
gen prob_norecessiontm1= l3.prob_norecession
 

*Instruments
rename ff4_tc ff4
rename ed2_tc ed2
rename ed3_tc ed3
rename ed4_tc ed4



* ln asset variables
gen lnSP500 = ln(SP500)
gen lnyield_2y= ln(aver_yield_2y)
gen lnyield_5y= ln(aver_yield_5y)
gen lnyield_10y= ln(aver_yield_10y)
gen lnyield_30y= ln(aver_yield_30y)
gen lnyield_3m= ln(aver_yield_3m)
gen lnyield_6m= ln(aver_yield_6m)
gen lnAAA=ln(AAA)
gen lnBAA=ln(BAA)

*Number of periods
local hmax= 15
*Number of lags
local lmax= 4

*generate leads of the assets
local asset=   " lnSP500 lnyield_2y lnyield_5y lnyield_10y lnyield_30y lnyield_6m lnyield_3m lnAAA lnBAA "
foreach a of local asset {
forvalues h=0/`hmax'{
gen `a'`h'=F`h'.`a'

}
}





*use Federal Funds Rate as interest rate
*First difference of the Federal Funds Rate
gen ffchange=D.ff
gen ff_exp1yrchange=D.ff_exp1yr
gen gs1change=D.gs1


*generate dummies
gen ed4h =ed4*prob_norecessiontm1

gen ed4l=ed4*prob_recessiontm1

gen ff_exp1yrchangeh=ff_exp1yrchange*prob_norecessiontm1

gen ff_exp1yrchangel=ff_exp1yrchange*prob_recessiontm1

gen ff4h =ff4*prob_norecessiontm1

gen ff4l=ff4*prob_recessiontm1

gen ffchangeh=ffchange*prob_norecessiontm1

gen ffchangel=ffchange*prob_recessiontm1

gen gs1changeh=gs1change*prob_norecessiontm1

gen gs1changel=gs1change*prob_recessiontm1


	
	
*Instrument ff4				 

drop if ff4==.	

*"ff ff_exp1yr gs1 "	
local rate= "ff  "	
foreach r of local rate {	
local asset= " lnSP500 lnyield_2y lnyield_5y lnyield_10y lnyield_30y lnyield_6m lnyield_3m lnAAA lnBAA "
 quietly foreach a of local asset {
	
*Number of periods
local hmax= 15
*Number of lags
local lmax= 4 




eststo clear
cap drop bh bl uh ul dh dl Months Zero
gen Months = _n-1 if _n<=`hmax'+1
gen Zero = 0 if _n<=`hmax'+1
gen bh=0
gen bl=0
gen uh=0
gen ul=0
gen dh= 0
gen dl= 0




 quietly forv h = 0/`hmax' {
 ivregress gmm `a'`h' l(1/`lmax').`r' l(1/`lmax').`a' (`r'changeh `r'changel = ff4h ff4l) , vce(hac nwest) 

*positive
replace bh= _b[`r'changeh] if _n == `h'+1
*95% CI
replace uh= _b[`r'changeh] + 1.96* _se[`r'changeh] if _n==`h'+1
replace dh= _b[`r'changeh] - 1.96* _se[`r'changeh] if _n==`h'+1
*negative
replace bl= _b[`r'changel] if _n == `h'+1
*95% CI
replace ul=_b[`r'changel] + 1.96* _se[`r'changel] if _n==`h'+1
replace dl=_b[`r'changel] - 1.96* _se[`r'changel] if _n==`h'+1

eststo
}
	

*summary of the LP coefficients	
nois esttab, se nocons keep(`r'changeh `r'changel)

twoway(rarea uh dh Months, fcolor(blue%15) lcolor(gs13) lw(none) lpattern(solid))(line bh Months, lcolor(blue) lpattern(solid) lwidth(thick)) (rarea ul dl Months,fcolor(red%15) lcolor(gs13) lw(none) lpattern(solid))(line bl Months, lcolor(red) lpattern(dash) lwidth(thick)) (line Zero Months, lcolor(back)), legend(off)  ytitle("Percent") note("Notes: 95% confidence bands") graphregion(color(white)) plotregion(color(white))

*title("Response of the S&P 500 to a monetary shock", color(black) size(med))

graph export IR_`a'_ff4_`r'_GDP.pdf ,replace


}	
}	




********************** Baseline Regression for period before the ZLB was reached in December 2008********************



import excel "Historical_Data",  firstrow clear

*set TS variable
gen date=ym(year,month)
*format date %tm
drop month year
tsset date


*September 2007 (beginning of crisis) in line 339 equals to date=572
*March 2009 (end crisis) in line 357  equals to date= 590
gen crisis=1
replace crisis=0 if date<572
replace crisis=0 if  date>590

*Dummy for ZLB
*the fed funds rate hit the zero lower bound in December 2008
*12.2008 in line 354 equals date=587
gen zlb=0 
replace zlb=1 if date>586




drop Open High Low Vol Change

*Instruments
rename ff4_tc ff4
rename ed2_tc ed2
rename ed3_tc ed3
rename ed4_tc ed4

drop if ed4==.

* ln asset variables
gen lnSP500 = ln(SP500)
gen lnyield_2y= ln(aver_yield_2y)
gen lnyield_5y= ln(aver_yield_5y)
gen lnyield_10y= ln(aver_yield_10y)
gen lnyield_30y= ln(aver_yield_30y)
gen lnyield_3m= ln(aver_yield_3m)
gen lnyield_6m= ln(aver_yield_6m)
gen lnAAA=ln(AAA)
gen lnBAA=ln(BAA)

*use Federal Funds Rate as interest rate
*First difference of the Federal Funds Rate
gen ffchange=D.ff
gen ff_exp1yrchange=D.ff_exp1yr
gen gs1change=D.gs1



*Number of periods
local hmax= 15
*Number of lags
local lmax= 4

*generate leads of the assets
local asset=   " lnSP500 lnyield_2y lnyield_5y lnyield_10y lnyield_30y lnyield_6m lnyield_3m lnAAA lnBAA "
foreach a of local asset {
forvalues h=0/`hmax'{
gen `a'`h'=F`h'.`a'

}
}




drop if ff4==.	

local rate= "ff "	
foreach r of local rate {
 local asset=   " lnSP500 lnyield_2y lnyield_5y lnyield_10y lnyield_30y lnyield_6m lnyield_3m lnAAA lnBAA "
foreach a of local asset {
*Number of periods
local hmax= 15
*Number of lags
local lmax= 4



  
eststo clear
cap drop beta upperbound lowerbound Months Zero
gen Months = _n-1 if _n<=`hmax'+1
gen Zero = 0 if _n<=`hmax'+1
gen beta=0
gen upperbound=0
gen lowerbound= 0
	
	

 quietly forv h = 0/`hmax' {
 ivregress gmm `a'`h' l(1/`lmax').`r' l(1/`lmax').`a'  (`r'change = ff4) if zlb==0 , vce(hac nwest) 

replace beta= _b[`r'change] if _n == `h'+1
*95% CI
replace upperbound= _b[`r'change] + 1.96* _se[`r'change] if _n==`h'+1
replace lowerbound= _b[`r'change] - 1.96* _se[`r'change] if _n==`h'+1
eststo
}
	
*summary of the LP coefficients	
nois esttab, se nocons keep(`r'change)

twoway(rarea upperbound lowerbound Months, fcolor(blue%15) lw(none) lpattern(solid)) (line beta Months, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Months, lcolor(back)), legend(off) ytitle("Percent") note("Notes: 95% confidence bands")  graphregion(color(white)) plotregion(color(white))

*title("Response of the S&P 500 to a monetary shock", color(black) size(med))

graph export IR_`a'_ff4_`r'zlb.pdf ,replace                                    

}	
}








********************** Baseline Regression with lagged logcpi and logip as controlls********************

import excel "Historical_Data",  firstrow clear




*set TS variable
gen date=ym(year,month)
format date %tm
drop month year
tsset date




drop Open High Low Vol Change

*Instruments
rename ff4_tc ff4
rename ed2_tc ed2
rename ed3_tc ed3
rename ed4_tc ed4

drop if ed4==.

* ln asset variables
gen lnSP500 = ln(SP500)
gen lnyield_2y= ln(aver_yield_2y)
gen lnyield_5y= ln(aver_yield_5y)
gen lnyield_10y= ln(aver_yield_10y)
gen lnyield_30y= ln(aver_yield_30y)
gen lnyield_3m= ln(aver_yield_3m)
gen lnyield_6m= ln(aver_yield_6m)
gen lnAAA=ln(AAA)
gen lnBAA=ln(BAA)

*use Federal Funds Rate as interest rate
*First difference of the Federal Funds Rate
gen ffchange=D.ff
gen ff_exp1yrchange=D.ff_exp1yr
gen gs1change=D.gs1



*Number of periods
local hmax= 15
*Number of lags
local lmax= 4

*generate leads of the assets
local asset=   " lnSP500 lnyield_2y lnyield_5y lnyield_10y lnyield_30y lnyield_6m lnyield_3m lnAAA lnBAA "
foreach a of local asset {
forvalues h=0/`hmax'{
gen `a'`h'=F`h'.`a'

}
}




drop if ff4==.	
local rate= "ff "	
foreach r of local rate {
 local asset=   " lnSP500 lnyield_2y lnyield_5y lnyield_10y lnyield_30y lnyield_6m lnyield_3m lnAAA lnBAA "
foreach a of local asset {
*Number of periods
local hmax= 15
*Number of lags
local lmax= 4



  
eststo clear
cap drop beta upperbound lowerbound Months Zero
gen Months = _n-1 if _n<=`hmax'+1
gen Zero = 0 if _n<=`hmax'+1
gen beta=0
gen upperbound=0
gen lowerbound= 0
	
	

 quietly forv h = 0/`hmax' {
 ivregress gmm `a'`h' l(1/`lmax').`r' l(1/`lmax').`a' l.logcpi l.logip (`r'change = ff4) , vce(hac nwest) 

replace beta= _b[`r'change] if _n == `h'+1
*95% CI
replace upperbound= _b[`r'change] + 1.96* _se[`r'change] if _n==`h'+1
replace lowerbound= _b[`r'change] - 1.96* _se[`r'change] if _n==`h'+1
eststo
}
	
*summary of the LP coefficients	
nois esttab, se nocons keep(`r'change)

twoway(rarea upperbound lowerbound Months, fcolor(blue%15) lw(none) lpattern(solid)) (line beta Months, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Months, lcolor(back)), legend(off) ytitle("Percent") note("Notes: 95% confidence bands")  graphregion(color(white)) plotregion(color(white))

*title("Response of the S&P 500 to a monetary shock", color(black) size(med))

graph export IR_`a'_ff4_`r'C.pdf ,replace                                    

}	
}











