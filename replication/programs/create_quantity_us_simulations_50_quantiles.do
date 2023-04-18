use data/main_amazon_sales.dta, clear 
cross using data/A_B_params.dta 
cross using data/sigma.dta 
 
tsset canum ddate

	 xtile r50=review, nq(50)

******************************************************* 
* first, get the causal elasticities 	 


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
********************
	

estimates use "estimates/review_quantiles_50"

gen gamma1=0

replace gamma1 = B*(_b[1.r50#c.lR]*(r50==1) + ///
	 _b[4.r50#c.lR]*(r50==4) + ///
	 _b[6.r50#c.lR]*(r50==6) + ///
	 _b[8.r50#c.lR]*(r50==8) + ///
	 _b[9.r50#c.lR]*(r50==9) + ///
	 _b[11.r50#c.lR]*(r50==11) + ///
	 _b[12.r50#c.lR]*(r50==12) + ///
	 _b[13.r50#c.lR]*(r50==13) + ///
	 _b[14.r50#c.lR]*(r50==14) + ///
	 _b[15.r50#c.lR]*(r50==15) + ///
	 _b[16.r50#c.lR]*(r50==16) + ///
	 _b[17.r50#c.lR]*(r50==17) + ///
	 _b[18.r50#c.lR]*(r50==18) + ///
	 _b[19.r50#c.lR]*(r50==19) + ///
	 _b[20.r50#c.lR]*(r50==20) + ///
	 _b[21.r50#c.lR]*(r50==21) + ///
	 _b[22.r50#c.lR]*(r50==22) + ///
	 _b[23.r50#c.lR]*(r50==23) + ///
	 _b[24.r50#c.lR]*(r50==24) + ///
	 _b[25.r50#c.lR]*(r50==25) + ///
	 _b[26.r50#c.lR]*(r50==26) + ///
	 _b[27.r50#c.lR]*(r50==27) + ///
	 _b[28.r50#c.lR]*(r50==28) + ///
	 _b[29.r50#c.lR]*(r50==29) + ///
	 _b[30.r50#c.lR]*(r50==30) + ///
	 _b[31.r50#c.lR]*(r50==31) + ///
	 _b[32.r50#c.lR]*(r50==32) + ///
	 _b[33.r50#c.lR]*(r50==33) + ///
	 _b[34.r50#c.lR]*(r50==34) + ///
	 _b[35.r50#c.lR]*(r50==35) + ///
	 _b[36.r50#c.lR]*(r50==36) + ///
	 _b[37.r50#c.lR]*(r50==37) + ///
	 _b[38.r50#c.lR]*(r50==38) + ///
	 _b[39.r50#c.lR]*(r50==39) + ///
	 _b[40.r50#c.lR]*(r50==40) + ///
	 _b[41.r50#c.lR]*(r50==41) + ///
	 _b[42.r50#c.lR]*(r50==42) + ///
	 _b[43.r50#c.lR]*(r50==43) + ///
	 _b[44.r50#c.lR]*(r50==44) + ///
	 _b[45.r50#c.lR]*(r50==45) + ///
	 _b[46.r50#c.lR]*(r50==46) + ///
	 _b[47.r50#c.lR]*(r50==47) + ///
	 _b[48.r50#c.lR]*(r50==48) + ///
	 _b[49.r50#c.lR]*(r50==49) + ///
	 _b[50.r50#c.lR]*(r50==50) ) / (1-_b[L1.lrank]) if lreview~=. & lR~=. 

gen alpha1 = B*_b[lpamzn]/(1-_b[L1.lrank])
	

gen e1 = B*(_b[dnytpost1_3]*dnytpost1_3 +  _b[dnytpost6_3]*dnytpost6_3 + ///
	_b[dnytpost10_3]*dnytpost10_3 + _b[dothpost_3]*dothpost_3 + _b[dothpost10_3]*dothpost10_3 + ///
	_b[dnytpost1r_3]*dnytpost1r_3 +  _b[dnytpost6r_3]*dnytpost6r_3 + _b[dnytpost10r_3]*dnytpost10r_3 )/(1-_b[L1.lrank])

gen double q1 = (A)/exp(B*lrank - e1)	
gen double q = (A)/exp(B*lrank)		

	

*************************************************************************
* Then, get Rhat and collapse to asin level
		
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
	(max) DNYT DOTH DGR DPW DUSAT lreview drecommend, by(asin genre)
	
	save  tempfiles/quantity_us_simulations_50_quantiles.dta, replace
