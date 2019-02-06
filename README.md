# ritest
Stata package to perform randomization inference on any Stata command.

ToC:
 - [Install](#install) 
 - [Citation](#citation)
 - [Changelog](#changelog)
 - [Media Coverage](#media-coverage)
 - [FAQ](#faq)


## Install
To obtain the latest version through github, from the main window in Stata, run:
```
net describe ritest, from(https://raw.githubusercontent.com/simonheb/ritest/master/)
```
If the download from within Stata fails (e.g. because you are behind a firewall),you can always download the files directly: 
 - https://raw.githubusercontent.com/simonheb/ritest/master/ritest.ado
 - https://raw.githubusercontent.com/simonheb/ritest/master/ritest.sthlp

## Citation
Heß, Simon, "Randomization inference with Stata: A guide and software" *Stata Journal* 17(3) pp. 630-651.

[BibTeX record](https://raw.githubusercontent.com/simonheb/ritest/master/ritest.bib)

## Bugs
There are no known bugs. Please report any unintend or surprising behaviour. 

## Changelog
 - **1.1.2** Fixed the issue that data sanity checks were applied to the full sample, even if and [if] or [in]-statement was used to restrict analysis to a subsample. h/t Fred Finan
 - **1.1.0** added an option (fixlevels()) to constrain re-randomization to certain values of the treatment variable. This can be used for pairwise tests in multi-treatment experiments, by  restricting permutation to only some treatment arms. 
 - **1.0.9** added the strict and the eps option to the helpfile and added parameter-checks so that "strict" enforces "eps(0)". h/t Katharina Nesselrode
 - **1.0.8** minor bugfix and I got rid of the google analytics part
 - **1.0.7** Jason Kerwin pointed out that when string variables were used as strata or cluster ids, all observations were treated as belonging to the same. This is fixed with this version. Also I sped up execution time by dropping unneeded code.
 - **1.0.6** Jason Kerwin pointed out an issue with the "saveresampling()"-option. This version fixes this.
 - **1.0.4** David McKenzie pointed out that under some conditions, the random seed was ignored. This is fixed with this version.
 - **1.0.3** is the version that was published in the Stata Journal.

## Media Coverage
 - [Finally, a way to do easy randomization inference in Stata!](http://blogs.worldbank.org/impactevaluations/finally-way-do-easy-randomization-inference-stata) (blog post by David McKenzie)
 - [Simon Heß has a brand-new Stata package for randomization inference](https://jasonkerwin.com/nonparibus/2017/09/27/simon-hes-brand-new-stata-package-randomization-inference/) (blog post by Jason Kerwin)

## Disclaimer of Warranties and Limitation of Liability
Use at own risk. You agree that use of this software is at your own risk. The author is optimistic but does not make any warranty as to the results that may be obtained from use of this software. The author would be very happy to hear about any issues you might find and will be transparent about changes made in response to user inquiries.


## FAQ

### How do I export ritest results with `estout`?
run ritest:
```eststo regressionresult: reg y treatment controls 
ritest treatment _b[treatment]: `e(cmdline)'
```
extract the RI p-values:
```
matrix pvalues=r(p) //save the p-values from ritest
mat colnames pvalues = treatment //name p-values so that esttab knows to which coefficient they belong 
est restore regressionresult        
```
display the p-values in the table footer:
```
estadd scalar pvalue_treat = pvalues[1,1]
esttab regressionresult, stats(pvalue_treat)
```
alternatively, display the p-values next to the coefficient 
```
estadd matrix pvalues = pvalues
esttab regressionresult, cells(b p(par) pvalues(par([ ])))
```

### Can you give a simple example using `ritest` together with a difference-in-differences regression with binary treatment and panel data?
This won't  work:
```
gen treatpost = treatment*post
ritest treatment _b[treatpost]: reg y treatment post treatpost
```
for two reasons:
 - `ritest` will keep permuting `treatment`, but is not aware that  `treatpost` will need to be updated as well.
 - `ritest` does not know that `treatment` has to be held constant within units.
 
instead run:
```
ritest treatment _b[c.treatment#c.post], cluster(unit_id): reg y c.treatment##c.post
```
