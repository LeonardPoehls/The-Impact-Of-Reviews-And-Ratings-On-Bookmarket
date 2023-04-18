
use data/main_amazon_sales.dta, clear 

tsset canum ddate
	reghdfe, compile

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
		
		
label var dnytpost1_1 "CA: NYT, 0-5 days"
label var dnytpost1_2 "GB: NYT, 0-5 days"
label var dnytpost1_3 "US: NYT, 0-5 days"
label var dnytpost6_1 "CA: NYT, 6-10 days"
label var dnytpost6_2 "GB: NYT, 6-10 days"
label var dnytpost6_3 "US: NYT, 6-10 days"

label var dnytpost10_1 "CA: NYT, 11-20 days"
label var dnytpost10_2 "GB: NYT, 11-20 days"
label var dnytpost10_3 "US: NYT, 11-20 days"

label var dnytpost1r_3 "US: NYT rec'd, 0-5 days"
label var dnytpost6r_3 "US: NYT rec'd, 6-10 days"
label var dnytpost10r_3 "US: NYT rec'd, 11-20 days"


label var dothpost_1 "CA: other, 1-10 days"
label var dothpost_2 "GB: other, 1-10 days"
label var dothpost_3 "US: other, 1-10 days"
label var dothpost10_1 "CA: other, 11-20 days"
label var dothpost10_2 "GB: other, 11-20 days"
label var dothpost10_3 "US: other, 11-20 days"

drop dnytpost1_5	 dnytpost6_10 	
	
			
*********************************************************************

******************************			


	xtile r50=review, nq(50)
******************************	
	
	reghdfe lrank L1.lrank  lpamzn c.lR#i.r50 i.r50   dnytpost1_* dnytpost6_* dnytpost10_* dothpost_* dothpost10_*  dnytpostpre_* dothpostpre_* dnytpost1r_* dnytpost6r_* dnytpost10r_* dnytpostprer_* epos* eneg*, absorb(canum) vce(robust)
	estimates save "estimates/review_quantiles_50", replace

	reg lreview i.r50 if e(sample)==1
	parmest, fast

		split parm, parse(".r50")
		replace parm1= subinstr(parm1,"1b","1",.)
		gen count =real(parm1)
		rename estimate lr
		keep if count~=.
		keep lr count 
		tempfile lrev
		save `lrev'


	estimates use "estimates/review_quantiles_50"

	parmest, fast

		split parm, parse(".r50#")
		replace parm1= subinstr(parm1,"1b","1",.)
		gen count =real(parm1)
		gen max=max95
		gen min=min95
		label var count "# of reviews grouping"
		drop if count==.
		merge 1:1 count using `lrev'
		

**********************************
** Create Figure 3:

	label var lr "log reviews"
	twoway (scatter estimate lr) (rcap max min lr) if count<=50, scheme(lean2) ///
	legend(off) ytitle(log sales rank effect) yscale(rev)
	graph export "results/gamma_50s_log_reviews.pdf", as(pdf) replace


