# ritest
Stata package to perform randomization inference on any stata command.

The first version was published alongside an [article in the Stata Journal](http://www.stata-journal.com/article.html?article=st0489). I provide provide regular updates through GitHub.

## Installation
To obtain the latest version through github, from the main window in Stata, run:
>  net describe ritest, from(https://raw.githubusercontent.com/simonheb/ritest/master/)

If the download from within Stata fails (e.g. because you are behind a firewall),you can always download the files directly: 
 - https://raw.githubusercontent.com/simonheb/ritest/master/ritest.ado
 - https://raw.githubusercontent.com/simonheb/ritest/master/ritest.sthlp

## Bugs
There are no known bugs. The number of people who have used the code until now is small though, so please report any unintend or surprising behaviour. 

## Changelog
 - **1.0.5** Jason Kerwin pointed out that string strata-ids were ignored. This is fixed with this version. Also I sped execution time by dropping useless code.
 - **1.0.4** David McKenzie pointed out that under some conditions, the random-seed was ignored. This is fixed with this version
 - **1.0.3** Was published in Stata Journal

## Mentions
 - [Finally, a way to do easy randomization inference in Stata!](http://blogs.worldbank.org/impactevaluations/finally-way-do-easy-randomization-inference-stata) (blog post by David McKenzie)
 - [Simon Heß has a brand-new Stata package for randomization inference](https://jasonkerwin.com/nonparibus/2017/09/27/simon-hes-brand-new-stata-package-randomization-inference/) (blog post by Jason Kerwin)
