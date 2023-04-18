

use tempfiles/quantity_us_simulations.dta, clear
	keep asin
	duplicates drop 
	tempfile simulation_asins 
	save `simulation_asins'
	


import delimited "data/Books.csv",  encoding(UTF-8) colrange(1:3) clear
	drop v2 
	rename v1 asin
	rename v3 stars 
	merge m:1 asin using `simulation_asins'
	keep if _merge==3 
	drop _merge 
	tempfile micro_level_book_ratings
	save `micro_level_book_ratings'
	
	keep asin 
	duplicates drop
	
	merge 1:1 asin using tempfiles/quantity_us_simulations.dta
	
	keep if _merge==3 
	drop _merge 

	tempfile overlap 
	save `overlap'
	
	
	


***************************** 
** Nested logit calibration 
***************************** 	

clear 
set obs 1
gen x=.
save tempfiles/welfare_effects_WOM.dta, replace  
 
 foreach N in 5 10 20  { 
	forvalues k=1(1) 100 {

	use `micro_level_book_ratings', clear  

		egen s=mean(stars), by(asin)
		local m = 86 + `N' + 100*`k'
		set seed `m' 
		sample `N', by(asin) count
		
		collapse (mean) stars`N' = stars stars=s, by(asin)
		compress
		
		merge 1:1 asin using `overlap'
	
		gen M = 12*327.2*1000000
		
		egen Q=sum(q)
		egen Q1=sum(q1)

		gen s=q/M
		gen s0 = 1 - Q/M
		gen s_in=Q/M
		gen s_jin=q/Q
		
		* calculate the nested logit parameters from the elasticities:
		
		gen ALPHA = alpha1*(1-sigma)/((1-sigma*s_jin-(1-sigma)*s)*p)
		reg ALPHA
		replace ALPHA = _b[_cons]

		gen GAMMA = -gamma1*(1-sigma)/((1-sigma*s_jin-(1-sigma)*s)*R)
		
		gen PSI = ln(q/q1)*(1-sigma)
		drop q1

** create new "expected" stars from micro reviews:		
		drop R Rhat
		gen R=stars
		gen Rhat = stars`N'
		replace Rhat=stars if stars`N'==.		
	
	** Deltas:
		gen delta=ln(s) - ln(s0) - sigma*ln(s/(1-s0))
 		gen delta_1 = delta - GAMMA*(R-Rhat)
 		replace delta_1 = delta if delta_1==. | R==. | lreview==.
		gen delta_2 = delta - PSI 

	** Counterfactual for ratings
		gen exb_1=exp(delta_1/(1-sigma))
		egen D_1=sum(exb_1)
		gen s1_in = [D_1^(1-sigma)]/[1+D_1^(1-sigma)]
		gen s1=[exb_1/(D_1)]*s1_in
		gen q1=M*s1
		
	** Actual consumer surplus
		gen xcs  = exp(delta/(1-sigma))
		egen xCS = sum(xcs)
		gen CS = log(1+xCS^(1-sigma))*(M/ALPHA)
		
	** Counterfactual CS - ratings
		gen xcs1  = exp(delta_1/(1-sigma))
		egen xCS1 = sum(xcs1)
		gen CS1 = log(1+xCS1^(1-sigma))*(M/ALPHA)
		
	** Adjustments:	
		replace Rhat=0 if Rhat==. | R==.
		replace R=0 if R==. 
		
		gen adj1 = (GAMMA/ALPHA)*(R-Rhat)*q1 
		egen ADJ1 = sum(adj1)
		
		gen double dCS_ratings = CS - (CS1 + ADJ1)
		
		gen N=`N'
		gen count=`k'
		keep dCS_ratings  N count
		collapse (mean) dCS_ratings  N count
		
		append using tempfiles/welfare_effects_WOM.dta  
		save tempfiles/welfare_effects_WOM.dta, replace  
		
	}
}

*********************************

* this scales the delta CS1 to the population level (for ease of comparison)  
* Hence the comparisons to population delta CS_reviews ($3.18 mil)

use tempfiles/welfare_effects_WOM.dta, clear

	gen scale = 695*0.445/148.4054
	gen dCS_ratings_adj = dCS_ratings*scale/1000000

	gen ratio= dCS_ratings_adj/3.18

log using replication_logs/text_welfare_effects_WOM_log.txt, replace text

	table N, c(mean ratio)

log close

