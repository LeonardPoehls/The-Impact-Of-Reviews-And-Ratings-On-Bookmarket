
***********************************************************************
** This file uses the main causal regression to calibrate a NL demand model
** It then calculates industry-level CS impacts
***********************************************************************


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
	
	egen P=mean(p)
	replace P=p if p!=.
	gen double rev=P*q
	gen double rev1=P*q1
	gen double rev2=P*q2
	
	egen double REV=sum(rev)
	egen double REV1=sum(rev1)
	egen double REV2=sum(rev2)
	
	** by whether it's better than expected:
	gen double revup = rev *(R>Rhat)
	gen double revdown = rev*(R<=Rhat)
	egen double REVup = sum(revup)
	egen double REVdown = sum(revdown)
	gen double rev1up = rev1 *(R>Rhat)
	gen double rev1down = rev1*(R<=Rhat)
	egen double REV1up = sum(rev1up)
	egen double REV1down = sum(rev1down)
	******************************

	******************************
	** Changes in CS and rev
	
	gen double DREV1=REV - REV1
	gen double DREV2=REV - REV2
	gen double DREV1up = REVup - REV1up
	gen double DREV1down = REVdown - REV1down
	******************************


	******************************
	** keep totals & save 
		
	collapse (mean) CS CS1 CS2  ADJ1 ADJ2  REV* DREV*

********************************************************** 
	
	
	* define variables
	
	************************************
	* sample dCS
	gen dCS_stars = (CS - CS1 - ADJ1) / 1000000
	gen dCS_reviews = (CS - CS2 - ADJ2) / 1000000
	
	
		** Scale up to get total CS effects for stars
		gen dCS_stars_adj = dCS_stars*`sc'
		
		gen DREV_stars_up_adj	=`sc'*DREV1up/1000000
		gen DREV_stars_down_adj	=`sc'*DREV1down/1000000
		gen DREV_stars_adj		=`sc'*DREV1/1000000
		
		gen DREV_reviews 		=DREV2/1000000
		gen ratio				=dCS_stars_adj/dCS_reviews

		
log using replication_logs/table_4_baseline_log.txt, replace text 
		
*  baseline results (revenue and consumer surplus): 
	fsum DREV_stars_adj  DREV_reviews DREV_stars_up_adj DREV_stars_down_adj
	fsum dCS_stars_adj dCS_reviews ratio
	
log close
	
		
