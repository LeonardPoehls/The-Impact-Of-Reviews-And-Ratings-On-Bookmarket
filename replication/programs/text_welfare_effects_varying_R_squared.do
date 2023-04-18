

**************************************************************
* create file for appending results 
clear 
set obs 1 
gen x=. 
save tempfiles/welfare_effects_varying_R_squared.dta, replace
**************************************************************


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
*********************		

keep if cno==3 


*******************************************************
* create parameters and counterfactual quantity
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

	
	su gamma* alpha*
	******************************
******************************************************* 
*gen DPRO=DNYT==1 | OTHDATE~=.
* table DPRO, c(sum q) row col


*************************************************************************
* Then, get Rhat and collapse to title level
* various r-squareds
*************************************************************************
		
		******************************
	* get Rhat

	egen maxdate=max(ddate), by(asin)
	egen double avgR=mean(R), by(asin)
		
		

		* drawnorm epsilon
	set seed 10
	gen double epsilon=rnormal(0,10)

	gen double magic=0

	foreach k in 1000 500 100 75 50 25 10 5 1 {
		set seed `k'
		drop epsilon
		gen double epsilon=rnormal(0,10)
		replace magic = avgR + (1/`k')*epsilon
		areg  avgR i.gno  i.numbooks  magic if cno==3 & ddate==maxdate, absorb(pubno)
		predict Rhat`k'
		gen double lRhat`k'=ln(Rhat`k')
		gen double r2_`k'=e(r2)
	}
		
		
	areg  avgR i.gno i.numbooks if  cno==3 & ddate==maxdate, absorb(pubno)
	predict Rhat11
	gen double lRhat11=ln(Rhat11)
	gen double r2_11=e(r2)

		
	reg  avgR  if cno==3 &  ddate==maxdate
	predict Rhat12
	gen double lRhat12=ln(Rhat12)
	gen double r2_12=e(r2)

	
	gen lavgR=ln(avgR)

	rename pamzn p
	gen DOTH=OTHDATE~=.
	
	collapse (sum) q q1 (mean) e* gamma* alpha* p lR lRhat* R Rhat* r2_* sigma avgR (max) DNYT DOTH DGR DPW DUSAT lreview drecommend, by(asin genre)



********************************************************************************		
	
	

		
	
**********************		
foreach j in 1000 500 100 75 50 25 10 5 1 11 12 {
		
	
		preserve 
	
	******************************
	* define variables 
		gen double M = 12*327.2*1000000
		
		egen double Q=sum(q)
		egen double Q1=sum(q1)

		gen double s=q/M
		gen double s0 = 1 - Q/M
		gen double s_in=Q/M
		gen double s_jin=q/Q
	******************************

	
	******************************
	* calculate the NL parameters from the elasticities:
		
		gen double ALPHA = alpha1*(1-sigma)/((1-sigma*s_jin-(1-sigma)*s)*p)
		reg ALPHA
		replace ALPHA = _b[_cons]

		gen double GAMMA = -gamma1*(1-sigma)/((1-sigma*s_jin-(1-sigma)*s)*R)
		replace GAMMA = 0 if GAMMA==. | lreview==.

		gen double PSI = ln(q/q1)*(1-sigma)
		drop q1  /* no longer need this, we calculate it using logit formulas below */
	******************************
	
	
	******************************
	* Actual and counterfactual deltas & shares
	
		** Deltas:
		gen double delta=ln(s) - ln(s0) - sigma*ln(s/(1-s0))
		gen double delta_1 = delta - GAMMA*(R-Rhat`j')
		replace delta_1 = delta if delta_1==. | R==. | lreview==.
		gen double delta_2 = delta - PSI 
		

		** Counterfactual for ratings
		gen double exb_1=exp(delta_1/(1-sigma))
		egen double D_1=sum(exb_1)
		gen double s1_in = [D_1^(1-sigma)]/[1+D_1^(1-sigma)]
		gen double s1=[exb_1/(D_1)]*s1_in
		gen double q1=M*s1
				
		** Counterfactual for reviews
		gen double exb_2=exp(delta_2/(1-sigma))
		egen double D_2=sum(exb_2)
		gen double s2_in = [D_2^(1-sigma)]/[1+D_2^(1-sigma)]
		gen double s2=[exb_2/(D_2)]*s2_in
		gen double q2=M*s2

	******************************


	******************************
	** Consumer surplus calculations

		** Actual consumer surplus
		gen double xcs  = exp(delta/(1-sigma))
		egen double xCS = sum(xcs)
		gen double CS = log(1+xCS^(1-sigma))*(M/ALPHA)
		
		** Counterfactual CS - ratings
		gen double xcs1  = exp(delta_1/(1-sigma))
		egen double xCS1 = sum(xcs1)
		gen double CS1 = log(1+xCS1^(1-sigma))*(M/ALPHA)
		
		** Counterfactual CS - reviews
		gen double xcs2  = exp(delta_2/(1-sigma))
		egen double xCS2 = sum(xcs2)
		gen double CS2 = log(1+xCS2^(1-sigma))*(M/ALPHA)
	******************************

	replace Rhat`j'=0 if Rhat`j'==. | R==.
	replace R=0 if R==. 

	******************************
	** Adjustments & revenues

		gen double adj1 = (GAMMA/ALPHA)*(R-Rhat`j')*q1 
		replace  adj1 = 0 if adj1==.

		gen double adj2 = (PSI/ALPHA)*q2 
		egen double ADJ1 = sum(adj1)
		egen double ADJ2 = sum(adj2)
		
	******************************
		
		
	******************************
	** keep totals & save 
		
	collapse (mean) CS CS1 CS2  ADJ1 ADJ2  r2_`j' 
		
	append using tempfiles/welfare_effects_varying_R_squared.dta
	save tempfiles/welfare_effects_varying_R_squared.dta, replace

	restore 
	******************************

}
********************************************************************************		




