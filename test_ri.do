clear all
local RR 1000
set maxvar `: di `RR' + 2048' 
local Nstrata 12
local Nclustpstrata 6
local Nobspclust 5

//prepare prererandomized data
local v=1
forvalues f=1/`v' {
	di "." _c
	tempfile a`f'
	preserve
	clear 
	qui set obs `Nstrata' //strata
	gen strata = _n
	gen strata_char = rnormal()
qui 	expand `Nclustpstrata' //clusters
	gen cluster = _n
	gen cluster_char = rnormal()
	forvalues i = 1/`RR' {
		gen r=rnormal()
		qui bys strata: egen mr = median(r)
		gen t`i' = r>mr
		drop r mr
	}
	gen id  = _n
	sort id
	save `a`f''
	restore
}
di "."
cap do Z:\home\simon\dropbox\randinference\ritest.ado
cap do C:\Dropbox\randinference\ritest.ado

cap program drop permmee
program permmee
	version 9
	syntax , permvar(varname) stratvar(varname) clustvar(varname) *
	tempvar rr mr r
	qui bys `clustvar': gen `r'=rnormal() if _n==1
	qui bys `stratvar': egen `mr' = median(`r') if !missing(`r')
	qui bys `clustvar': egen `rr' = mode(`r') 
	replace `permvar' = `rr'>`mr'
end

cap postclose aa
postfile aa p1 p2 p3 p4 teff	using results_pvalues, replace
forvalues iii=1/3000 {
	if `iii'/100 == round(`iii'/100) di `iii'
	di "."
	qui {
		clear
		qui set obs `Nstrata' //strata
		gen strata = _n
		gen strata_char = rnormal()
		expand `Nclustpstrata' //clusters
		gen cluster = _n
		gen cluster_char = rnormal()
		
		gen r=rnormal()
		qui bys strata: egen mr = median(r)
		gen t = r>mr
//		drop mr r
		expand `Nobspclust' // observations
		gen x = rnormal()
		local teff = rnormal()>0
		gen e = rnormal()
		gen y = x + t*0.4*`teff'  + e + strata_char  + cluster_char 
		gen id  = _n
		noi {
		ritest t _b[t], nodots permprogram(permmee) permprogramoptions("stratvar(strata) clustvar(cluster)") r(`RR') : reg y x t
		ritest t _b[t], nodots strata(strata) kdensityplot r(`RR') : reg y x t
		vfdv
		pause
		
		permute t _b[t], nodots strata(strata)  r(`RR'): reg y x t
		ritest t _b[t], nodots r(`RR'): reg y x t
		permute t _b[t], nodots  r(`RR'): reg y x t
		pause on 
		pause
		}
		ritest t _b[t],  nodots permfile(`a`: di ceil(runiform()*`v')'')  permmatchvar(id) r(`RR'): reg y x t
		mat a = r(p)
		local p1=a[1,1]
		ritest t _b[t], nodots cluster(cluster) strata(strata) r(`RR'): reg y x t
		mat a = r(p)
		local p2=a[1,1]
		areg y x  t, absorb(strata) cluster(cluster) 
		testparm t
		local p3=r(p)
		reg y x  t, cluster(cluster) noheader
		testparm t
		local p4=r(p)
		post  aa (`p1') (`p2') (`p3') (`p4') (`teff') 
	}
}

postclose aa
use results_pvalues,clear
rename p1 p_perm_file
rename p2 p_perm_stratacluster
rename p3 p_aregstrata_clustse
rename p4 p_reg_clustse
