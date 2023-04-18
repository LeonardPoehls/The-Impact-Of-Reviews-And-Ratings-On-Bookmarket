

********************************************************************
* Substitutability section
	* effect of star ratings before and after pro review
********************************************************************


*************************************************
** effect of star ratings before and after pro review

use data/main_amazon_sales.dta, clear 

	tsset canum ddate
	reghdfe, compile

	******************************
	** review variables:

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
			
	drop dnytpost1_5	 dnytpost6_10 	
	******************************

		
	******************************
	** interactions: 

	gen DOTH = OTHDATE~=.
	gen DPRO=(DNYT + DOTH>0)
	gen DPRO_post = DPRO*(( NYT_elapse >=0 & NYT_elapse~=. ) | (OTH_elapse>=0 & OTH_elapse~=.))
	gen DPRO_pre = DPRO*(1-DPRO_post)

	gen lR_pro = DPRO_post*lR
	gen lR_not_pro = (1-DPRO)*lR
	gen lR_pre_pro = DPRO_pre*lR
	******************************


	
	
log using replication_logs/text_numbers_section7_log.txt, replace text 
	
	******************************
	** regression: 

	reghdfe lrank L1.lrank lpamzn c.DPRO_post#c.lpamzn  lR c.DPRO_post#c.lR  ///
		lreview c.DPRO_post#c.lreview  lrR c.DPRO_post#c.lrR ///
		dnytpost1_* dnytpost6_* dnytpost10_* dothpost_* dothpost10_*  dnytpostpre_* dothpostpre_* ///
		epos* eneg* if DPRO==1 , absorb(canum) vce(robust)

*************************************************

log close 

