log using replication_logs/text_sections_1_through_5_log.txt, replace text 


********************************************************************
********************************************************************
* Introduction section
	* 21,546 editions (10,641 titles) in total sample
	* average NYT review effect (2.8%)
********************************************************************

*************************************************
* number of editions

use data/main_amazon_sales.dta, clear 
	distinct asin titleno
*************************************************


*************************************************
* Avg. NYT effect
quietly {
use  tempfiles/quantity_us_simulations.dta, clear

	collapse (mean) DNYT DOTH drecommend q q1, by(asin)

	gen change=100*((q/q1)-1)

	qui: su change if DNYT==1 
	gen nytoverall=r(mean)


keep nytoverall
collapse (mean)  nytoverall
}
fsum nytoverall, format(%9.1f)
*************************************************

	
	
	
	
********************************************************************
********************************************************************
* Background section
	* 9.3% of pro reviewed books are also in USAT 
	* share of books that have any ratings
	* avg. book had 984 ratings yearend 2018
	* over 75% of reviews > 1 week after publication
********************************************************************

use data/main_amazon_sales.dta, clear 
	keep if country=="US"
	
*************************************************
** Values in the text of section 1.2 & 1.3

** % of professionally reviewed books that are also bestsellers:
	bys titleno: gen nt = _n
	fsum DUSAT if DNYT+DBG+DCHI+DLAT+DWAPO+DWSJ>0 & nt==1, format(%9.3f)

** Number of ratings by the end of 2018
	quietly{
		egen maxdate = max(ddate), by(asin cno)
		bys asin cno: gen n_asin = _n
		egen total_ratings = max(review), by(asin cno)
		replace total_ratings = 0 if total_ratings==.
		gen any_rating = total_ratings>0
	}
	fsum any_rating
	
** Number of ratings by the end of 2018
	fsum total_ratings if country=="US" & n_asin==1

** % of reviews > 1 week after publication
	quietly { 
		gen elapse = ddate - pubdate
		gen latereview = elapse>7
	}
	fsum latereview if ddate==NYTDATE | ddate==OTHDATE

*************************************************



********************************************************************
********************************************************************
* Data section
	* sales sample titles
	* est  sample  titles 
	* share of simulated sales in est_sample (vs sales_sample)  
********************************************************************


*************************************************
** Distinct numbers of titles

use data/main_amazon_sales.dta, clear 

	distinct titleno
	distinct titleno if est_sample==1
*************************************************

*************************************************
** Share of simulated sales in est_sample vs sales sample

use tempfiles/quantity_us_simulations.dta, clear
quietly {
	egen qtotal = sum(q)
	gen DEST = est_sample>0
	egen qest = sum(q), by(DEST)
	gen share_qest = qest / qtotal if DEST==1
}
	su share_qest
*************************************************


********************************************************************
********************************************************************
* Empirical Strategies and Descriptive Results section
	* editions matched 
	* std. errors of A&B
	* B=0.54 from log-log weekly Nielsen regression
	* Micro-level review data (also mentioned in data section):
		* # matched, # reviewers, # editions
		* average ratings
********************************************************************



*************************************************
** Matches with Nielsen 
** (captured, because confidential data aren't included)

capture noisily {
quietly {
use data/main_amazon_sales.dta , clear 

	keep if cno==3
	tsset ano ddate 
	gen ddateadj=ddate-6
	gen week =week(ddateadj)
	
	gen match=substr(asin,1,9)
	keep rank week ddate asin match  
	merge m:1 match week using "confidential_data/nielsen_A_B_data.dta"
	gen nielsen_keepa_match = _merge==3
	keep if nielsen_keepa_match==1
	}
	distinct asin if nielsen_keepa_match==1
}
*************************************************

	
*************************************************
** A & B and their standard errors
	
use data/A_B_params.dta, clear
	su A B

use data/A_B_params_bs.dta, clear
quietly {
foreach i in A B {
	qui: su `i'
	gen `i'_sd = r(sd)
}
}
	su A_sd B_sd
*************************************************


*************************************************
** B from log-log weekly Nielsen regression (footnote 20)
** (captured, because confidential data aren't included)
capture noisily {
use "confidential_data/nielsen_top100.dta", clear
	keep if year==2018

	gen lrank=log(twrank)
	gen lq=log(sales)

	reg lq lrank
}
*************************************************




*************************************************
** Analysis of micro level reviews (Section 4.3)

quietly{
********************************
** List if pro-reviewed asins
use data/main_amazon_sales.dta, clear 
	gen DOTH=OTHDATE~=.
	gen DPRO=DNYT+DOTH>=1
	keep asin DPRO titleno
	duplicates drop 
	tempfile reviewed_asins
	save `reviewed_asins'

** Reviewer-book level reviews from Ni et al.
import delimited "data/Books.csv", varnames(nonames) stringcols(1) clear 

	gen double rtime = v4*1000 + mdyhms(1,1,1970,0,0,0)
	format rtime %tC
	gen rdate = dofc(rtime)
	format rdate %td
	keep if year(rdate)==2018
		
	rename v1 asin
	ren v2 person
	ren v3 star

** Keep overlapping asins
	merge m:1 asin using  `reviewed_asins'
	keep if _merge==3
********************************
}

********************************
** Number of reviews, matched editions & reviewers

	distinct asin person  
********************************

********************************
** Average star ratings: 

egen DRELEVANT=max(DPRO),by(person)
table DRELEVANT DPRO , c(mean star) row
ttest star if DRELEVANT==1, by(DPRO)

********************************

*************************************************



********************************************************************
********************************************************************
* Welfare Analysis section
	* R-squared from star regression
	* total sales in sales sample (=331.55)
********************************************************************

*************************************************
** Report R-squared from star ratings regression
quietly {

use data/main_amazon_sales.dta, clear 

	tsset canum ddate
	keep if cno==3 
	egen avgR=mean(R), by(asin)

	egen maxdate=max(ddate), by(asin)
	keep if ddate==maxdate
	
	eststo: areg  avgR i.gno  i.numbooks , absorb(pubno)
}
	di e(r2)
*************************************************

*************************************************
** Total simulated sales in sales sample

use tempfiles/quantity_us_simulations.dta, clear

	egen qtotal = sum(q)
	replace qtotal = qtotal/1000000
	su qtotal
*************************************************

log close 

