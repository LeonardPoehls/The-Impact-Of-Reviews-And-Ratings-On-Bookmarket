*******************************************	
* find A and B
*******************************************
		
use data/main_amazon_sales.dta , clear 

 * keep the same observations in the US regression
	keep if cno==3
	keep if year(ddate)==2018
	tsset ano ddate 

	gen ddateadj=ddate-6
	gen week =week(ddateadj)
	
	gen match=substr(asin,1,9)
	keep rank week ddate asin match  
	merge m:1 match week using confidential_data/nielsen_A_B_data.dta
	
	keep if _merge==3	
	gsort asin ddate 
	
** prepare nonlinear least squares:
	
	keep sales match rank week 
	egen mno=group(match)
	keep if sales + rank + week~=.

	
*** Define a minimizing function: 

capture program drop minfunction 
program define minfunction
	tempvar a
	tempvar b
	tempvar c
	tempvar d
	tempvar e

 if "`3'"!=""{
	loc sse = "`3'"
	qui cap drop `sse'
	}
 else {
	tempvar sse
	}

		gen double  `a' = `1'[1,1]*1000*$rvar^`1'[1,2]
		egen double `d' = sum(`a'), by($mwvar)
		gen double `e'=($svar - `d')^2
		egen double  `sse' = sum(`e')
	
	sca `2' = -`sse'
	
end

	gl nlist = "beta:A beta:B"	
	gl rvar = "rank"
	gl svar = "sales"  
	gl mvar = "mno"  
	gl wvar = "week"  
	egen mwno = group(mno week)
	gl mwvar = "mwno"
	 
	mat b0 = ( 10 , -0.25)
	mat colnames b0 = $nlist
	amoeba minfunction b0 yout bols . . 1E-10 
	drop mwno 
	 
	gen double A= 1000*bols[1,1]
	gen double B = -1*bols[1,2]

	
****************************
*** Repeat this 500 times:
	
preserve 
	keep A B
	keep if _n==1
	save  results/A_B_params_bs.dta, replace 
restore 	

drop A B 	
forvalues k=1 (1) 500 { 
	preserve 
		set seed `k'
		bsample, cluster(mno week) idcluster(mwno)
		gl mwvar = "mwno"  

		su 
		amoeba minfunction b0 yout bols . . 1E-10 
		gen double A= 1000*bols[1,1]
		gen double B = -1*bols[1,2]
		keep A B
		gen counter=`k'
		keep if _n==1
		append using  data/A_B_params_bs.dta
		save  data/A_B_params_bs.dta, replace 
	restore 
}		
