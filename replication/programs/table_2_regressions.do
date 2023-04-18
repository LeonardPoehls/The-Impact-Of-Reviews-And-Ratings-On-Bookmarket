log using replication_logs\table_2_log.txt, replace text


use data\main_amazon_sales.dta, clear 

tsset canum ddate
	reghdfe, compile


gen lr2R=(lreview^2)*lR

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
** Column 1: daily review effects
	
** create days-since-review dummies
foreach x in "NYT" "OTH" { 
	forvalues k=0(1) 40 {
		gen D`x'`k'=(`x'_elapse==`k')
	}
	forvalues k=1(1) 20 {
		gen D`x'm`k'=`x'_elapse==-1*`k'
	}
}


*********************
** Column 1 in table

reghdfe lrank L1.lrank lpamzn lreview lR  DNYT* DOTH* epos* eneg* if cno==3, absorb(canum) vce(robust)
estimates save "estimates\daily_param", replace



estimates use "estimates\daily_param"
outreg2 using "results\table_2_causal_effects.tex", keep(L.lrank lpamzn lreview lR) label replace se
*********************


********************************************
** Columns 2-5:

reghdfe lrank L1.lrank  lpamzn lreview lR  dnytpost1_3 dnytpost6_3 dnytpost10_3 dnytpost1r_3 dnytpost6r_3 dnytpost10r_3 dnytpostprer_* dothpost_3 dothpost10_3  dnytpostpre_* dothpostpre_* epos* eneg* if cno==3, absorb(ano) vce(robust)
estimates save "estimates\usreg", replace
estimates use  "estimates\usreg"
outreg2 using results\table_2_causal_effects.tex, keep (L1.lrank lpamzn lreview lR  dnytpost1_3 dnytpost6_3 dnytpost10_3 dnytpost1r_3 dnytpost6r_3 dnytpost10r_3 dothpost_3 dothpost10_3) label se


reghdfe lrank L1.lrank  lpamzn lreview lR lrR  dnytpost1_3 dnytpost6_3 dnytpost10_* dothpost_* dothpost10_*  dnytpostpre_* dothpostpre_* dnytpost1r_3 dnytpost6r_3 dnytpost10r_3 dnytpostprer_* epos* eneg* if cno==3, absorb(ano) vce(robust)
estimates save "estimates\usregint", replace
estimates use "estimates\usregint" 
outreg2 using results\table_2_causal_effects.tex, ///
keep (L1.lrank lpamzn lreview lR  lrR lr2R dnytpost1_3 dnytpost6_3 dnytpost10_3 dnytpost1r_3 dnytpost6r_3 dnytpost10r_3 dothpost_3 dothpost10_3 ) label se


reghdfe lrank L1.lrank  lpamzn lreview lR   dnytpost1_*  dnytpost6_* dnytpost10_* dothpost_* dothpost10_*  dnytpostpre_* dothpostpre_* dnytpost1r_* dnytpost6r_* dnytpost10r_* dnytpostprer_* epos* eneg*, absorb(canum) vce(robust)
estimates save "estimates\3coreg", replace
estimates use "estimates\3coreg"
outreg2 using results\table_2_causal_effects.tex, keep (L1.lrank lpamzn lreview lR dnytpost1_3 dnytpost6_3 dnytpost10_3 dnytpost1r_3 dnytpost6r_3 dnytpost10r_3 dothpost_3 dothpost10_3 ) label se


reghdfe lrank L1.lrank  lpamzn lreview lR  lrR  dnytpost1_* dnytpost6_* dnytpost10_* dothpost_* dothpost10_*  dnytpostpre_* dothpostpre_* dnytpost1r_* dnytpost6r_* dnytpost10r_* dnytpostprer_* epos* eneg*, absorb(canum) vce(robust)
 estimates save "estimates\3coregint", replace
estimates use  "estimates\3coregint"
outreg2 using results\table_2_causal_effects.tex, keep (L1.lrank lpamzn lreview lR lrR lr2R dnytpost1_3 dnytpost6_3 dnytpost10_3 dnytpost1r_3 dnytpost6r_3 dnytpost10r_3 dothpost_3 dothpost10_3 ) label se


log close
