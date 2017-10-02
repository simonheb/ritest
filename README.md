# ritest
Stata package to perform randomization inference on any stata command

The first version was published alongside an article in the Stata Journal (http://www.stata-journal.com/article.html?article=st0489). I provide provide regular updates here.

* Installation
To obtain the latest version through github, from the main window in Stata, run:
  net describe ritest, from(https://raw.githubusercontent.com/simonheb/ritest/master/)

If the download from within Stata fails (e.g. because you are behind a firewall),you can always download the files directly: 
  https://raw.githubusercontent.com/simonheb/ritest/master/ritest.ado
  https://raw.githubusercontent.com/simonheb/ritest/master/ritest.sthlp

* Version history / Changelog
*1.0.5 Jason Kerwin pointed out that string strata-ids were ignored. This is fixed with this version. Also I sped execution time by dropping useless code.
*1.0.4 David McKenzie pointed out that under some conditions, the random-seed was ignored. This is fixed with this version
*1.0.3 Was published in Stata Journal
