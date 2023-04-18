
***********************************************************************
** This file uses the main causal regression to calibrate a NL demand model
** It then calculates industry-level CS impacts
***********************************************************************

 use  tempfiles/quantity_us_simulations.dta, clear

	******************************
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
	* REVIEWED BOOKS ONLY:
			gen DPRO=(DNYT+DOTH>0)
			replace GAMMA= 0 if DPRO==0

	gen PSI = ln(q/q1)*(1-sigma)
	drop q1  
					
		
	******************************
	** Actual and counterfactual deltas & shares
	
	** Deltas:
		gen delta=ln(s) - ln(s0) - sigma*ln(s/(1-s0))
		gen delta_1 = delta - GAMMA*(R-Rhat)
		replace delta_1 = delta if delta_1==. | R==. | lreview==.
		gen delta_2 = delta - PSI 
		
	** Counterfactual for ratings:
		gen exb_1=exp(delta_1/(1-sigma))
		egen D_1=sum(exb_1)
		gen s1_in = [D_1^(1-sigma)]/[1+D_1^(1-sigma)]
		gen s1=[exb_1/(D_1)]*s1_in
		gen q1=M*s1
				
	** Counterfactual for reviews:
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
	* define variables
		
	collapse (mean) CS CS1 CS2  ADJ1 ADJ2  

	gen dCS_stars 		= (CS - CS1 - ADJ1) / 1000000
	gen dCS_stars_adj 	= 0.445 * dCS_stars
	gen dCS_reviews 	= (CS - CS2 - ADJ2) / 1000000

	gen ratio 			= dCS_stars_adj/dCS_reviews

log using replication_logs/table_4_reviewed_books_log.txt, replace text 
				
fsum  dCS_stars_adj dCS_reviews ratio 
			
log close
