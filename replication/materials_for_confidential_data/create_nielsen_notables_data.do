

********************************
** combine sales data
** front end: set up to loop through directory

ssc install filelist, replace

clear
set obs 1
gen x = .
tempfile salesinfo
save `salesinfo'

* -filelist- if from SSC
filelist , dir(nielsen_directory) pattern(*.xlsx) norecur

* save a copy so that we can load each observation in the loop below
tempfile files
save "`files'"

global obs = _N

* loop over each file to collect all necessary data

forvalues i=1/$obs {

    use "`files'" in `i', clear
    local f = dirname + "/" + filename
    di "`f'"

	import excel "`f'", sheet("135.0 Title Sales and Rank  ...") clear    
	ren A week
	capture noisily: ren B sales
	if _rc ==0 {
		drop in 1/12
		split week, p(" - ")
		gen ddate = date(week1,"MDY")
		format ddate %td
		keep ddate sales
		order ddate
		destring sales, replace
		drop if ddate==.
		tempfile sales
		save `sales', replace
	}

	import excel "`f'", sheet("136.0 Search Results") clear    
	keep if B!=""
	keep A G
	ren A isbn13
	gen pubdate = date(G,"YMD")
	format pubdate %td
	drop G
	keep in 2
	compress
	cross using `sales'
	*save "tempfiles/salesinfo_`i'.dta", replace
	append using `salesinfo'
	save `salesinfo', replace

}
**********************************************************


gsort isbn13 ddate

merge m:1 isbn13 using data/nielsen_notables_spine.dta, nogen

save data/master_nielsen.dta, replace
