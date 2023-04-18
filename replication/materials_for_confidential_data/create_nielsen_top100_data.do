

cd ~\Dropbox\book_wisdom_crowd\

ssc install filelist, replace

clear
set obs 1
gen x = .
tempfile sales
save `sales'

clear
set obs 1
gen x = .
tempfile names
save `names'

* -filelist- if from SSC
filelist , dir(data\raw\nielsen_top100) pattern(*.xlsx) norecur

* save a copy so that we can load each observation in the loop below
tempfile files
save "`files'"

global obs = _N

* loop over each file to collect all necessary data

forvalues i=1/$obs {

    use "`files'" in `i', clear
    local f = dirname + "/" + filename
    di "`f'"
	
	 import excel "`f'", sheet("130.0 Weekly Bestsellers |  ...") cellrange(A9:M109) firstrow clear
		gen d = "`f'"
		append using `sales'
		save `sales', replace
	}

split d, parse(" _ " " - ")
gen ddate = date(d2,"MDY")
gen pdate = date(PUBDATE,"YMD")	
	
         

rename TWRNK twrank 
rename TITLE title
rename AUTHOR author
rename ISBN isbn13 
rename TWSALES sales 
gen week = week(ddate) 
gen year = year(ddate)
 



keep ddate twrank title author isbn13  sales pdate  week  year       




********************
** create "prior-success" variable
preserve 

	collapse (sum) sales, by(title author ddate)

	gsort author ddate
	bys author: gen csales = sum(sales)

	gsort author title ddate
	bys author title : gen ctsales = sum(sales)

	gen prior_sales = csales - ctsales


	gsort author ddate title 

	keep author title ddate prior_sales 

	tempfile tf
	save `tf'

restore

merge m:1 author title ddate using `tf'
drop _merge
********************
	

********************
** add total weekly sales

keep if year(ddate)==2018 | year(ddate)==2017 | year(ddate)==2016 | year(ddate)==2015
duplicates drop

save data/nielsen_top100.dta, replace



