
clear

*********************
* FIGURE 2 
*********************
** NYT daily effect figure

** The below estimates come from table_2_regressions.do:

estimates use "estimates/daily_param"

	parmest, fast
	
** NYT picture:
	split parm, parse("NYT")
	gen time=real(parm2)
	drop parm1 parm2
	split parm, parse("NYTm")
	replace time=-1*real(parm2) if time==. 

	
	gen xx=estimate if time==-1
	egen XX=mean(xx)
	gen estimate1=estimate-XX
	
	gen max951=max95 - XX
	gen min951=min95 - XX
	
	
	sort time
	twoway (line estimate1 time, lwidth(medthick) ) (line max951 time, lwidth(thin))  (line min951 time, lwidth(thin)) if time~=. & time>=-20 & time<40, ///
	scheme(lean2) title(New York Times effect) legend(off)   yscale(range(0.2 -0.6) rev)  ylabel(0.2 (-0.2) -0.6)  xline(-.5) 
	graph export "results/nyt_effect_daily.pdf", as(pdf) replace
	
	
	
** OTH picture:
	drop parm1 parm2 time max951 min951 xx XX estimate1
	split parm, parse("OTH")
	gen time=real(parm2)
	drop parm1 parm2
	split parm, parse("OTHm")
	replace time=-1*real(parm2) if time==.
	
	gen xx=estimate if time==-1
	egen XX=mean(xx)
	gen estimate1=estimate-XX
	
	gen max951=max95 - XX
	gen min951=min95 - XX

	

	sort time
	twoway (line estimate1 time, lwidth(medthick) )  (line max951 time, lwidth(thin))  (line min951 time, lwidth(thin)) if time~=. & time>=-20 & time<40, ///
	scheme(lean2) title(Non-New York Times effect) legend(off)   yscale(range(0.2 -0.6) rev)  ylabel(0.2 (-0.2) -0.6)  xline(-.5) 
	graph export "results/non_nyt_effect_daily.pdf", as(pdf) replace
	
*********************

