log using replication_logs/create_sigma_log.txt, replace text

set seed 9489

use data/nielsen_top100.dta, clear
	merge m:1 year week using data/pw_weekly.dta
	drop _merge


*******************************************
** Determine correlation coefficient sigma


*************************
** Create variables to set up nested logit
gen age=ddate-pdate
egen tno=group(title)

* assume each American decides to read a book once a month
gen M = 327200000*.25

** Market shares
gen sj=sales/M
gen s0 = 1-(quantity*1000)/M
gen sin=sales/(quantity*1000)

** nested logit variables
gen dv = ln(sj) - ln(s0)
gen lsin = ln(sin)
*************************


*************************
** Create BLP-esque instruments 

gen lpsales = ln(prior_sales+1)
xtile dlpsales = lpsales, nq(10)

** number of books from each psales quantile each week
gen dlpsales1 = dlpsales==1
egen num_dlpsales1 = sum(dlpsales1), by(ddate)
forvalues i=4(1)10{
	gen dlpsales`i' = dlpsales==`i'
	egen num_dlpsales`i' = sum(dlpsales`i'), by(ddate)
}

** number of books from each vintage by week
forvalues k=7(7) 70 {
	gen d`k'=age<=`k'
	egen num_new`k'=sum(d`k'), by(ddate)
}
*************************



*************************
** Run IV lasso regressions

ivlasso dv (i.week) (lsin = num_new* num_dlpsales*), first idstats

*************************

*******************************************
** save sigma coefficient: 

gen sigma = _b[lsin]
gen sigma_se = _se[lsin]
keep sigma sigma_se
keep if _n==1 

save data/sigma.dta, replace 

log close
