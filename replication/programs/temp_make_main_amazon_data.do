* create replication master 

cd ~\Dropbox\book_data_scratch\

use  data\clean\master_data.dta , clear

********************
* define the regression sample

tsset canum ddate
reghdfe, compile

	
		gen epos=pelapse*(pelapse>=0)
		gen eneg = pelapse*(pelapse<0)
			
		gen epos2=epos^2
		gen epos3=epos^3
		gen eneg2=eneg^2
		gen eneg3=eneg^3

	
	reghdfe lrank L1.lrank  lpamzn lreview lR lrR  i.cno#c.dnytpost1_5 i.cno#c.dnytpost6_10 ///
		i.cno#c.dnytpost10 i.cno#c.dothpost i.cno#c.dothpost10  i.cno#c.dnytpostpre i.cno#c.dothpostpre ///
		epos* eneg* ///
		, absorb(canum) vce(robust)
		
gen est_sample= e(sample)==1 
ren bekannt sales_sample

drop _merge 
 save "~\Dropbox\book_wisdom_crowd\replication\data\main_amazon_sales.dta", replace 

 use "~\Dropbox\book_wisdom_crowd\replication\data\main_amazon_sales.dta", clear
 
 gsort -cno DUSAT DUSAT_back DNYT DBG DCHI DLAT DWAPO DWSJ DPW DGR DGR_back asin ddate


order asin country pubdate ddate pelapse btitle bauthor publisher /// 
genre numbooks ///
est_sample sales cnew cused pamzn pnew pused R review rating plist ///
lrank lpamzn pnew lpused lR lreview lrR ///
DUSAT DUSAT_back DNYT NYTDATE NYT_elapse drecommended DBG BGDATE BG_elapse DCHI CHIDATE CHI_elapse DLAT LATDATE LAT_elapse DWAPO WAPODATE WAPO_elapse DWSJ WSJDATE WSJ_elapse DPW DGR DGR_back OTHDATE ///
dnytpost dnytpost10 dnytpostpre dothpost dothpost10 dothpostpre ///
epos epos2 epos3 eneg eneg2 eneg3 ///
ano cno titleno canum gno pubno ///
bauthor1 
 
order OTH_elapse, after(OTHDATE)
order dnytpost1_5 dnytpost6_10, before(dnytpost)

drop sales_sample

drop btitle_temp*
drop nytdate_true 
drop majpub pp
drop title author 
drop debut 
drop rating
drop lpused 
drop bauthor1 /* same as bauthor but with numbers when author=="" */
drop lpnew
drop danum dcnum
drop test
 
 use "~\Dropbox\book_wisdom_crowd\replication\data\main_amazon_sales.dta", clear

format pubdate %td
format ddate %td

replace DUSAT = 1 if DUSAT_back==1
replace DGR = 1 if DGR_back==1
drop DUSAT_back DGR_back
drop pyear


ren sales rank

label var asin			"Amazon edition identifier"
label var country   	"Country"
label var pubdate		"Publication date"
label var ddate			"Date"
label var pelapse		"Days since publication"
label var btitle		"Title"
label var bauthor		"Author"
label var publisher		"Publisher"
label var genre			"Genre"
label var numbooks		"#(pre-2018 books by the authors)"
label var est_sample 	"=1 if used for estimation"
label var sales			"Amazon sales rank"
label var cnew			"Number of sellers (new)"
label var cused			"Number of sellers (used)"
label var pamzn			"Amazon Price"
label var pnew			"Cheapest price (new) on marketplace"
label var pused			"Cheapest price (used) on marketplace"
label var R				"Amazon star rating"
label var review		"# Amazon ratings"
label var plist			"List price"
label var lrank			"Log sales rank"
label var lpamzn		"log Amazon price"
label var lR			"log star rating"
label var lreview		"Log # ratings"
label var lrR			"log # reviews x log stars"
label var DUSAT			"USA Today indicator"
label var DUSAT_back 	"USA Today backlist indicator"
label var DNYT			"New York Times review indicator"
label var NYTDATE		"NY Times review date"
label var NYT_elapse 	"Days until/since NY Times review"
label var drecommended 	"=1 if NY Times recommended the book"
label var DBG			"Boston Globe review indicator"
label var BGDATE		"Boston Globe review date"
label var BG_elapse		"Days until/since Boston Globe review"
label var DCHI			"Chicago Tribune review indicator"
label var CHIDATE		"Chicago Tribune review date"
label var CHI_elapse 	"Days until/since Chicago Tribune review"
label var DLAT			"LA Times review indicator"
label var LATDATE		"LA Times review date"
label var LAT_elapse 	"Days until/since LA Times review"
label var DWAPO			"Washington Post review indicator"
label var WAPODATE		"Washington Post review date"
label var WAPO_elapse 	"Days until/since Washington Post review"
label var DWSJ			"Wall Street Journal review indicator"
label var WSJDATE		"Wall Street Journal review date"
label var WSJ_elapse 	"Days until/since Wall Street Journal review"
label var DPW			"Publishers Weekly indicator"
label var DGR			"Goodreads indicator"
label var DGR_back		"Goodreads backlist indicator"
label var OTHDATE       "1st Non-NYT professional review date"
label var OTH_elapse    "Days until/since other paper review"
label var dnytpost1_5   "NYT 0-5 days post review"
label var dnytpost6_10  "NYT 6-10 days post review"
label var dnytpost      "NYT 0-10 days post review"
label var dnytpost10    "NYT 11-20 days post review"
label var dnytpostpre   "NYT 10 days pre to 20 days post review"
label var dothpost      "Other paper 0-10 days post review"
label var dothpost10    "Other paper 11-20 days post review"
label var dothpostpre   "Other paper 10 days pre to 20 days post review"
label var epos          "Days since publication (if>0)"
label var epos2         "(epos)^2"         
label var epos3         "(epos)^3"
label var eneg          "Days since publication (if<0)"
label var eneg2         "(eneg)^2"
label var eneg3         "(eneg)^3"
label var ano           "asin identifier"
label var cno           "Country identifier (=3 if USA)"
label var titleno       "Title-author identifier"
label var canum         "asin-country identifier"
label var gno           "Genre identifier"
label var pubno         "Publisher identifier"



