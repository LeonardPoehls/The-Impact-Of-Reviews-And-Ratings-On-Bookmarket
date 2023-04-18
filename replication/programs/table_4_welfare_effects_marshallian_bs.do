
*********************************************************
** BS standard errors for Marshallian welfare calculation  
********************************************************* 	



clear
set obs 1
gen x=.
save  tempfiles/welfare_effects_marshallian_bs_a.dta, replace 
save  tempfiles/welfare_effects_marshallian_bs_b.dta, replace 
save  tempfiles/welfare_effects_marshallian_bs_c.dta, replace 
save  tempfiles/welfare_effects_marshallian_bs_d.dta, replace 

	
forvalues k=1(1) 500 { 	
	use tempfiles/quantity_us_simulations_bs_`k'.dta, clear 



rename bs_gamma2   gamma1 
rename bs_alpha1  alpha1 
rename  q1 q1_1 
		
		
******************************************************* 
* baseline cs effect of stars: full expansion
*******************************************************

preserve 

	**********************************
	** get Marshalllian CS and revenue 
	
	egen P=mean(p)
	replace p = P if p==.
	
	gen del_q = q*(gamma1*(lR - lRhat))
	mvencode del_q, mv(0) o
	gen del_p = p*(1/alpha1)*(del_q/q)
		
	gen del_cs = 0.5*(del_q^2)*(p/(q*alpha1))
	
	gen del_cs1=abs(del_cs)	
	egen dCS1 = sum(del_cs1)


	**************************
	
	
		* scaling 

		gen qmil=q/1000000
		egen sample_q=sum(qmil) /* our estimate of the units of sample books sold */
		gen samzn = 0.445
		gen qagg=695 
		gen scale = (qagg*samzn/sample_q)
		su scale 
		local sc=r(mean)
		gen dCS1_adj = dCS1*`sc'/1000000
	
	
       keep  dCS1_adj
	collapse (mean) dCS_ratings=dCS1_adj
	gen counter=`k'
	
	
append using tempfiles/welfare_effects_marshallian_bs_a.dta 
save 	tempfiles/welfare_effects_marshallian_bs_a.dta, replace 

restore 

******************************************************* 
	

	
		
******************************************************************* 
* no expansion effect of stars: proportional inverse adjustment 
*******************************************************************

preserve 

		
	**************************
	** adjust downs to get 0 change in q
	gen del_q = q*(gamma1*(lR - lRhat))
	mvencode del_q, mv(0) o

	egen xUP=sum(del_q) if del_q>0
	egen xDOWN=sum(del_q) if del_q<=0
	egen UP=max(xUP) 
	egen DOWN=max(xDOWN) 

	gen rho = (-UP/DOWN)^.5 
	
	replace  del_q=del_q*(1/rho) if del_q>0 
	replace del_q=del_q*(rho) if del_q<=0 
	
	**************************

	**************************
	** BoE get CS and revenue
	
	egen P=mean(p)
	replace p = P if p==.
	gen del_p = p*(1/alpha1)*(del_q/q)
	
	gen del_cs = 0.5*(del_q^2)*(p/(q*alpha1))
	
	gen del_cs1=abs(del_cs)	
	egen dCS1 = sum(del_cs1)

	**************************
	
		* scaling 

		gen qmil=q/1000000
		egen sample_q=sum(qmil) /* our estimate of the units of sample books sold */
		gen samzn = 0.445
		gen qagg=695 
		gen scale = (qagg*samzn/sample_q)
		su scale 
		local sc=r(mean)
		gen dCS1_adj = dCS1*`sc'/1000000
	
	
      keep  dCS1_adj
	collapse (mean) dCS_ratings_constrained = dCS1_adj
	gen counter=`k'
	
append using tempfiles/welfare_effects_marshallian_bs_b.dta 
save 	tempfiles/welfare_effects_marshallian_bs_b.dta, replace 
	
	
restore 

******************************************************* 
	
******************************************************* 
* baseline effect of NYT
*******************************************************
preserve 


	**************************
	** BoE get CS and revenue

	gen double del_q = q1 - q
	egen P=mean(p)
	replace p = P if p==.
	gen del_p = p*(1/alpha1)*(del_q/q)
	
	gen del_cs = 0.5*(del_q^2)*(p/(q*alpha1))

	gen del_cs2=abs(del_cs)	
	egen dCS2 = sum(del_cs2)
	replace dCS2=dCS2/1000000

	**************************
	
	**************************
	** no need to scale to industry
	
	
	keep dCS2
	collapse (mean) dCS_reviews = dCS2
	gen counter=`k'
	
append using tempfiles/welfare_effects_marshallian_bs_c.dta 
save 	tempfiles/welfare_effects_marshallian_bs_c.dta, replace 

	
	**************************
	
	
restore 


******************************************************* 
* No-expansion effect of NYT
*******************************************************
preserve 

	**************************
	gen T = (q1 - q) / q if q1!=q
	
	qui: su T
	local Tbar = r(mean) 
	local Nt = r(N)
	
	qui:su q if q==q1_1
	local Nnt = r(N)
	
	qui: su q
	local N = r(N)
	
	gen deltaT = `Tbar'/(1+(`Nt'/`Nnt'))
	gen deltaNT = deltaT - `Tbar'
	
	**************************
	** adjust all q's down to get 0 change in q
	gen double del_q = (q1 - q)* (deltaT/`Tbar')
	replace del_q = deltaNT*q if q1==q
	gen double q2 = q + del_q
	
	** Note: some NYT-reviewed books are now better off without reviews
	**************************


	
	**************************
	** BoE get CS and revenue

	egen P=mean(p)
	replace p=P if p==.
	
	gen del_p = p*(1/alpha1)*(del_q/q)

	gen del_cs = 0.5*(del_q^2)*(p/(q*alpha1))
	
	gen del_cs2=abs(del_cs)	
	egen dCS2 = sum(del_cs2)
	replace dCS2=dCS2/1000000

	**************************
	
	**************************
	** no need to scale to industry
	
		
	keep dCS2
	collapse (mean) dCS_reviews_constrained = dCS2
	gen counter=`k'
	
append using tempfiles/welfare_effects_marshallian_bs_d.dta 
save 	tempfiles/welfare_effects_marshallian_bs_d.dta, replace 

	**************************
	
	
restore 
}



use  	tempfiles/welfare_effects_marshallian_bs_a.dta, replace 
append   using	tempfiles/welfare_effects_marshallian_bs_b.dta
append   using	tempfiles/welfare_effects_marshallian_bs_c.dta 
append   using	tempfiles/welfare_effects_marshallian_bs_d.dta

	
collapse (mean) dCS*, by(counter)
gen ratio = dCS_ratings/dCS_reviews 
gen ratio_constrained = dCS_ratings_constrained/dCS_reviews_constrained 

	foreach i in dCS_ratings dCS_reviews ratio dCS_ratings_constrained dCS_reviews_constrained ratio_constrained {
		qui: su `i'
		gen `i'_sd = r(sd)
	}
	
log using replication_logs/table_4_marshallian_bs_log.txt, replace text 

** CS results from unconstrained Marshallian calculations (std. errors):
fsum dCS_ratings_sd dCS_reviews_sd ratio_sd

** CS results from constrained Marshallian calculations (std. errors):
fsum *_constrained_sd

log close 

	
	