

use "tempfiles/quantity_us_simulations.dta", clear 
	keep asin 
	tempfile asin
	save `asin'

use  "data/main_amazon_sales.dta", clear  
	keep if cno==3
	* drop _merge
	merge m:1 asin using `asin'
	keep if _merge==3 
	drop _merge 
	gen count=_n
	tempfile daily
	save `daily'

use data/A_B_params_bs.dta, clear 
	mvencode counter, mv(0)
	gsort counter 
	gen count=_n
	drop counter 
	merge 1:1 count using `daily'
	drop _merge 
	
cross using data/sigma.dta 


keep A B NYT_elapse cno drecommend dothpost* dnytpost* ddate gno numbooks pubno lreview lrank pamzn OTHDATE R asin DNYT lR sigma sigma_se


* create variables in the regression needed for simulation	
	gen dnytpost1=NYT_elapse>=0 & NYT_elapse<=5
	gen dnytpost6=NYT_elapse>=6 & NYT_elapse<=10

forvalues k =1(1) 3 {
	gen dnytpost1_`k'=dnytpost1*(cno==`k')*(drecommend==0)
	gen dnytpost6_`k'=dnytpost6*(cno==`k')*(drecommend==0)
	gen dnytpost10_`k'=dnytpost10*(cno==`k')*(drecommend==0)
	gen dnytpostpre_`k'=dnytpostpre*(cno==`k')*(drecommend==0)

	gen dothpost_`k'=dothpost*(cno==`k')
	gen dothpost10_`k'=dothpost10*(cno==`k')
	gen dothpostpre_`k'=dothpostpre*(cno==`k')
	
	gen dnytpost1r_`k'=dnytpost1*(cno==`k')*drecommend
	gen dnytpost6r_`k'=dnytpost6*(cno==`k')*drecommend
	gen dnytpost10r_`k'=dnytpost10*(cno==`k')*drecommend
	gen dnytpostprer_`k'=dnytpostpre*(cno==`k')*drecommend
}

	 estimates use  "estimates/3coregint"
	 	matrix m = e(b)
		matrix C = e(V)

	set seed 86 
		drawnorm x1-x45, means(m) cov(C)

		set seed 99
	matrix m = ( sigma[1])
	matrix sd = ( sigma_se[1])
	drop sigma 
	drawnorm  sigma, means(m) sds(sd)


		egen maxdate=max(ddate), by(asin)
		egen avgR=mean(R), by(asin)
		areg  avgR i.gno  i.numbooks  if ddate==maxdate, absorb(pubno)
		predict Rhat 
		gen lRhat=ln(Rhat)

	

forvalues k = 1 (1) 500 { 
preserve 

	gen xA			= A if _n==`k'
	gen xB			= B if _n==`k'
	gen xsigma		= sigma if _n==`k'
	gen xalpha		= x2 if _n==`k'
	gen xgamma		= x4 if _n==`k'
	gen xgamma1		= x5 if _n==`k'
	gen xtheta		= x1 if _n==`k'
	gen xbnyt1_5	= x8 if _n==`k'
	gen xbnyt6_10 	= x11 if _n==`k'
	gen xbnyt10 	= x14  if _n==`k'
	gen xboth 		= x17  if _n==`k'
	gen xboth10 	= x20 if _n==`k'
	gen xbnyt1_5r	= x29 if _n==`k'
	gen xbnyt6_10r 	= x32 if _n==`k'
	gen xbnyt10r 	= x35  if _n==`k'

	egen bs_A=mean(xA)
	egen bs_B=mean(xB)
	egen bs_sigma=mean(xsigma)
	egen bs_alpha=mean(xalpha)
	egen bs_gamma=mean(xgamma)
	egen bs_gamma1=mean(xgamma1)
	egen bs_theta=mean(xtheta)
	egen bs_bnyt1_5=mean(xbnyt1_5)
	egen bs_bnyt6_10=mean(xbnyt6_10)
	egen bs_bnyt10=mean(xbnyt10)
	egen bs_both=mean(xboth)
	egen bs_both10=mean(xboth10)
	egen bs_bnyt1_5r=mean(xbnyt1_5r)
	egen bs_bnyt6_10r=mean(xbnyt6_10r)
	egen bs_bnyt10r=mean(xbnyt10r)

		gen double q = bs_A/exp(bs_B*lrank)
		
		gen bs_gamma2=0
		replace bs_gamma2 = bs_B*(bs_gamma+bs_gamma1*lreview)/(1-bs_theta) if lreview~=. & lR~=.   
		gen bs_alpha1 = bs_B*bs_alpha/(1-bs_theta)
	
		
		gen e = bs_B*((bs_bnyt1_5*dnytpost1_3 +  bs_bnyt6_10*dnytpost6_3 + bs_bnyt10*dnytpost10_3 + bs_both*dothpost_3 + bs_both10*dothpost10_3 + ///
		bs_bnyt1_5r*dnytpost1r_3 + bs_bnyt6_10r*dnytpost6r_3 + bs_bnyt10r*dnytpost10r_3))/(1-bs_theta)
		
		gen double q1 = bs_A/exp(bs_B*lrank - e)		

		rename pamzn p
		gen DOTH=OTHDATE~=.

collapse (sum) q q1 (mean) e bs_gamma2 bs_alpha1 p lR lRhatx=lRhat R Rhat bs_sigma (max) DNYT DOTH lreview drecommend, by(asin)
save tempfiles/quantity_us_simulations_bs_`k'.dta, replace

}
