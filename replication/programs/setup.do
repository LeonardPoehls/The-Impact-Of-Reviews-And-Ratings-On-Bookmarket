

********************************
* PRELIMINARIES
********************************

** Packages:
	net install sg71.pkg, from(http://www.stata.com/stb/stb38)
	ssc install reghdfe, replace
	ssc install distinct, replace
	ssc install outreg2, replace
	ssc install fsum, replace

* set path 
	capture cd "D:/Dropbox/book_wisdom_crowd/replication/"
	capture cd "~/Dropbox/book_wisdom_crowd/replication"
	
* create directories 	
	mkdir results
	mkdir tempfiles 
	mkdir replication_logs 
	mkdir estimates  
	

