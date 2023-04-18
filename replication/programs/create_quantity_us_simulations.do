
use data/main_amazon_sales.dta, clear 
cross using data/A_B_params.dta 
cross using data/sigma.dta 

tsset canum ddate
reghdfe, compile

	 
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

********************
* choose sample 

keep if cno==3 

*******************************************************
* CHOOSE WHICH OBSERVATIONS TO USE FOR THE SIMULATION 
*******************************************************

	 estimates use  "estimates/3coregint"
	 
	gen gamma1=0
	replace gamma1 = B*(_b[lR]+lreview*_b[lrR])/(1-_b[L1.lrank]) if lreview~=. & lR~=.  
	gen alpha1 = B*_b[lpamzn]/(1-_b[L1.lrank])
	

	gen e1 = B*(_b[dnytpost1_3]*dnytpost1_3 +  _b[dnytpost6_3]*dnytpost6_3 + ///
	_b[dnytpost10_3]*dnytpost10_3 + _b[dothpost_3]*dothpost_3 + _b[dothpost10_3]*dothpost10_3 + ///
	_b[dnytpost1r_3]*dnytpost1r_3 +  _b[dnytpost6r_3]*dnytpost6r_3 + _b[dnytpost10r_3]*dnytpost10r_3 )/(1-_b[L1.lrank])

	gen double q1 = (A)/exp(B*lrank - e1)	
	gen double q = (A)/exp(B*lrank)		

	******************************

	
*************************************************************************
* Then, get Rhat and collapse to title level
*************************************************************************
	
	******************************
	* get Rhat

	egen maxdate=max(ddate), by(asin)
	egen avgR=mean(R), by(asin)
	
	areg  avgR i.gno  i.numbooks  if cno==3 & ddate==maxdate, absorb(pubno)
	predict Rhat  
	gen lRhat = ln(Rhat)

	******************************

	
	******************************
	* collapse to asin level
	
	rename pamzn p
	gen DOTH=OTHDATE~=.
	
	collapse (sum) q q1 (mean) e* gamma* alpha* p lR lRhat R Rhat sigma avgR ///
	(max) DNYT DOTH DUSAT lreview drecommend, by(asin genre)
	
	save  tempfiles/quantity_us_simulations.dta, replace

