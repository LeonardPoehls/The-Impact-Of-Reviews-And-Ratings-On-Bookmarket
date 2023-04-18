
********************************************************************
* Table 1 
********************************************************************
log using replication_logs/table_1_log.txt, replace text



use data/main_amazon_sales.dta, clear 


********************************************************************
** For Table 1 values:

keep if est_sample==1 
********************
qui: eststo sumby: estpost tabstat pamzn R rank review , stats(mean) by(country) columns(s) 
esttab sumby,  unstack replace label cells("mean(fmt(2) label(Mean))") nonumbers noobs

foreach i in 10 25 50 75 90 {
	qui: eststo ratings: estpost tabstat R pamzn, stats(p`i') by(country) columns(s) 
	qui: label var R "Ratings, `i'th pct" 
	esttab ratings,  unstack append label cells("p`i'(fmt(1))") nonumbers noobs keep(R)
}

distinct asin titleno
distinct asin titleno  if country=="CA"
distinct asin titleno if country=="GB"
distinct asin titleno if country=="US" 
********************************************************************

log close 



