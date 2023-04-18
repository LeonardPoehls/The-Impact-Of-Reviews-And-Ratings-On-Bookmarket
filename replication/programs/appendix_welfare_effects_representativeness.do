
clear
set obs 1
gen x=.
save  tempfiles/welfare_effects_representativeness.dta, replace 

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



		*******************************************
		preserve 
			egen P=mean(p)
			replace p=P if p==.
			gen rev=p*q
			collapse (sum) Qtype = q, by(DUSAT)
		
			tempfile busat
			save `busat'
		restore
	
	forvalues j= 0 (1) 1 {
		preserve 
		
		
		egen Q=sum(q)

	
		gen M = 12*327.2*1000000  /*12 months x US population x millions */
		drop Q
		
		egen Q=sum(q)
		egen Q1=sum(q1)


		gen s=q/M
		gen s0 = 1 - Q/M
		gen s_in=Q/M
		gen s_jin=q/Q
		
		
		* calculate the nested logit parameters from the elasticities:
		
		gen ALPHA = alpha1*(1-sigma)/((1-sigma*s_jin-(1-sigma)*s)*p)
		reg ALPHA
		replace ALPHA = _b[_cons]

		gen GAMMA = -gamma1*(1-sigma)/((1-sigma*s_jin-(1-sigma)*s)*R)
		
		gen PSI = ln(q/q1)*(1-sigma)

		rename q1 target1
			
		
		gen delta=ln(s) - ln(s0) - sigma*ln(s/(1-s0))
		
		***********************************************************
		* designate a decile that is being treated by digitization
		**********************************************************
		
		replace GAMMA=0 if DUSAT~=`j' 
		replace PSI=0 if DUSAT~=`j'  

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
		
			
		replace Rhat=0 if Rhat==. | R==.
		replace R=0 if R==. 

		gen adj1 = (GAMMA/ALPHA)*(R-Rhat)*q1 
		gen adj2 = (PSI/ALPHA)*q2 

		** Actual consumer surplus
		gen xcs  = exp(delta/(1-sigma))
		egen xCS = sum(xcs)
		gen CS = log(1+xCS^(1-sigma))*(M/ALPHA)
		
		** Counterfactual CS - ratings
		gen xcs1  = exp(delta_1/(1-sigma))
		egen xCS1 = sum(xcs1)
		gen CS1 = log(1+xCS1^(1-sigma))*(M/ALPHA)
		
		** Counterfactual CS - reviews
		gen xcs2  = exp(delta_2/(1-sigma))
		egen xCS2 = sum(xcs2)
		gen CS2 = log(1+xCS2^(1-sigma))*(M/ALPHA)

		egen ADJ1 = sum(adj1)
		egen ADJ2 = sum(adj2)
		
		
		replace DUSAT= `j'
		collapse (mean) CS CS1 CS2  ADJ1 ADJ2   DUSAT
		
		
	append using tempfiles/welfare_effects_representativeness.dta
	save  tempfiles/welfare_effects_representativeness.dta, replace 
		restore 
		}


		
	

use tempfiles/welfare_effects_representativeness.dta, clear



* define changes in CD:

	* sample dCS
		gen dCS_stars 		= (CS - CS1 - ADJ1) / 1000000
		gen dCS_reviews 	= (CS - CS2 - ADJ2) / 1000000
	
	** Scale up to get total CS effects for stars
		gen dCS_stars_adj 	= dCS_stars*`sc'

	** Relative sizes:
		gen ratio			= dCS_stars_adj/dCS_reviews
	
		merge 1:1 DUSAT using `busat'
		
		sort Qtype  
		gen Qmil=Qtype/1000000
	
	
	**************************
	** scale only the non-bestsellers:
	
	gen CS_per_Q = dCS_stars_adj / Qmil
	gen samzn = 0.445   /* our estimate of Amazon's share */
	gen qagg=695 		/* estimate of units of physical books sold in the US in 2018 */
	
	gen share = Qmil / qagg if DUSAT==1
	
	gen scaled_USAT_dCS = dCS_stars*share
	
	egen temp_share = mean(share)
	replace share = 1 - temp_share if DUSAT==0
	gen temp_dCS = share * CS_per_Q * qagg * samzn
	egen dCS_weighted = sum(temp_dCS)
	
log using replication_logs/appendix_welfare_effects_representativeness_log.txt, replace text 
	
** Change in CS from stars, scaling up only non-bestsellers:
fsum dCS_weighted

log close 
