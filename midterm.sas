/* Dion Hagan -- Stat 135 Midterm Project*/


/*  Step 1: Data Cleaning/Munging
*	Decide which data columns/questions to analyze
* 	Remove any columns not related to questions of interest 
*/

/* Formats */
proc format;
   value preddeg  	0 = 'Not classified'
				  	1 = 'Mostly Associate'
				  	2 = 'Mostly Bachelors'
				  	3 = 'All Bachelors';
				  	
   value highdeg	0 = 'None'
					1 = 'Certificate'
					2 = 'Associate'
					3 = 'Bachelors'
					4 = 'Graduate';
					
   value region		0 = 'U.S. Service Schools'
					1 = 'New England'
					2 = 'Mid East'
					3 = 'Great Lakes'
					4 = 'Plains'
					5 = 'Southeast'
					6 = 'Southwest'
					7 = 'Rocky Mountains'
					8 = 'Far West'
					9 = 'Other';	
					 
   value kind    	1 = 'Public'
   				    2 = 'Private'
   				    3 = 'Private-for-profit';
   				    
   value $ yesno	0 = 'No'
   					1 = 'Yes';
run;

/* Subset Dataset */
proc sql;
	create table student as
		select 
			   /* SCHOOL */
			   instnm as name label='University Name', 
		       city as city label='City',
		       region as region label='Region' format=region.,
		       preddeg as mode_deg label='Predominant Degree Granted' format=preddeg., 
			   highdeg as highdeg label='Highest Degree Available' format=highdeg.,
			   input(adm_rate, 6.) as admit_pct label='Admission Rate' format=percent9.2,
			   control as kind label='Type of Institution' format=kind.,
			   HBCU as hbcu label='HBCU' format=$yesno.,
			   
			   /* COST & TUITION */
		       input(costt4_a, 7.) as yrcost4 label='Annual Cost at 4yr University',
		       input(avgfacsal, 6.) as mn_faculty_sal label='Average Faculty Salary', 
		       input(tuitionfee_in, 6.) as tuition_in label='In-state Tuition', 
		       input(tuitionfee_out, 5.) as tuition_out label='Out-of-state Tuition',
		       input(num4_pub, 10.) as pubnum label='Number of Public School Students',
		       input(num4_priv, 10.) as privnum label='Number of Private School Students',
		       input(NPT4_PUB, 6.) as ppub label='Avg net price of public' format=dollar10.,
		       input(NPT4_PRIV, 6.) as ppriv label='Avg net price of private' format=dollar10.,
		       tuitfte as revenue label='Net Revenue per Full Time Student' format=dollar10.,
		       inexpfte as expend label='Instructional Expenditures per Full Time Student' format=dollar10.,
		       input(avgfacsal, 6.) as mn_faculty_sal label='Average Faculty Salary',
		       input(pftfac, 6.) as ftfac label='Proportion of Full Time Faculty' format=percent9.2,
		       
		       /* ACT & SAT MATH*/
		       input(SATMT25, 3.) as sat25 label='SAT Math 25th Qt.', 
		       input(SATMT75, 3.) as sat75 label='SAT Math 75th Qt.',
		       input(SAT_AVG, 4.) as satavg label='Average SAT',
		       input(ACTMT25, 2.) as actm25 label= 'ACT Math 25th Qt.', 
		       input(ACTMT75, 2.) as actm75 label= 'ACT Math 75th Qt',
		       
		       /* RACE DEMOGRAPHICS */
		       UGDS_WHITE as wht label='White Undergrads'  format=PERCENT9.2,
		       UGDS_BLACK as blck label='Black Undergrads'  format=PERCENT9.2,
		       UGDS_HISP as hsp label='Hispanic Undergrads' format=PERCENT9.2,
		       UGDS_ASIAN as asn label='Asian Undergrads'  format=PERCENT9.2,
		       input(c150_4, 9.) as compl_rate4 label='Completion Rate after 4yrs' format=percent9.2,
		       input(c150_4_white, 9.) as wht_rate label='Completion Rate after 4yrs' format=percent9.2,
		       input(c150_4_black, 6.) as blk_rate label='Completion Rate after 4yrs' format=percent9.2,
		       input(c150_4_hisp, 9.) as hisp_rate label='Completion Rate after 4yrs' format=percent9.2,
		       input(c150_4_asian, 9.) as asian_rate label='Completion Rate after 4yrs' format=percent9.2,
		       
		       /* DEBT & LOANS */
		       PCTPELL as pell label='Percentage of Pell Students' format=PERCENT9.2,
		       DEBT_MDN as cumdebt label='Cumulative Median Debt',
		       FEMALE_DEBT_MDN as fdebt label='Female Median Debt',
		       MALE_DEBT_MDN as mdebt label='Male Median Debt',
		  
		       /* REPAYMENT */
		       CDR3 as cdr3 label='Cohort Default Rate - 3yrs' format=percent9.2
		  from import;
