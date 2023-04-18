*********************************************************
** BS standard errors for 50-quantiles welfare calculation  
********************************************************* 	

*****************
** create a file for saving bootstrapped CS effects
*****************
	clear
	set obs 1
	gen x=.
	save  tempfiles\welfare_effects_50_quantiles_bs.dta, replace 
*****************


**************************** 
** Nested logit calibration 
***************************** 	
forvalues k=251(1)500{

use   tempfiles\quantity_us_simulations_50_quantiles_bs_`k'.dta, clear
	

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

	gen ALPHA = bs_alpha1*(1-bs_sigma)/((1-bs_sigma*s_jin-(1-bs_sigma)*s)*p)
	reg ALPHA
	replace ALPHA = _b[_cons]

	gen GAMMA = -bs_gamma2*(1-bs_sigma)/((1-bs_sigma*s_jin-(1-bs_sigma)*s)*R)
	replace GAMMA = 0 if GAMMA==. | lreview==.

	gen PSI = ln(q/q1)*(1-bs_sigma)
	drop q1  /* no longer needed, we calculate it using logit formulas below */
				
	
******************************
** Actual and counterfactual deltas & shares

** Deltas:
	gen delta=ln(s) - ln(s0) - bs_sigma*ln(s/(1-s0))
	gen delta_1 = delta - GAMMA*(R-Rhat)
	replace delta_1 = delta if delta_1==. | R==. | lreview==.
	gen delta_2 = delta - PSI 
	
** Counterfactual for ratings
	gen exb_1=exp(delta_1/(1-bs_sigma))
	egen D_1=sum(exb_1)
	gen s1_in = [D_1^(1-bs_sigma)]/[1+D_1^(1-bs_sigma)]
	gen s1=[exb_1/(D_1)]*s1_in
	gen q1=M*s1
			
** Counterfactual for reviews
	gen exb_2=exp(delta_2/(1-bs_sigma))
	egen D_2=sum(exb_2)
	gen s2_in = [D_2^(1-bs_sigma)]/[1+D_2^(1-bs_sigma)]
	gen s2=[exb_2/(D_2)]*s2_in
	gen q2=M*s2
******************************


******************************
** Consumer surplus calculations

** Actual consumer surplus
	gen double xcs  = exp(delta/(1-bs_sigma))
	egen double xCS = sum(xcs)
	gen double CS = log(1+xCS^(1-bs_sigma))*(M/ALPHA)
	
** Counterfactual CS - ratings
	gen double xcs1  = exp(delta_1/(1-bs_sigma))
	egen double xCS1 = sum(xcs1)
	gen double CS1 = log(1+xCS1^(1-bs_sigma))*(M/ALPHA)
	
** Counterfactual CS - reviews
	gen double xcs2  = exp(delta_2/(1-bs_sigma))
	egen double xCS2 = sum(xcs2)
	gen double CS2 = log(1+xCS2^(1-bs_sigma))*(M/ALPHA)
******************************

	
******************************
** Adjustments 
	replace Rhat=0 if Rhat==. | R==.
	replace R=0 if R==. 
	
	gen double adj1 = (GAMMA/ALPHA)*(R-Rhat)*q1 
	replace  adj1 = 0 if adj1==.

	gen double adj2 = (PSI/ALPHA)*q2 
	egen double ADJ1 = sum(adj1)
	egen double ADJ2 = sum(adj2)
******************************

******************************
** keep totals & save 
		
	collapse (mean) CS CS1 CS2  ADJ1 ADJ2 (sum) Q=q
				
	append using tempfiles\welfare_effects_50_quantiles_bs.dta
	save  tempfiles\welfare_effects_50_quantiles_bs.dta, replace 
******************************


}		
********************************************************** 


********************************************************** 
* define changes in CS:

use tempfiles\welfare_effects_50_quantiles_bs.dta, clear
	drop if CS==.
	
	gen sc=0.445*695/(Q/1000000)		

	* sample dCS
		gen dCS_stars 		= (CS - CS1 - ADJ1) / 1000000
		gen dCS_reviews 	= (CS - CS2 - ADJ2) / 1000000
	
	** Scale up to get total CS effects for stars
		gen dCS_stars_adj 	= dCS_stars*sc

	** Relative sizes:
		gen ratio			= dCS_stars_adj/dCS_reviews
		
		foreach i in dCS_stars_adj dCS_reviews ratio {
			qui: su `i'
			gen `i'_sd = r(sd)
		}
		
log using replication_logs\table_4_50_quantiles_bs_log.txt, replace text
		
* 50 quantiles CS result (standard deviations):
fsum *_sd 

log close
