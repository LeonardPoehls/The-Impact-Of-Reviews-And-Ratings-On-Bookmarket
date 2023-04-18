

***********************************************
* the below creates standard errors for the top half of Table 3:


use "data/A_B_params_bs.dta", clear
	replace counter=0 if counter==.  
	replace counter=counter+1
	tempfile bbs 
	save `bbs'
	
use "data/main_amazon_sales.dta", clear
	keep if cno==3 
	gen counter=_n
	merge 1:1 counter using `bbs'
	
	keep A B lreview 

	estimates use  "estimates/3coregint"
	 	matrix m = e(b)
		matrix C = e(V)
		
		* keep if cno==3
	
		set seed 86 
		drawnorm x1-x45, means(m) cov(C)


	gen alpha		= x2 
	gen gamma		= x4 
	gen gamma1		= x5 
	gen theta		= x1 
	gen bnyt1_5		= x8 
	gen bnyt6_10 	= x11 
	gen bnyt10 		= x14  
	gen both 		= x17  
	gen both10 		= x20 
	gen bnyt1_5r	= x29
	gen bnyt6_10r 	= x32
	gen bnyt10r 	= x35
			
	egen l25 =pctile(lreview), p(25)
	egen l50 =pctile(lreview), p(50)
	egen l75 =pctile(lreview), p(75)

	egen lmean=mean(lreview)

* quartiles

gen star25= B*(gamma+gamma1*l25)/(1 - theta)
gen star50= B*(gamma+gamma1*l50)/(1 - theta)
gen star75= B*(gamma+gamma1*l75)/(1 - theta)
gen starmean= B*(gamma+gamma1*lmean)/(1 - theta)

gen elasP = B*alpha/(1-theta)

gen nyt1 = B*bnyt1_5/(1-theta)
gen nyt6 =  B*bnyt6_10/(1-theta)
gen nyt10 = B*bnyt10/(1-theta)

gen nyt1r = B*bnyt1_5r/(1-theta)
gen nyt6r =  B*bnyt6_10r/(1-theta)
gen nyt10r = B*bnyt10r/(1-theta)

gen oth = B*both/(1-theta)
gen oth10 = B*both10/(1-theta)

*****************************
** This creates standard errors for the top half of Table 3:


keep if _n>1 
foreach i in elasP star25 star50 star75 starmean nyt1 nyt6 nyt10 nyt1r nyt6r nyt10r oth oth10 {
	su `i'
	gen `i'_sd = r(sd)
} 


log using replication_logs/table_3_bs_log.txt, replace text 

** This produces the std. errors for the top panel of Table 3:
 	fsum *_sd, format(%9.3f)
	
log off 

***********************************************
* the below creates standard errors for the bottom half of Table 3:

clear
set obs 1
gen x = .
save tempfiles/table_3_ses.dta, replace

* the code reads files created in create_quantity_us_simulations_bs.do

forvalues k = 1(1) 500 { 
use tempfiles/quantity_us_simulations_bs_`k'.dta, clear

	collapse (mean) DNYT DOTH drecommend q q1, by(asin)

	gen change=100*((q/q1)-1)
	
	qui: su change if DNYT==0 & DOTH==1
	gen other_only = r(mean)

	qui: su change if DNYT==1 & DOTH==0 & drecommend==0
	gen nyt_not_rec_only = r(mean)

	qui: su change if DNYT==1 & DOTH==0 & drecommend==1
	gen nyt_rec_only = r(mean)

	qui: su change if DNYT==1 & DOTH==1 & drecommend==0
	gen both_not_rec = r(mean)

	qui: su change if DNYT==1 & DOTH==1 & drecommend==1
	gen both_rec = r(mean)

	qui: su change if DNYT==1 
	gen nytoverall=r(mean)

	qui: su change if DNYT+DOTH>=1 
	gen overall=r(mean)

keep other_only nyt_not_rec_only nyt_rec_only both_not_rec both_rec overall nytoverall
collapse (mean) other_only nyt_not_rec_only nyt_rec_only both_not_rec both_rec overall nytoverall

append using tempfiles/table_3_ses.dta
sleep 10
save tempfiles/table_3_ses.dta, replace

}

use  tempfiles/table_3_ses.dta, clear

keep if _n>1 

foreach i in other_only nyt_not_rec_only nyt_rec_only both_not_rec both_rec overall {
	qui: su `i'
	gen `i'_sd = r(sd)	
}

log on 
	
* This produces the std. errors for the bottom panel of Table 3.
	
	fsum *_sd, format(%9.3f)


**********************************

log close 