quit;

/* subset where pell is not NULL */
proc sql;
	create table sample as
		select A.*
  	  	from student as A
  	  	where pell >= 0;
quit;

/*	
*@---------------------------------------------------------------------------------------@
*|							STEP 2: Summary Stats/EDA									 |
*|					 ~ Private, Public, Private-for-Profit ~ 					    	 |    
*@---------------------------------------------------------------------------------------@
*/

/**********************************
 	    ~ DATA: publix ~	     
 **********************************/
proc means data=sample;
    title 'Public vs Private - Summary';
	var pubnum ppub privnum ppriv;
run;
proc sql;
	select mean(ppub)/mean(pubnum) as ratio_per_public_public_student,
		   mean(ppriv)/mean(privnum) as ratio_per_private_student
	from sample;
quit;
/**************************************
	  	 ORDERDED BY: kind 			  	 
          ~ DATA: publix ~       	 
**************************************/
proc sql;
	create table publix as
		select *
		from sample
		order by kind;
quit;
proc means data=publix;
	class kind;
	var;
run;
/**************************************
 			In state tuition	     
    		  %publix 				 
**************************************/

/* histograms of instate and outstate tuition */
proc sgplot data=publix;
	histogram tuition_in / group=kind nbins=75 binwidth=5 showbins;
	title 'In-state Tuition';
run;
proc sgplot data=publix;
	histogram tuition_out / group=kind nbins=75 binwidth=5 showbins;
	title 'Out-of-State Tuition';
run;

/* Regional Analysis */
proc sql;
	create table tuitreg as
		select region as region format=region.,
			   tuition_in as tin,
			   tuition_out as tout,
			   pell, kind
		from publix
		order by region;
quit;
data tuitreg2;
	set tuitreg;
	if tout eq tuin then instate = 0;
	else instate = 1;
	format region;
run;
data tmp;
	set tuitreg2;
	format region;
	where region neq 0 and region neq 9;
run;
proc sql;
	create table tuitreg3 as
	select region format=region., tin, tout, instate
	from tmp;
quit;

proc means data=tuitreg mean min max;
	class region;
	var tin tout;
run;

/* ANOVA tests */
proc anova data=tuitreg3;
	title 'Regional Breakdown of In State Tuition';
	class region;
	model tin = region;
	means region / SCHEFFE;
	where instate eq 1;
run;
proc anova data=tuitreg3;
	title 'Regional Breakdown of Out of State Tuition';
	class region;
	model tout = region;
	means region / SCHEFFE;
run;

/* Pell Pct vs Has Lower In State Tuition */
proc ttest data=tuitreg2;
	title 'Pell Grant Students at In State Tuition School';
	class instate;
	var pell;
run;
proc reg data=tuitreg2;
	title 'Regression of Percentage Pell Grants on Presence of lowered Tuition for In State students';
	model pell = instate;
run;

/* Completion Rate */
proc anova data=student;
	class kind;
	model compl_rate4 = kind;
run;

/*	
*@---------------------------------------------------------------------------------------@
*|							   EXPLORATORY DATA ANALYSIS								 |	 |
*|					 			~ RACE + DEMOGRAPHICS ~ 					    	     |    
*@---------------------------------------------------------------------------------------@
*/

