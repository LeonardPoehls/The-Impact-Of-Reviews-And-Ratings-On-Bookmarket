


use "tempfiles/quantity_us_simulations.dta", clear 
	keep asin 
	tempfile asin
	save `asin'

use  "data/main_amazon_sales.dta", clear  
	xtile r50 = review, nq(50)

	keep if cno==3
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


keep A B NYT_elapse cno drecommend dothpost* dnytpost* ddate gno numbooks pubno lreview lrank pamzn OTHDATE R asin DNYT lR lpamzn canum pelapse review sigma sigma_se r50


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

drop dnytpost1_5 dnytpost6_10

	 estimates use  "estimates/review_quantiles_50"
	 	matrix m = e(b)
		matrix C = e(V)
		
		
	set seed 86 
		drawnorm x1-x132, means(m) cov(C)

	set seed 99
		matrix m = ( sigma[1])
		matrix sd = ( sigma_se[1])
		drop sigma 
		drawnorm  sigma, means(m) sds(sd)
	
	drop x49-x93 

		egen maxdate=max(ddate), by(asin)
		egen avgR=mean(R), by(asin)
		areg  avgR i.gno  i.numbooks  if ddate==maxdate, absorb(pubno)
		predict Rhat 
		gen lRhat=ln(Rhat)

	

forvalues k = 261 (1) 500 { 
	preserve 
	gen bs_A		= A if _n==`k'
	gen bs_B		= B if _n==`k'
	gen bs_sigma		= sigma if _n==`k'
	gen bs_alpha		= x2 if _n==`k'
	gen bs_theta		= x1 if _n==`k'

	gen bs_g1	=x3	 if _n==`k'
	gen bs_g4	=x4	 if _n==`k'
	gen bs_g6	=x5	 if _n==`k'
	gen bs_g8	=x6	 if _n==`k'
	gen bs_g9	=x7	 if _n==`k'
	gen bs_g11	=x8	 if _n==`k'
	gen bs_g12	=x9	 if _n==`k'
	gen bs_g13	=x10	 if _n==`k'
	gen bs_g14	=x11	 if _n==`k'
	gen bs_g15	=x12	 if _n==`k'
	gen bs_g16	=x13	 if _n==`k'
	gen bs_g17	=x14	 if _n==`k'
	gen bs_g18	=x15	 if _n==`k'
	gen bs_g19	=x16	 if _n==`k'
	gen bs_g20	=x17	 if _n==`k'
	gen bs_g21	=x18	 if _n==`k'
	gen bs_g22	=x19	 if _n==`k'
	gen bs_g23	=x20	 if _n==`k'
	gen bs_g24	=x21	 if _n==`k'
	gen bs_g25	=x22	 if _n==`k'
	gen bs_g26	=x23	 if _n==`k'
	gen bs_g27	=x24	 if _n==`k'
	gen bs_g28	=x25	 if _n==`k'
	gen bs_g29	=x26	 if _n==`k'
	gen bs_g30	=x27	 if _n==`k'
	gen bs_g31	=x28	 if _n==`k'
	gen bs_g32	=x29	 if _n==`k'
	gen bs_g33	=x30	 if _n==`k'
	gen bs_g34	=x31	 if _n==`k'
	gen bs_g35	=x32	 if _n==`k'
	gen bs_g36	=x33	 if _n==`k'
	gen bs_g37	=x34	 if _n==`k'
	gen bs_g38	=x35	 if _n==`k'
	gen bs_g39	=x36	 if _n==`k'
	gen bs_g40	=x37	 if _n==`k'
	gen bs_g41	=x38	 if _n==`k'
	gen bs_g42	=x39	 if _n==`k'
	gen bs_g43	=x40	 if _n==`k'
	gen bs_g44	=x41	 if _n==`k'
	gen bs_g45	=x42	 if _n==`k'
	gen bs_g46	=x43	 if _n==`k'
	gen bs_g47	=x44	 if _n==`k'
	gen bs_g48	=x45	 if _n==`k'
	gen bs_g49	=x46	 if _n==`k'
	gen bs_g50	=x47	 if _n==`k'

	gen bs_bnyt1_5		= x95 if _n==`k'
	gen bs_bnyt6_10 	= x98 if _n==`k'
	gen bs_bnyt10 		= x101  if _n==`k'
	gen bs_both 		= x104  if _n==`k'
	gen bs_both10 		= x107 if _n==`k'
	gen bs_bnyt1_5r		= x116 if _n==`k'
	gen bs_bnyt6_10r 	= x119 if _n==`k'
	gen bs_bnyt10r 		= x122 if _n==`k'



	gsort bs_A
	replace bs_A = bs_A[_n-1] if bs_A==.
	replace bs_B = bs_B[_n-1] if bs_B==.
	replace bs_sigma = bs_sigma[_n-1] if bs_sigma==.
	replace bs_alpha = bs_alpha[_n-1] if bs_alpha==.
	replace bs_theta = bs_theta[_n-1] if bs_theta==.

	replace bs_g1 = bs_g1[_n-1] if bs_g1==.
	replace bs_g4 = bs_g4[_n-1] if bs_g4==.
	replace bs_g6 = bs_g6[_n-1] if bs_g6==.
	replace bs_g8 = bs_g8[_n-1] if bs_g8==.
	replace bs_g9 = bs_g9[_n-1] if bs_g9==.

	forvalues i=11(1)50{
		replace bs_g`i' = bs_g`i'[_n-1] if bs_g`i'==.
	}

	foreach i in nyt1_5 nyt6_10 nyt10 oth oth10 nyt1_5r nyt6_10r nyt10r {
		replace bs_b`i' = bs_b`i'[_n-1] if bs_b`i'==.
	}

	gen bs_alpha1 = bs_B*bs_alpha/(1-bs_theta)
		
	gen bs_gamma2=0
	replace bs_gamma2 = bs_B*(bs_g1*(r50==1) + ///
		bs_g4*(r50==4) + ///
		bs_g6*(r50==6) + ///
		bs_g8*(r50==8) + ///
		bs_g9*(r50==9) + ///
		bs_g11*(r50==11) + ///
		bs_g12*(r50==12) + ///
		bs_g13*(r50==13) + ///
		bs_g14*(r50==14) + ///
		bs_g15*(r50==15) + ///
		bs_g16*(r50==16) + ///
		bs_g17*(r50==17) + ///
		bs_g18*(r50==18) + ///
		bs_g19*(r50==19) + ///
		bs_g20*(r50==20) + ///
		bs_g21*(r50==21) + ///
		bs_g22*(r50==22) + ///
		bs_g23*(r50==23) + ///
		bs_g24*(r50==24) + ///
		bs_g25*(r50==25) + ///
		bs_g26*(r50==26) + ///
		bs_g27*(r50==27) + ///
		bs_g28*(r50==28) + ///
		bs_g29*(r50==29) + ///
		bs_g30*(r50==30) + ///
		bs_g31*(r50==31) + ///
		bs_g32*(r50==32) + ///
		bs_g33*(r50==33) + ///
		bs_g34*(r50==34) + ///
		bs_g35*(r50==35) + ///
		bs_g36*(r50==36) + ///
		bs_g37*(r50==37) + ///
		bs_g38*(r50==38) + ///
		bs_g39*(r50==39) + ///
		bs_g40*(r50==40) + ///
		bs_g41*(r50==41) + ///
		bs_g42*(r50==42) + ///
		bs_g43*(r50==43) + ///
		bs_g44*(r50==44) + ///
		bs_g45*(r50==45) + ///
		bs_g46*(r50==46) + ///
		bs_g47*(r50==47) + ///
		bs_g48*(r50==48) + ///
		bs_g49*(r50==49) + ///
		bs_g50*(r50==50) )/ (1-bs_theta) if lreview~=. & lR~=. 
	 

	gen e = bs_B*((bs_bnyt1_5*dnytpost1_3 +  bs_bnyt6_10*dnytpost6_3 + bs_bnyt10*dnytpost10_3 + bs_both*dothpost_3 + bs_both10*dothpost10_3 + ///
	bs_bnyt1_5r*dnytpost1r_3 + bs_bnyt6_10r*dnytpost6r_3 + bs_bnyt10r*dnytpost10r_3))/(1-bs_theta)
					

	gen double q = bs_A/exp(bs_B*lrank)
	gen double q1 = bs_A/exp(bs_B*lrank - e)		

		rename pamzn p
		gen DOTH=OTHDATE~=.

	collapse (sum) q q1 (mean) e bs_gamma2 bs_alpha1 p lR lRhatx=lRhat R Rhat bs_sigma (max) DNYT DOTH lreview drecommend, by(asin)
	save  tempfiles/quantity_us_simulations_50_quantiles_bs_`k'.dta, replace

restore
}
