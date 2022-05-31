clear 
version 17
set more off
capture log close
log using an2, replace



ssc install csipolate
ssc install  diagreg2
ssc install hprescott

*Path name here cd ""  





import excel "Real_GDP",  sheet("RealGDP") firstrow clear

gen month=month(date_2)
gen year=year(date_2)
gen date_3=ym(year,month)
format date_3 %tm
tsset date_3


*csipolate creates newvar by averaging non-missing values of yvar and using natural cubic spline interpolation of missing values of yvar, given xvar. That is, provided that xvar is not missing,

* 1. When yvar is not missing, newvar is the mean of yvar over observations with the same value of xvar. If a value of xvar is unique, then each mean is just the same as the value of yvar at that point.

*2. When yvar is missing, newvar is filled in using natural cubic spline interpolation.

csipolate realGDP date_2, generate(realGDPinterp)

* Like in Auerbach and Gorodnichenko (2013) set smoothing paramenter to 10,000 --> smooth(10000)
* Hodrick–Prescott filter for realGDPinterp to obtain cyclical component ct and trend component

tsfilter hp realGDPinterp_ct=realGDPinterp, trend(realGDPinterp_trendvar) smooth(10000)
*standard deviation od cyclical component
egen sd_realGDPinterp_ct=sd(realGDPinterp_ct)
*standardising cyclical component
*which is the z in the Auerbach paper equal the normalised deviations from the trend. 
*standardised z is supposed to have mean 0 and variance 1
gen stand_z=realGDPinterp_ct/sd_realGDPinterp_ct



*calculate the probability of being in a recession unsing the cdf of the normal distributin assuming that the deviations from the trend are normally distributed
gen pr_recession_gdp=normal(stand_z)



*Output gap
gen outputgap=realGDP-realpotentialGDP
csipolate outputgap date_2, generate(gapinterp)


export excel "Real_GDP" , sheet("Interpol") firstrow (variables) 




********************Industrial Production********************

import excel "INDPRO",   firstrow clear


gen month=month(observation_date)
gen year=year(observation_date)
gen date_2=ym(year,month)
format date_2 %tm
tsset date_2
*Use the Hodrick–Prescott filter for INDPRO to obtain cyclical component ct using tsset data and save the trend component in the variable trendvar

tsfilter hp INDPRO_ct=INDPRO, trend(INDPRO_trendvar)

*standard deviation od cyclical component
egen sd_INDPRO_ct=sd(INDPRO_ct)
*standardising cyclical component
*which is the z in the Auerbach paper equal the normalised deviations from the trend. 
*standardised z is supposed to have mean 0 and variance 1
gen stand_z=INDPRO_ct/sd_INDPRO_ct



*calculate the probability of being in a recession unsing the cdf of the normal distributin assuming that the deviations from the trend are normally distributed
gen pr_recession_indpro=normal(stand_z)




export excel "INDPRO" , sheet("HP") firstrow (variables) replace


*****************S&P 500 data - create monthly average of daily close index prices********************

import excel "SPGlobal_Export",  sheet("Raw") firstrow clear


gen month=month(date)
gen year=year(date)
gen date_2=ym(year,month)
format date_2 %tm
*Monthly average of S&P500
bysort date_2: egen SP500 = mean(SPX)

export excel "SPGlobal_Export" , sheet("Average") firstrow (variables) 
 
duplicates drop date_2 , force
export excel "SPGlobal_Export" , sheet("Average monthly") firstrow (variables) 
 

*******************US government bond date - create monthly average of daily yields********************

  
 local bonds=" 3m  6m 2y 5y 10y 30y"
foreach b of local bonds {
import excel "USbond_yields", sheet("`b'") firstrow clear

gen month=month(date)
gen year=year(date)
gen date_2=ym(year,month)
format date_2 %tm
*Monthly average of yield
bysort date_2: egen aver_yield_`b' = mean(YIELD_`b')

duplicates drop date_2 , force
export excel "USbond_yields" , sheet("monthly_aver_`b'") firstrow (variables) 

}



