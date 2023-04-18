******************************************************************************
* THIS PROGRAM CALCULATES MARSHALLIAN WELFARE EFFECTS
******************************************************************************

use  tempfiles/quantity_us_simulations.dta, clear

		
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
		qui: su scale 
		local sc=r(mean)
		gen dCS_ratings = dCS1*`sc'/1000000
	
	
	su  dCS_ratings
	keep dCS_ratings
	keep if _n==1 
	gen count=1
	tempfile one 
	save `one'
	
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
		gen dCS_ratings_constrained = dCS1*`sc'/1000000
	
	
	su  dCS_ratings_constrained
	keep dCS_ratings_constrained
	keep if _n==1 
	gen count=1
	tempfile two 
	save `two'
	
	
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

	ren q1  q2
	
	gen del_cs = 0.5*(del_q^2)*(p/(q*alpha1))

	gen del_cs2=abs(del_cs)	
	egen dCS_review = sum(del_cs2)
	replace dCS_review=dCS_review/1000000

	**************************
	
	**************************
	** no need to scale to industry
	
	
	su  dCS_review 
	keep dCS_review
	keep if _n==1 
	gen count=1
	tempfile three 
	save `three'

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
	
	qui:su q if q==q1
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
	egen dCS_review_constrained = sum(del_cs2)
	replace dCS_review_constrained=dCS_review_constrained/1000000
	**************************
	
	**************************
	** no need to scale to industry
	
	
	su dCS_review_constrained
	keep 	dCS_review_constrained
	keep if _n==1 
	gen count=1
	tempfile four 
	save `four'
	**************************
	
	
restore 

**********************************
use `one', clear
merge 1:1 count using `two', nogen 
merge 1:1 count using `three', nogen 
merge 1:1 count using `four', nogen 

gen ratio = dCS_ratings/dCS_review
gen ratio_constrained = dCS_ratings_constrained/dCS_review_constrained 
	
**********************************
log using replication_logs/table_4_marshallian_log.txt, replace text 

** CS results from unconstrained Marshallian calculations:
fsum dCS_ratings dCS_review ratio

** CS results from constrained Marshallian calculations:
fsum *_constrained

log close 	
	