********************************************************************************		
********************************************************************************		

******************************
** re-create scaling factor

	 use  tempfiles/quantity_us_simulations.dta, clear

	* find the sample total quantity (to feed scaling)
	gen qmil=q/1000000
	* scaling 
	egen sample_q=sum(qmil) /* our estimate of the units of sample books sold */
	gen samzn = 0.445   /* our estimate of Amazon's share */
	gen qagg=695 		/* estimate of units of physical books sold in the US in 2018 */
	gen scale = (qagg*samzn/sample_q)  /*the weight to translate sample results for stars into "aggregate sales" */
	su scale 
	local sc=r(mean)  /*create scaling factor used at the end of the program */
******************************


use  tempfiles/welfare_effects_varying_R_squared.dta, clear 

	* create variable
	egen double R2=rmean(r2_*)
******************************


	* sample dCS
	gen dCS_stars = (CS - CS1 - ADJ1) / 1000000
	gen dCS_reviews = (CS - CS2 - ADJ2) / 1000000
	
	
	** Scale up to get total CS effects for stars
	gen dCS_stars_adj = dCS_stars*`sc'
	
	gen ratio = dCS_stars_adj/dCS_reviews
	
	*  baseline result: note that dCS1 is scaled, as is DREV1
	
log using replication_logs/text_welfare_effects_varying_R_squared_log.txt, replace text 
	
	su dCS_stars_adj dCS_reviews ratio

log close 

	gsort R2
	
	
	
* this picture illustrates the claims in section 6.1.1
	
	twoway (line ratio R2 if R2>0.324) (scatter ratio R2 if R2<0.340), scheme(lean2)  ///
	legend(off) ///
	xtitle(quality prediction R squared) ytitle("{&Delta}(CS) from stars / {&Delta}(CS) from pro reviews") xline(0.5 0.8)
	
graph export "results/text_welfare_effects_varying_R_squared.pdf", as(pdf) replace 

	******************************

