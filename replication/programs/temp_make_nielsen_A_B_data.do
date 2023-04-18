	cd ~\Dropbox\book_wisdom_crowd

* get Nielsen weekly data by title with a 
		use "data\clean\nielsen_top100.dta", clear
			keep if year(ddate)==2018 
			
			append using "~\Dropbox\book_wisdom_crowd\AER_revision\data\additional_nielsen_weekly.dta"
			
			gen match=substr(isbn13,4,9)
			keep ddate week isbn13 sales  match
			duplicates drop ddate week isbn13 match, force 
			
label var ddate "Date"
label var isbn13 "ISBN-13 (official edition identifier)"
label var sales "Weekly unit sales"
label var week "Week in the year"
label var match "Parsed edition identifier for matching"

compress 

save "~\Dropbox\book_wisdom_crowd\replication\data\nielsen_A_B_data.dta", replace 



use "data\clean\nielsen_top100.dta", clear

label var ddate 		"Date"
label var twrank 		"This week's Nielsen rank"
label var title 		"Title"
label var author 		"Author"
label var isbn13		"ISBN-13 (official edition identifier)"
label var sales 		"Weekly unit sales"
label var pdate 		"Publication date"
label var prior_sales 	"Book's sales in Top 100 before this week"
label var week 			"Week in the year"
label var quantity 		"Weekly total print quantity (PW)"

save "~\Dropbox\book_wisdom_crowd\replication\data\nielsen_top100.dta", replace 
