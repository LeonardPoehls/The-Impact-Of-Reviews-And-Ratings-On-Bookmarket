


***********************************************************************
* Figure A2: genre distributions 
***********************************************************************
use data/main_amazon_sales.dta, clear 

cross using data/A_B_params.dta 


keep if cno==3

gen DPRO = (NYTDATE!=. | BGDATE!=. | CHIDATE!=. | LATDATE!=. | WAPODATE!=. | WSJDATE!=. )

gen q=A/rank^B

collapse (sum) q, by(genre DPRO)
egen Q=sum(q), by(DPRO)
gen s=q/Q

table genre DPRO, c(mean s)

keep s genre DPRO
reshape wide s, i(genre) j(DPRO)

gen ratio=s1/s0


gen dif=100*(s1-s0)
replace genre = "(AUTO)BIOGRAPHY" if genre=="BIOGRAPHY & AUTOBIOGRAPHY"
replace genre = "FICTION: Short Stories" if genre=="FICTION: Short Stories (single author)"


gr bar (mean) dif if ratio~=. & (dif<-1 | dif>1) & genre~="unknown", ///
over(genre, label(angle(forty_five) labsize(small)) sort(dif) descending) /// 
ytitle("pct diff: prof vs other") scheme(lean2) 

graph export results/appendix_genre_distribution.pdf, as(pdf) replace


