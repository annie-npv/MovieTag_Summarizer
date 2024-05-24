/*****************************************************************************
* Project Code for Final Submission           
* Author: Annie Nguyen                         
* Class Section: STA 402B                      
* Task: This SAS program performs various data processing tasks for the final
*   project. It includes importing CSV files, merging datasets, and generating 
*   keyword summaries for movies based on tag relevance scores. Additionally, 
*   it allows the user to specify a genre, generating graphs/tables showing 
*   popular keywords and suggesting movies for that genre.           
* Instructions:                               
* 1. Set the folder variable using %LET.      
* 2. Run the entire code to set up macros and 
*    necessary files.                          
* 3. Invoke user-oriented macros for specific 
*    tasks after the setup.                    
******************************************************************************/



/* PART I: Importing Data */

/* Specify the folder path */
%let path = M:\STA502\Term Project\ml-latest;

/* Create a macro to read the CSV files */
%macro importFiles(in=, out=);
    proc import
        datafile=&in /* CSV data set */
        out=&out /* New SAS data set */
        dbms=csv
        replace; /* Replace existing dataset if it already exists */
        guessingrows=1000; /* Adjust the value as needed */
    run;
%mend importFiles;

/* Import CSV files using the macro */
%importFiles(in="&path\genome-scores.csv", out=genome_scores);
%importFiles(in="&path\genome-tags.csv", out=genome_tags);
%importFiles(in="&path\movies.csv", out=movies);
%importFiles(in="&path\tags.csv", out=tags);

/* PART II: Merging and Sorting Data */

/* Sort the genome scores dataset by tagId */
proc sort data=genome_scores out=genome_scores_sorted;
    by tagId;
run;

/* Format tag in genome_tags */
data genome_tags;
	length tag $200;
    set genome_tags;
	format tag $200.; /* Apply a format to the tag variable */
	informat tag $200.;
	tag = compress(tag); /* Remove unnecessary spaces */
run;

/* Merge the sorted genome scores with genome tags */
data genome_merged;
    merge genome_scores_sorted genome_tags;
    by tagId;
	drop relevance;
run;

/* Print first 20 rows of merged dataset */
proc print data=genome_merged(obs=20);
run;

/* Sort the genome_merged dataset by movieId */
proc sort data=genome_merged out=genome_merged_sorted;
    by movieId;
run;

/* Sort the movies dataset by movieId */
proc sort data=movies out=movies_sorted;
    by movieId;
run;

/* Merge genome_merged with movies */
data movie_merged;
    merge genome_merged_sorted movies_sorted;
    by movieId;
	drop genres;
run;

/* Print first 20 rows of merged dataset */
proc print data=movie_merged(obs=20);
run;

/* Remove 'timestamp' variable from 'tags' dataset */
data tags;
	length tag $200; /* Adjust a maximum length of 200 characters */
    set tags;
    tag = compress(tag); /* Remove unnecessary spaces */
	format tag $200.; /* Apply a format to the tag variable */
	informat tag $200.;
    drop timestamp;
	if cmiss(of _all_) then delete;
run;

/* Sort the 'tags' dataset by movieId */
proc sort data=tags out=tags_sorted;
    by movieId;
run;

ods rtf bodytitle file = "M:\STA502\Term Project\tags_sorted.rtf";
title "Tags for all movies";
	proc print data = tags_sorted (obs=15);
	run;
ods rtf close;

/* Merge 'movie_merged' with 'tags_sorted' */
data movie_tagged;
    merge movie_merged tags_sorted;
    by movieId;
run;

/* Generate Frequency Table:
Create a frequency table for tags.
Order the tags by frequency. */
ods rtf bodytitle file = "M:\STA502\Term Project\tags_sorted_freq.rtf";
title "Most 15 common tags for all movies";
proc freq data=tags order = FREQ;;
    tables tag / out=tag_freq nocum nopercent maxlevels=15;
run;
ods rtf close;


/* PART III: Summarizing Tags */

/* Macro for summarizing tags for a specific movie */
%macro summarize_tags(title);
    /* Filter the dataset for the specified movie title */
    data movie_tags;
		length tag $200; /* Adjust a maximum length of 200 characters */
        set movie_tagged;
		tag = compress(tag); /* Remove unnecessary spaces */
		format tag $200.; /* Apply a format to the tag variable */
		informat tag $200.;
        where title = "&title"; /* Use double quotes around title */
    run;

	/* Generate Frequency Table:
	Create a frequency table for tags. Order the tags by frequency. */
    title "List of 15 Most Common Keywords/Tags for Movie &title";
	proc freq data=movie_tags order = FREQ;;
	    tables tag / out=tag_freq_movie nocum nopercent maxlevels=15;
	run;

%mend summarize_tags;

ods rtf bodytitle file = "M:\STA502\Term Project\sample.rtf";
title "List of tags for Toy Story (1995)";
/* Example usage of summarize_tags macro */
%summarize_tags(title=Toy Story (1995));
ods rtf close;
