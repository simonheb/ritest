{smcl}
{* *! version 0.0.4  01dec2016}{...}
{vieweralsosee "[R] simulate" "help permute"}{...}
{vieweralsosee "[R] bootstrap" "help bootstrap"}{...}
{vieweralsosee "[R] jackknife" "help jackknife"}{...}
{vieweralsosee "[R] simulate" "help simulate"}{...}
{viewerjumpto "Syntax" "ritest##syntax"}{...}
{viewerjumpto "Description" "ritest##description"}{...}
{viewerjumpto "Options" "ritest##options"}{...}
{viewerjumpto "Examples" "ritest##examples"}{...}
{viewerjumpto "Author" "ritest##author"}{...}
{title:Title}

{p2colset 5 20 22 2}{...}
{p2col :{bf:ritest} {hline 2}}Randomization inference and permutation tests, allowing for arbitrary randomization procedures{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}
Compute p values for Monte Carlo permutation tests, allowing for arbitrary randomization procedures

{p 8 16 2}
{cmd:ritest}
	{it:resampvar}
	{it:{help exp_list}}
	[{cmd:,} {it:{help ritest##options_table:options}}]
	{cmd::} {it:command}



{synoptset 27 tabbed}{...}
{marker options_table}{...}
{synopthdr}
{synoptline}
{syntab :Main}
{synopt :{opt r:eps(#)}}perform {it:#} random permutations; default is {cmd:reps(100)}{p_end}
{synopt :{opt le:ft}|{opt ri:ght}}compute one-sided p-values; default is two-sided{p_end}

{syntab :Automatic permuation}
{synopt :{opth str:ata(varlist)}}permute {it:resampvar} within strata{p_end}
{synopt :{opth clu:ster(varlist)}}keep {it:resampvar} constant within clusters{p_end}

{syntab :File-based  permuation}
{synopt :{opth samplings:ourcefile(filename)}}take permutations of {it:resampvar} from stata data file {it:filename}, containing variables named {it:resampvar}1, resampvar2, resampvar3, ...{p_end}
{synopt :{opth samplingm:atchvar(varlist)}}merge permutations in {it:samplingsourcefile} with the data using these variables (1:1 or m:1){p_end}

{syntab :Program-based permutation}
{synopt :{opth samplingp:rogram(it:programname)}}generate permutations of {it:resampvar} by calling user-written program {it:programname}{p_end}
{synopt :{opth samplingprogramo:ptions(string)}}optionally pass {it:string} as options to {it:programname} {p_end}

{syntab :Reporting}
{synopt :{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt :{opt v:erbose}}display full table legend{p_end}
{synopt :{opt nodots}}suppress replication dots{p_end}
{synopt :{opt noi:sily}}display any output from {it:command}{p_end}

{syntab :Advanced}
{synopt :{opt kdens:ityplot}}plot the densities of each statistic in {it:exp_list}{p_end}
{synopt :{opt kdenstyo:options(string)}}additional options to be passed on to {it:kdensity} {p_end}
{synopt :{opt saver:esampling(filename)}}save all permutations of {it:resampvar} in a file called {it:filename} for later inspection.{p_end}
{synopt :{opt noanal:ytics}}do not send anonymized usage statistics to google analytics{p_end}
{synopt :{opt seed(#)}} set random-number seed to #{p_end}
{synopt :{opt eps}}numerical tolerance; seldom used{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}{it:weights} are not allowed in {it:command} (they might work, but how they affect the results is unclear).
{p2colreset}


{marker description}{...}
{title:Description}

{pstd}
{cmd:ritest} estimates p-values for permutation tests on the basis of Monte Carlo
simulations.  Unlike permute, ritest allows to specify more complex permutation
structures, as generated for example by clustered treatment assignments.

{dlgtab:Automatic permutation}

{pin}
{cmd:. ritest} {it:resampvar} {it:exp_list}{cmd:,} {opt reps(#) strata(stratavar) cluster(clustervar)}{cmd::} {it:command}

{pstd}
randomly permutes the values in {it:resampvar} {it:#} times, respecting strata and clusters, each time executing
{it:command} and collecting the associated values from the expressions in
{it:exp_list}. Not specifying strata assumes no strata were used, which is
equivalent to all observations being in one single stratum. Not specifying clusters
assumes no clusters were used, which is equivalent to each observations being a separate cluster.

{dlgtab:File-based permutation}

{pin}
{cmd:. ritest} {it:resampvar} {it:exp_list}{cmd:,} {opt reps(#) samplingsourcefile(permutations.dta) samplingmatchvar(id)}{cmd::} {it:command}

{pstd}
merges the data based on {it:id} {it:#} times using {it:permutations.dta} (1:1, or if ids are not unique m:1). ). 
It executes {it:command} each time, replacing resampvar iteratively with {it:resampvar}1, {it:resampvar}2, {it:resampvar}3, ..., {it:resampvar}1000,
which have to be stored in {it:permutations.dta} prior to executing {cmd: ritest}. 

{dlgtab:Program-based permutation}

{pin}
{cmd:. ritest} {it:resampvar} {it:exp_list}{cmd:,} {opt reps(#) samplingprogram(progname) samplingprogramoptions(string)}{cmd::} {it:command}

{pstd}
permutes {it:resampvar} by calling a user-written program {it:progname}, and
passing the string {it:samplingprogramoptions} as options to this program.
Also, the program will to be passed at two standard arguments: {it:resampvar} is
the variable name of the relevant variable and {it:run} is an integer containing
the iteration.


{dlgtab:General}

{pstd}
{it:left|right} lets p-value estimates be one-sided:  Pr(T* {ul:<} T) or Pr(T* {ul:>} T).
The default is two-sided:  Pr(|T*| {ul:>} |T|).  Here T* denotes the value of
the statistic from a randomly permuted dataset, and T denotes the statistic
as computed on the original data.

{pstd}
{it:resampvar} identifies the variable whose observed values will be randomly
permuted.

{pstd}
{it:command} defines the statistical command to be executed.
Most Stata commands and user-written programs can be used with {cmd:ritest},
as long as they follow {help language:standard Stata syntax}.
The {cmd:by} prefix may not be part of {it:command}.

{pstd}
{it:exp_list} specifies the statistics to be collected from the execution of
{it:command}.  


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt reps(#)} specifies the number of permutations to perform.  The
default is 100.

{phang}
{opt left} or {opt right} requests that one-sided p-values be computed.
If {opt left} is specified, an estimate of Pr(T* {ul:<} T) is produced, where
T* is the test statistic and T is its observed value.  If {opt right} is
specified, an estimate of Pr(T* {ul:>} T) is produced.  By default, two-sided
p-values are computed; that is, Pr(|T*| {ul:>} |T|) is estimated.

{dlgtab:Options}

{phang}
{opth strata(varlist)} specifies that the permutations be
performed within each stratum defined by the values of {it:varlist}.

{phang}
{opth cluster(varlist)} specifies that the permutations be
performed treating each cluster as defined by {it:varlist} as one unit of assignment.

{phang}
{opth samplingsourcefile(filename)} specifies that permutations of {it:resampvar} have to be taken from stata data-file {it:filename}.
This dataset should contain variables named [resampvarname]1, [resampvarname]2, [resampvarname]3, ... and a unique id.

{phang}
{opth samplingmatchvar(varlist)} merge permutations in from {it:samplingsourcefile} with the data using these variables (1:1 or m:1 merge).

{phang}
{opth samplingprogram(programname)} specifies that permutations of {it:resampvar} be generated by calling user-written {it:programname}.

{phang}
{opth samplingprogramoptions(string)}	specifies that when {it:programname} is called {it:string} is also passed string as options to {it:programname}.


{dlgtab:Reporting}

{phang}
{opt level(#)} specifies the confidence level, as a percentage,
for confidence intervals. The default is {cmd:level(95)} or as set by 
{helpb level:set level}.

{phang}
{opt verbose} requests that the full table legend be displayed.  By default,
coefficients and standard errors are not displayed.

{phang}
{opt nodots} suppresses display of the replication dots.  By default, one 
dot character is displayed for each successful replication.  A red 'x'
is displayed if {it:command} returns an error or if one of the values in
{it:exp_list} is missing.

{phang}
{opt noisily} requests that any output from {it:command} be displayed.  This
option implies the {opt nodots} option.


{dlgtab:Advanced}

{phang}
{opt kdensityplot} produces a density plot of the realizations of expressions in
{it:exp_list}. The realization for the expression in the original data is drawn
as a vertical line.

{phang}
{opt noanalytics} suppresses the sending of anonymous usage statistics. If this 
is not specified and the computer is connected to the internet, ritest will send
a beacon to the author's google analytics account, containing information on (i)
the version of stata, (ii) the version of ritest, (iii) the operating system, and (iv) 
whether program-based, file-based, or automatic permutation was used. No information on 
the command used, the data used, or any other information regarding the user or the data
analysis is recorded. If you want to confirm that no other information is being sent,
search the .ado-file for "GOOGLE-ANALYTICS" to find the part of the code related to this.


{marker examples}{...}
{title:Examples}

{pstd} Assume the data consists of observations from 2 schools, each school has 4 classes of 10 students each. Classes were randomly assigned to treatment, stratifying by school. This assured that each school had two treatment and to control classes. The outcome are test scores and the researcher wants to do a fisher test for the sharp null of no treatment effect, in a regression controlling for gender. {p_end}

{dlgtab:Automatic resampling (permutation}

{phang2}{cmd:. ritest treatment _b[treatment], cluster(classid) strata(schoolid): reg testscore treatment age}{p_end}

{dlgtab:File-based resampling}

{phang2}{cmd:. # assuming you start with an empty datasets of classes containing }{p_end}
{phang2}{cmd:. # only schoolid and classid}{p_end}
{phang2}{cmd:. forvalues i = 1/100 (}{p_end}
{phang2}{cmd:. 		tempvar random cutoff}{p_end}
{phang2}{cmd:. 		gen `random'=rnormal()}{p_end}
{phang2}{cmd:. 		bys schoolid: egen `cutoff' = median(`random')}{p_end}
{phang2}{cmd:. 		gen treatment`i' = `random'> `cutoff'}{p_end}
{phang2}{cmd:. }}{p_end}
{phang2}{cmd:. save permutations.dta}{p_end}
{phang2}{cmd:. use studentdata.dta}{p_end}
{phang2}{cmd:. ritest treatment _b[treatment], samplingsourcefile(permutations.dta) samplingmatchvar(classid)}{p_end}

{pstd}The benefit of the file-based approach is that more complicated randomization structures can be implemented. For smaller samples, it is also straightforward to implement complete (non-stochastic) Fisher tests, which exhaust all possible permutations{p_end}

{dlgtab:Program-based resampling}

{pstd}Define a program to create random permuations:{p_end}
{phang2}{cmd:. program permme        ///define the program}{p_end}
{phang2}{cmd:.     syntax ,          ///}{p_end}
{phang2}{cmd:.     resampvar(varname)	 ///<- name of the permutation variable}{p_end}
{phang2}{cmd:.     stratvar(varname) ///<- name of the strata variable}{p_end}
{phang2}{cmd:.     clustvar(varname) ///<- name of the cluster variable}{p_end}
{phang2}{cmd:.     *		         ///<- ritest also passes other things to the permutation procedure (e.g. run(#))}{p_end}
{phang2}{cmd:. 	tempvar mr r}{p_end}
{phang2}{cmd:. 	qui bys `clustvar': gen `r'=rnormal() if _n==1 // draw one random variable per cluster}{p_end}
{phang2}{cmd:. 	qui bys `stratvar': egen `mr' = median(`r') if !missing(`r')  // compute median of these random variables within cluster}{p_end}
{phang2}{cmd:.  replace `resampvar' = cond(`r',`r'>`mr',.,.) // replace the permutation var with the new randomization outcome}{p_end}
{phang2}{cmd:.  sort `clustvar' `r' }{p_end}
{phang2}{cmd:.  by `clustvar': replace `resampvar' = `resampvar'[_n-1]  if missing(`resampvar') // replace the permutation var with the new randomization outcome for all remaining villages}{p_end}
{phang2}{cmd:. end}{p_end}


		 
		 

		 
{pstd}Call {cmd:ritest} using the program:{p_end}
{phang2}{cmd:. ritest t _b[t], samplingprogram(permme) ///}{p_end}
{phang2}{cmd:.  samplingprogramoptions("stratvar(schoolid) clustvar(classid)") ///}{p_end}
{phang2}{cmd:.  : reg y x t}{p_end}

{pstd}This method can be used implement any kind of re-randomization.{p_end}

{title:See also}

{pstd}
{help permute},
{help simulate},
{help bootstrap},
{help jackknife}

{title:Author and acknowledgements}

{pstd}
Simon Heﬂ, Goethe University Frankfurt, ({browse "mailto:hess@econ.uni-frankfurt.de":hess@econ.uni-frankfurt.de}){p_end}

{pstd}
The latest version of ritest can always be obtained from {browse "https://github.com/simonheb/geocodehere"} or {browse "http://HessS.org"}.
{p_end}

{pstd}
The {cmd:ritest}-code is based on and borrows heavily from the code for {cmd:permute}.
{p_end}

{pstd}
I am happy to receive comments and suggestions regarding bugs or possibilites for improvements/extensions.{p_end}
