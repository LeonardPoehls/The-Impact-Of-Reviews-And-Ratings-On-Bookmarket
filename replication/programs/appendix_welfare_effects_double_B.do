
use data/main_amazon_sales.dta, clear 
cross using data/A_B_params.dta 
cross using data/sigma.dta 

tsset canum ddate
reghdfe, compile


*** Set causal-effect B here:
replace B = 2*B	 
*******************	


	 
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

*	gen gamma1 = B*(_b[lR]+lreview*_b[lrR])/(1-_b[L1.lrank])
*	replace gamma1 = 0 if gamma1==. 
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
	

	******************************

	
	******************************
	* collapse to asin level
	
	rename pamzn p
	gen DOTH=OTHDATE~=.
	
	collapse (sum) q q1 (mean) e* gamma* alpha* p lR R Rhat sigma avgR ///
	(max) DNYT DOTH DUSAT lreview drecommend, by(asin genre)
	
		* find the sample total quantity (to feed scaling)
		gen qmil=q/1000000

		* scaling 
		egen sample_q=sum(qmil) /* our estimate of the units of sample books sold */
		gen samzn = 0.445   /* our estimate of Amazon's share */
		gen qagg=695 		/* estimate of units of physical books sold in the US in 2018 */
		gen scale = (qagg*samzn/sample_q)  /*the weight to translate sample results for stars into "aggregate sales" */
		su scale 
		local sc=r(mean)  /*create scaling factor used at the end of the program */
		
	
***************************** 
** Nested logit calibration 
***************************** 	

	* define variables 

	gen M = 12*327.2*1000000  /*12 months x US population x millions */
	egen Q=sum(q)
	egen Q1=sum(q1)

	gen s=q/M
	gen s0 = 1 - Q/M
	gen s_in=Q/M
	gen s_jin=q/Q
******************************


******************************
* calculate the NL parameters from the elasticities:

	gen ALPHA = alpha1*(1-sigma)/((1-sigma*s_jin-(1-sigma)*s)*p)
	reg ALPHA
	replace ALPHA = _b[_cons]

	gen GAMMA = -gamma1*(1-sigma)/((1-sigma*s_jin-(1-sigma)*s)*R)
	replace GAMMA = 0 if GAMMA==. | lreview==.

	gen PSI = ln(q/q1)*(1-sigma)

	drop q1  /* no longer needed, we calculate it with logit formulas below */
				
	

******************************
** Actual and counterfactual deltas & shares

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
			
** Counterfactual for reviews
	gen exb_2=exp(delta_2/(1-sigma))
	egen D_2=sum(exb_2)
	gen s2_in = [D_2^(1-sigma)]/[1+D_2^(1-sigma)]
	gen s2=[exb_2/(D_2)]*s2_in
	gen q2=M*s2
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

	
	replace Rhat=0 if Rhat==. | R==.
	replace R=0 if R==. 
	
	******************************
	** Adjustments & revenues
	gen double adj1 = (GAMMA/ALPHA)*(R-Rhat)*q1 
	replace  adj1 = 0 if adj1==.

	gen double adj2 = (PSI/ALPHA)*q2 
	egen double ADJ1 = sum(adj1)
	egen double ADJ2 = sum(adj2)
	
	******************************


	******************************
	** keep totals & save 
		
	collapse (mean) CS CS1 CS2  ADJ1 ADJ2  

********************************************************** 
	
	
	* define variables
	
	************************************
	* sample dCS
	gen dCS_stars = (CS - CS1 - ADJ1) / 1000000
	gen dCS_reviews = (CS - CS2 - ADJ2) / 1000000
	
	
		** Scale up to get total CS effects for stars
		gen dCS_stars_adj = dCS_stars*`sc'
		
		gen ratio = dCS_stars_adj/dCS_reviews

log using replication_logs/appendix_welfare_effects_double_B_log.txt, replace text 
		
*  baseline result: 
	fsum dCS_stars_adj dCS_reviews ratio
	
log close
	
		

