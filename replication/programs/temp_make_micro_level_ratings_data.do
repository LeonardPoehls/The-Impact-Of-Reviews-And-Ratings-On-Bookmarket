

* create the chunks of Ni data 


forvalues k=0(1) 23 {
	local l=`k'*10000000 + 1 
	local j=`l'+10000000 - 1 
import delimited "~\Downloads\all_csv_files.csv",  encoding(UTF-8) rowrange(`l':`j') colrange(1:3) clear
	drop v2 
	rename v1 asin
	rename v3 stars 
 
 merge m:1 asin using ~\Dropbox\book_data_scratch\data\intermediate\asin_spine_us.dta
 keep if _merge==3
 
 save ~\Dropbox\book_data_scratch\data\intermediate\part`k'.dta, replace
 }


 
 cd D:\Dropbox\book_data_scratch\
 
use  data\intermediate\part0.dta, clear
		forvalues j=1(1) 23 {
			append using  data\intermediate\part`j'.dta
		}
		
drop _merge 
compress 

save "D:\Dropbox\book_wisdom_crowd\replication\data\micro_level_book_ratings.dta", replace 
