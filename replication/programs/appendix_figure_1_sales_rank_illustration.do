
use data/main_amazon_sales.dta, clear

keep if cno==3 & asin=="198210029X"
gsort  ddate

format ddate %d 


twoway (line lrank ddate) if ddate<=mdy(9,7,2018), scheme(lean2) ytitle(log Amazon sales rank) xtitle("")


graph export results/appendix_sales_rank_illustration.pdf, as(pdf) name("Graph")