/* summary stats */
proc means data=student mean;
	class region;
	var wht blck hsp asn;
run;
proc corr data=student;
	title 'Factors correlated with Race';
	var wht blck hsp asn;
	with pell admit_pct satavg cdr3;
run;

/* random sample */
proc sql outobs=5000;
	create table regsample as
		select A.*
		from student as A
		order by RANUNI(24234);
quit;

/* check for normality */
/* histogram panel rendering */
proc template;
  define statgraph racehist;
    begingraph;
      entrytitle "Distribution of Races";
        layout lattice / rows=2 columns=2;
          layout overlay;
            histogram  wht  / scale=proportion;
          	densityplot wht / lineattrs=GraphFit  normal() name="Normal";
          	densityplot wht / lineattrs=GraphFit2 kernel() name="Kernel";
            discretelegend "Normal" "Kernel" / location=inside across=1
            autoalign=auto;
          endlayout;
          layout overlay;
            histogram  blck  / scale=proportion;
            densityplot blck / lineattrs=GraphFit  normal() name="Normal";
            densityplot blck / lineattrs=GraphFit2 kernel() name="Kernel";
            discretelegend "Normal" "Kernel" / location=inside across=1
            autoalign=auto;
          endlayout;
          layout overlay;
            histogram  hsp  / scale=proportion;
            densityplot hsp / lineattrs=GraphFit  normal() name="Normal";
            densityplot hsp / lineattrs=GraphFit2 kernel() name="Kernel";
            discretelegend "Normal" "Kernel" / location=inside across=1
            autoalign=auto;
          endlayout;
          layout overlay;
            histogram  asn  / scale=proportion;
            densityplot asn / lineattrs=GraphFit  normal() name="Normal";
            densityplot asn / lineattrs=GraphFit2 kernel() name="Kernel";
            discretelegend "Normal" "Kernel" / location=inside across=1
            autoalign=(bottomright);
          endlayout;
        endlayout;
    endgraph;
  end;
run;
proc template;
  define statgraph racefactors;
    begingraph;
      entrytitle "Distributions of Racial Predictive Factors";
        layout lattice / rows=2 columns=2;
          layout overlay;
            histogram  pell  / scale=proportion;
          	densityplot pell / lineattrs=GraphFit  normal() name="Normal";
          	densityplot pell / lineattrs=GraphFit2 kernel() name="Kernel";
            discretelegend "Normal" "Kernel" / location=inside across=1
            autoalign=auto;
          endlayout;
          layout overlay;
            histogram  admit_pct  / scale=proportion;
            densityplot admit_pct / lineattrs=GraphFit  normal() name="Normal";
            densityplot admit_pct / lineattrs=GraphFit2 kernel() name="Kernel";
            discretelegend "Normal" "Kernel" / location=inside across=1
            autoalign=auto;
          endlayout;
          layout overlay;
            histogram  satavg  / scale=proportion;
            densityplot satavg / lineattrs=GraphFit  normal() name="Normal";
            densityplot satavg / lineattrs=GraphFit2 kernel() name="Kernel";
            discretelegend "Normal" "Kernel" / location=inside across=1
            autoalign=auto;
          endlayout;
          layout overlay;
            histogram  lcdr3  / scale=proportion;
            densityplot lcdr3 / lineattrs=GraphFit  normal() name="Normal";
            densityplot lcdr3 / lineattrs=GraphFit2 kernel() name="Kernel";
            discretelegend "Normal" "Kernel" / location=inside across=1
            autoalign=auto;
          endlayout;
        endlayout;
    endgraph;
  end;
run;

/* render graphs from templates */
proc sgrender data=regsample template=racehist;
run;
proc sgrender data=regsample template=racefactors;
run;

/* correct for skew in blck, hsp, asn vars*/
data regsample;
	set regsample;
	/* add 1 to each to account for log(0) error possibility*/
	lblck = log(blck + 1);
	lhsp = log(hsp + 1);
	lasn = log(asn + 1);
	lcdr3 = log(cdr3 + 1);
