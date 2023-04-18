
**************************************************************
* create file for appending results 
clear 
set obs 1 
gen x=. 
save tempfiles/welfare_effects_2level_nl.dta, replace
**************************************************************


use  tempfiles/quantity_us_simulations.dta, clear


******************************************************* 
** Calculate dCS for different values of sigma:

forvalues sigma2=0.0 (0.05) 0.96 {
	forvalues sigma = `sigma2' (0.05) 0.96 {
	preserve 

	replace sigma = `sigma'
	gen sigma2 = `sigma2'

	******************************
	* Observed quantities & shares

		gen M = 12*327.2*1000000
		
		egen Q=sum(q)
		egen Q1=sum(q1)
		egen double Qgenre = sum(q), by(genre)

		gen double s=q/M
		gen double s0 = 1 - Q/M
		gen double s_in=Qgenre/M
		gen double s_jin=q/Qgenre
		gen double s_g = Qgenre/M
		gen double s_jG = q/Q
		gen double s_gG = Qgenre/Q
	******************************
		
		
	******************************
	* calculate the NL parameters from the elasticities:
	
		gen double ALPHA = alpha1*(1-sigma)/(p* (1-((sigma-sigma2)/(1-sigma2)*s_jin)-(sigma2*(1-sigma)/(1-sigma2)*s_jG)-((1-sigma)*s)))
		qui: reg ALPHA
		replace ALPHA = _b[_cons]

		gen double GAMMA = -gamma1*(1-sigma)/(R* (1-((sigma-sigma2)/(1-sigma2)*s_jin)-(sigma2*(1-sigma)/(1-sigma2)*s_jG)-((1-sigma)*s)))
		replace GAMMA = 0 if GAMMA==. | lreview==.

		gen double PSI = ln(q/q1)*(1-sigma)
		drop q1
	

		
	******************************
	** Actual and counterfactual deltas & shares
	
	** Deltas:
		gen double delta=ln(s) - ln(s0) - sigma*ln(s_jin) - sigma2*ln(s_gG)
		gen double delta_1 = delta - GAMMA*(R-Rhat)
		replace delta_1 = delta if delta_1==. | R==. | lreview==.
		gen double delta_2 = delta - PSI 

	** Counterfactual for ratings
		gen double exb_1=exp(delta_1/(1-sigma))
		egen double D_1=sum(exb_1), by(genre)   // this is D_g
		
		bys genre: gen double xn = _n
		gen double xD_1 = D_1 * (xn==1)
		gen double xxD_1 = xD_1^((1-sigma)/(1-sigma2)) 
		egen double sumD1 = sum(xxD_1) // this is D_G
				
		gen double s1=exb_1/(D_1^((sigma-sigma2)/(1-sigma2))*sumD1^sigma2*(1+sumD1^(1-sigma2)))
		gen double q1=M*s1
					
	** Counterfactual for reviews
		gen double exb_2=exp(delta_2/(1-sigma))
		egen double D_2=sum(exb_2), by(genre)
		
		gen double xD_2 = D_2 * (xn==1)
		gen double xxD_2 = xD_2^((1-sigma)/(1-sigma2))
		egen double sumD2 = sum(xxD_2)
				
		gen double s2=exb_2/(D_2^((sigma-sigma2)/(1-sigma2))*sumD2^sigma2*(1+sumD2^(1-sigma2)))
		gen double q2=M*s2
	******************************



	******************************
	** Consumer surplus calculations

	** Actual consumer surplus
		** Preliminaries:
		gen double xcs  = exp(delta/(1-sigma))
		** sum of books within genre:
		egen double xCSg = sum(xcs), by(genre)
		replace xCSg = xCSg^((1-sigma)/(1-sigma2))
		** sum across genres
		replace xCSg = 0 if xn>1
		egen double xCS = sum(xCSg)
	gen double CS = log(1+xCS^(1-sigma2))*(M/ALPHA)
	
	** Counterfactual CS - ratings
		** Preliminaries:
		gen double xcs1  = exp(delta_1/(1-sigma))
		** sum of books within genre:
		egen double xCSg1 = sum(xcs1), by(genre)
		replace xCSg1 = xCSg1^((1-sigma)/(1-sigma2))
		** sum across genres
		replace xCSg1 = 0 if xn>1
		egen double xCS1 = sum(xCSg1)
	gen double CS1 = log(1+xCS1^(1-sigma2))*(M/ALPHA)
	
	** Counterfactual CS - reviews
		** Preliminaries:
		gen double xcs2  = exp(delta_2/(1-sigma))
		** sum of books within genre:
		egen double xCSg2 = sum(xcs2), by(genre)
		replace xCSg2 = xCSg2^((1-sigma)/(1-sigma2))
		** sum across genres
		replace xCSg2 = 0 if xn>1
		egen double xCS2 = sum(xCSg2)
	gen double CS2 = log(1+xCS2^(1-sigma2))*(M/ALPHA)
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
	** keep totals & save for each sigma
		collapse (mean) CS CS1 CS2  ADJ1 ADJ2 
	
		gen sigma = `sigma'
		gen sigma2 = `sigma2'

		append using tempfiles/welfare_effects_2level_nl.dta 
		save tempfiles/welfare_effects_2level_nl.dta, replace 
	******************************
	restore 
	}
}
******************************************************* 



*********************************************		
* Create a scaling parameter and set up CS calculation:

use  tempfiles/quantity_us_simulations.dta, clear

	gen qmil=q/1000000
	egen sample_q=sum(qmil) /* our estimate of the units of sample books sold */
	gen samzn = 0.445   /* our estimate of Amazon's share */
	gen qagg=695 		/* estimate of units of physical books sold in the US in 2018 */
	gen scale = (qagg*samzn/sample_q)  /*the weight to translate sample results for stars into "aggregate sales" */
	su scale 
	local sc=r(mean)  /*create scaling factor used at the end of the program */



********************************************************** 
* define changes in CS:

use  tempfiles/welfare_effects_2level_nl.dta, clear  

	* sample dCS
		gen dCS_stars 		= (CS - CS1 - ADJ1) / 1000000
		gen dCS_reviews 	= (CS - CS2 - ADJ2) / 1000000
	
	** Scale up to get total CS effects for stars
		gen dCS_stars_adj 	= dCS_stars*`sc'

	** Relative sizes:
		gen ratio			= dCS_stars_adj/dCS_reviews

	foreach i in dCS_stars_adj dCS_reviews ratio { 
		su `i'
		gen `i'_min = r(min)
		gen `i'_max = r(max)
	}
log using replication_logs/appendix_welfare_effects_2level_nl_log.txt, replace text 

*  lowest and highest CS changes for varying 2-level NL values:
	fsum dCS_stars_adj_* dCS_reviews_* ratio_*
	
log close
			
********************************************************** 

