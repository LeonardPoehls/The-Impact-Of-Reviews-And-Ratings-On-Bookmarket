

use replication0/confidential_data/master_nielsen.dta, clear

*********************************************************
** Analysis at the title-week level
collapse (sum) sales (min) pubdate, by(ddate rdate titleno notable_year)

gsort titleno ddate
compress

keep if abs(ddate- rdate)<=63

xtset titleno ddate
*********************************************************



*********************************************************
** Variable definitions

gen dv = ln(sales) - ln(L7.sales)

** Control variables
gen goodreview = ddate-rdate>=0 & ddate-rdate<=7
gen age = floor((ddate - pubdate)/7)+1
gen age_at_review = rdate-pubdate
*********************************************************


**************************************
** pick different review years

gen ryear = year(rdate)

capture: drop b se nn 
capture: drop min max 
capture: drop yn 
gen b = 0
gen se = 0
bys ryear: gen nn = floor(_n/7)+1
label var nn "review at least x days after publication"
gen yn = 0 

foreach yy in 2004 2006 2008 2010 2012 2014 2016 2018 {
	areg dv age goodreview if age_at_review>=8 & ddate>=pubdate & notable_year==`yy' & age>=0, absorb(ddate) vce(cluster titleno) 
	replace b = _b[goodreview] if nn ==8 & ryear==`yy'
	replace se = _se[goodreview] if nn == 8 & ryear==`yy'
	replace yn = `yy' if nn == 8 & ryear==`yy'
	
}
	
gen max = b + 1.96*se
gen min = b - 1.96*se


********************************
** Create Figure 4:

twoway (scatter b notable_year) (rcap min max notable_year) if b!=0 & nn==8, ///
yline(0) scheme(lean2) legend(off) xtitle(year of review) ytitle("log sales change coefficient") ///
ylabel(-0.2(0.2)0.8,grid  glcolor(gs1)) 

graph export "results/NYTnotables_effect.pdf", as(pdf) replace

