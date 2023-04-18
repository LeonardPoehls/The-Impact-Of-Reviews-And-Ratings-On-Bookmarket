/* ****************************************************************************
* This program executes a series of do files that use our main datasets to:
	* produce intermediate datasets used for sales & CS simulations
	* produce parameter estimates (A, B, sigma) used for sales & CS simulations
	* produce the tables, figures, and numbers noted in the text
*/

********************************************************

********************************
* SETUP  
********************************
	
	cd "~/Dropbox/book_wisdom_crowd/replication"

	do programs/setup.do 


	
********************************
* PARAMETER CREATION 
* (captured, because they rely on confidential data)
********************************
	capture noisily {
		do programs/create_A_B.do
		do programs/create_A_B_bs.do 

		do programs/create_sigma.do 
	}

********************************
* TABLES, pt 1 
********************************

	do programs/table_1_sample_stats.do   

	do programs/table_2_regressions.do   

	
********************************
* INTERMEDIATE DATA CREATION 
********************************

	do programs/create_quantity_us_simulations.do 
	do programs/create_quantity_us_simulations_bs.do 

	do programs/create_quantity_us_simulations_50_quantiles.do 
	do programs/create_quantity_us_simulations_50_quantiles_bs.do 

	
********************************
* TABLES, pt 2 
********************************

	do programs/table_3_quantity_effects.do   
	do programs/table_3_quantity_effects_bs.do   

	do programs/table_4_welfare_effects_baseline.do   
	do programs/table_4_welfare_effects_baseline_bs.do   

	do programs/table_4_welfare_effects_50_quantiles.do   
	do programs/table_4_welfare_effects_50_quantiles_bs.do   

	do programs/table_4_welfare_effects_reviewed_books.do   
	do programs/table_4_welfare_effects_reviewed_books_bs.do   

	do programs/table_4_welfare_effects_varying_sigma.do   
	do programs/table_4_welfare_effects_varying_sigma_bs.do   

	do programs/table_4_welfare_effects_marshallian.do   
	do programs/table_4_welfare_effects_marshallian_bs.do   

********************************
* FIGURES
* (the captured program relies on confidential data)
********************************

	do programs/figure_2_daily_review_effects.do   

	do programs/figure_3_causal_effects_stars_50.do   
	
	capture noisily {
		do programs/figure_4_nyt_over_time_effect.do   
	}
	
********************************
* Numbers in main text
********************************

	do programs/text_numbers_main_sections1_5.do

	do programs/text_welfare_effects_varying_R_squared.do 
	do programs/text_welfare_effects_WOM.do 

	do programs/text_numbers_section7.do

 
********************************
* Numbers in appendix text
********************************
	
	do programs/appendix_welfare_effects_double_B.do 

	do programs/appendix_welfare_effects_2level_nl.do

	do programs/appendix_welfare_effects_representativeness.do


********************************
* Appendix figures
********************************

	do programs/appendix_figure_1_sales_rank_illustration.do

	do programs/appendix_figure_2_genre_distribution.do