run;

/* check normality assumption again */
proc template;
  define statgraph lracehist;
    begingraph;
      entrytitle "Distributions of Races";
        layout lattice / rows=2 columns=2;
          layout overlay;
            histogram  wht  / scale=proportion;
          	densityplot wht / lineattrs=GraphFit  normal() name="Normal";
          	densityplot wht / lineattrs=GraphFit2 kernel() name="Kernel";
            discretelegend "Normal" "Kernel" / location=inside across=1
            autoalign=auto;
          endlayout;
          layout overlay;
            histogram  lblck  / scale=proportion;
            densityplot lblck / lineattrs=GraphFit  normal() name="Normal";
            densityplot lblck / lineattrs=GraphFit2 kernel() name="Kernel";
            discretelegend "Normal" "Kernel" / location=inside across=1
            autoalign=auto;
          endlayout;
          layout overlay;
            histogram  lhsp  / scale=proportion;
            densityplot lhsp / lineattrs=GraphFit  normal() name="Normal";
            densityplot lhsp / lineattrs=GraphFit2 kernel() name="Kernel";
            discretelegend "Normal" "Kernel" / location=inside across=1
            autoalign=auto;
          endlayout;
          layout overlay;
            histogram  lasn  / scale=proportion;
            densityplot lasn / lineattrs=GraphFit  normal() name="Normal";
            densityplot lasn / lineattrs=GraphFit2 kernel() name="Kernel";
            discretelegend "Normal" "Kernel" / location=inside across=1
            autoalign=(bottomright);
          endlayout;
        endlayout;
    endgraph;
  end;
run;
proc template;
  define statgraph lracefactors;
    begingraph;
      entrytitle "Distributions of Racial Predictive Factors";
        layout lattice / rows=2 columns=2;
          layout overlay;
            histogram  pell  / scale=proportion;
          	densityplot pell / lineattrs=GraphFit  normal() name="Normal";
          	densityplot pell / lineattrs=GraphFit2 kernel() name="Kernel";
            discretelegend "Normal" "Kernel" / location=inside across=1
            autoalign=auto;
          endlayout;
          layout overlay;
            histogram  admit_pct  / scale=proportion;
            densityplot admit_pct / lineattrs=GraphFit  normal() name="Normal";
            densityplot admit_pct / lineattrs=GraphFit2 kernel() name="Kernel";
            discretelegend "Normal" "Kernel" / location=inside across=1
            autoalign=auto;
          endlayout;
          layout overlay;
            histogram  satavg  / scale=proportion;
            densityplot satavg / lineattrs=GraphFit  normal() name="Normal";
            densityplot satavg / lineattrs=GraphFit2 kernel() name="Kernel";
            discretelegend "Normal" "Kernel" / location=inside across=1
            autoalign=auto;
          endlayout;
          layout overlay;
            histogram  lcdr3  / scale=proportion;
            densityplot lcdr3 / lineattrs=GraphFit  normal() name="Normal";
            densityplot lcdr3 / lineattrs=GraphFit2 kernel() name="Kernel";
            discretelegend "Normal" "Kernel" / location=inside across=1
            autoalign=auto;
          endlayout;
        endlayout;
    endgraph;
  end;
run;
proc sgrender data=regsample template=lracehist;
run;
proc sgrender data=regsample template=lracefactors;
run;
/* regressions on race*/
proc reg data=regsample;
	title 'Which metrics are predictive of Race: White';
	model wht = pell admit_pct satavg cdr3;
run;
proc reg data=regsample;
	title 'Which metrics are predictive of Race: Black';
	model lblck = pell admit_pct satavg cdr3;
run;
proc reg data=regsample;
	title 'Which metrics are predictive of Race: Hispanic';
	model lhsp = pell admit_pct satavg cdr3;
run;
proc reg data=regsample;
	title 'Which metrics are predictive of Race: Asian';
	model lasn = pell admit_pct satavg cdr3;
run;
