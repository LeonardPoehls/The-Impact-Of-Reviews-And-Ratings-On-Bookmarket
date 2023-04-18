
use data/main_amazon_sales.dta, clear 
cross using data/A_B_params.dta 

tsset canum ddate 

*************

	estimates use  "estimates/3coregint"
	keep if cno==3

	******************************
	* calculate elasticities

	replace B=-1*B
	
	gen gamma1 = B*(_b[lR]+lreview*_b[lrR])/(1-_b[L1.lrank])
	gen alpha1 = B*_b[lpamzn]/(1-_b[L1.lrank])
	
	
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
		
	
	gen e1 = B*(_b[dnytpost1_3]*dnytpost1_3 +  _b[dnytpost6_3]*dnytpost6_3 + ///
	_b[dnytpost10_3]*dnytpost10_3 + _b[dothpost_3]*dothpost_3 + _b[dothpost10_3]*dothpost10_3 + ///
	_b[dnytpost1r_3]*dnytpost1r_3 +  _b[dnytpost6r_3]*dnytpost6r_3 + _b[dnytpost10r_3]*dnytpost10r_3 )/(1-_b[L1.lrank])

	gen double q1_1 = (A)/exp(B*lrank - e1)	


	********************
	** Obtain points on the log-review distribution 
	egen l25 =pctile(lreview), p(25)
	egen l50 =pctile(lreview), p(50)
	egen l75 =pctile(lreview), p(75)
	egen lmean=mean(lreview)

	
*****************************************************
* below produces all mean effects in the top half of table 3
*****************************************************

* quartiles:
	nlcom B*(_b[lR]+_b[lrR]*l25)/(1-_b[L1.lrank])
	gen star_elas_25 = r(b)[1,1]
	nlcom B*(_b[lR]+_b[lrR]*l50 )/(1-_b[L1.lrank])
	gen star_elas_50 = r(b)[1,1]
	nlcom B*(_b[lR]+_b[lrR]*l75)/(1-_b[L1.lrank])
	gen star_elas_75 = r(b)[1,1]

* mean: 
	nlcom B*(_b[lR]+_b[lrR]*lmean)/(1-_b[L1.lrank])
	gen star_elas_mean = r(b)[1,1]

* price:
	nlcom B*_b[lpamzn]/(1-_b[L1.lrank])
	gen price_elas_mean = r(b)[1,1]

* Professional reviews (daily):
	* NYT (not recommended)
	nlcom B*_b[dnytpost1_3]/(1-_b[L1.lrank])
	gen nyt_1_5_not_rec = r(b)[1,1]
	nlcom B*_b[dnytpost6_3]/(1-_b[L1.lrank])
	gen nyt_6_10_not_rec = r(b)[1,1]
	nlcom B*_b[dnytpost10_3]/(1-_b[L1.lrank])
	gen nyt_11_20_not_rec = r(b)[1,1]

	* NYT (recommended)
	nlcom B*_b[dnytpost1r_3]/(1-_b[L1.lrank])
	gen nyt_1_5_rec = r(b)[1,1]
	nlcom B*_b[dnytpost6r_3]/(1-_b[L1.lrank])
	gen nyt_6_10_rec = r(b)[1,1]
	nlcom B*_b[dnytpost10r_3]/(1-_b[L1.lrank])
	gen nyt_11_20_rec = r(b)[1,1]

	* Other papers:
	nlcom B*_b[dothpost_3]/(1-_b[L1.lrank])
	gen oth_1_10 = r(b)[1,1]
	nlcom B*_b[dothpost10_3]/(1-_b[L1.lrank])
	gen oth_11_20 = r(b)[1,1]

log using replication_logs/table_3_log.txt, replace text
* This produces the top panel of Table 3.
	fsum price_elas_mean star_elas_25 star_elas_50  star_elas_75  nyt_1_5_not_rec nyt_6_10_not_rec nyt_11_20_not_rec nyt_1_5_rec nyt_6_10_rec nyt_11_20_rec   oth_1_10  oth_11_20, format(%9.3f)

log off 
	
*****************************************************
* below prepares annual % effects in table 3 
*****************************************************

use  tempfiles/quantity_us_simulations.dta, clear

	collapse (mean) DNYT DOTH drecommend q q1, by(asin)

	gen change=100*((q/q1)-1)

	qui: su change if DNYT==0 & DOTH==1
	gen other_only = r(mean)

	qui: su change if DNYT==1 & DOTH==0 & drecommend==0
	gen nyt_not_rec_only = r(mean)

	qui: su change if DNYT==1 & DOTH==0 & drecommend==1
	gen nyt_rec_only = r(mean)

	qui: su change if DNYT==1 & DOTH==1 & drecommend==0
	gen both_not_rec = r(mean)

	qui: su change if DNYT==1 & DOTH==1 & drecommend==1
	gen both_rec = r(mean)

	qui: su change if DNYT==1 
	gen nytoverall=r(mean)

	qui: su change if DNYT+DOTH>=1 
	gen overall=r(mean)

keep other_only nyt_not_rec_only nyt_rec_only both_not_rec both_rec overall nytoverall
collapse (mean) other_only nyt_not_rec_only nyt_rec_only both_not_rec both_rec overall nytoverall


*****************************************************
* below produces annual % effects in table 3 
*****************************************************

log on 
* This produces the bottom panel of Table 3.
	fsum other_only nyt_not_rec_only nyt_rec_only both_not_rec both_rec overall, format(%9.3f)

log close
