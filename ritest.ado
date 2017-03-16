*! version 0.0.4  16aug2016 based on permute.ado (version 2.7.3  16feb2015).


cap program drop ritest
cap program drop RItest
cap program drop permute_extfile
cap program drop permute_simple
cap program drop rit_Results
cap program drop rit_GetResults
cap program drop rit_DisplayResults
cap program drop rit_GetEvent
cap program drop rit_TableFoot 
cap program drop ClearE

program ritest
	version 11

	set prefix ritest

	capture syntax [anything] using [, * ]
	if !c(rc) {
		if _by() {
			error 190
		}
		Results `0'
		exit
	}

//	quietly ssd query
//	if (r(isSSD)) {
//		di as err " not possible with summary statistic data"
//		exit 111
//	}
	

	preserve
	`version' RItest `0'
end

program RItest, rclass
	version 11
	local ritestversion "0.0.4"
	// get name of variable to permute
	gettoken permvar 0 : 0, parse(" ,:")
	confirm variable `permvar'
	unab permvar : `permvar'

	// <my_stuff> : <command>
	_on_colon_parse `0'
	local command `"`s(after)'"'
	local 0 `"`s(before)'"'
	
	syntax anything(name=exp_list			///
		id="expression list" equalok)		///
		[fw iw pw aw] [if] [in] [,		///
			FORCE				///
			noDROP				///
			Level(passthru)			///
			*				/// other options
		]

	if "`weight'" != "" {
		local wgt [`weight'`exp']
	}

	// parse the command and check for conflicts check all weights and stuff
	`version' _prefix_command ritest `wgt' `if' `in' , ///
		`efopt' `level': `command'

	if "`force'" == "" & `"`s(wgt)'"' != "" {
		// permute does not allow weights
		local 0 `s(wgt)'
		syntax [, NONOPTION ]
	}

	local version	`"`s(version)'"'
	local cmdname	`"`s(cmdname)'"'
	local cmdargs	`"`s(anything)'"'
	local wgt	`"`s(wgt)'"'
	local wtype	`"`s(wtype)'"'
	local wexp	`"`s(wexp)'"'
	local cmdopts	`"`s(options)'"'
	local rest	`"`s(rest)'"'
	local efopt	`"`s(efopt)'"'
	local level	`"`s(level)'"'
	// command initially executed using entire dataset
	local xcommand	`"`s(command)'"'
	if "`drop'" != "" {
		// command with [if] [in]
		local command	`"`s(command)'"'
	}
	else {
		// command without [if] [in]
		local command	`"`cmdname' `cmdargs' `wgt'"'
		if `"`cmdopts'"' != "" {
			local command `"`:list retok command', `cmdopts'`rest'"'
		}
		else	local command `"`:list retok command'`rest'"'
		local cmdif	`"`s(if)'"'
		local cmdin	`"`s(in)'"'
	}
	
	//now check the options
	local 0 `", `options'"'
	syntax  [,			///
		noDOTS			///
		Reps(integer 100)	///
		SAving(string)		///  not documented
		DOUBle			/// not documented (handles double precision)
		STRata(varlist)		///
		CLUster(varlist)        ///
		PERMFile(string)          ///
		PERMMatchvar(varlist)   ///
		PERMProgram(name)		///
		PERMPROGRAMOptions(string) ///
		NOIsily			/// "prefix" options
		LEft RIght		/// 
		noHeader		///  not documented
		noLegend		///  not documented
		NOANALYtics		/// not documented
		KDENSityplot	/// 
		*			///
	]

	if (("`strata'" != "" | "`cluster'" !=  "") & ("`permfile'" != "" | "`permmatchvar'" !=  "")){
		di as err "Options strata() and cluster() may not be combinded with permfile() and permmatchvar()"
		exit 198
	}
	if "`strata'" == "" {
            tempvar strata
            gen `strata' = 1
        }
        if "`cluster'" == "" {
            tempvar cluster 
            gen `cluster' = _n
        }
        ///check validy of clusters
        qui loneway `permvar' `cluster'
        if (r(sd_w) != 0 & !missing(r(sd_w))) {
            di as err "`permvar' doesnt seem to be constant within clusters"
            exit 9999
        }
        qui loneway `permvar' `strata'
        if (r(sd_w) == 0){
            di as err "Warning: some strata contain no variation in `permvar'"
        }
        
        
	if "`noisily'" != "" {
		local dots nodots
	}
	local nodots `dots'
	local dots = cond("`dots'" != "", "*", "_dots")
	local noi = cond("`noisily'"=="", "*", "noisily")

//I have no clue what this does:
	// preliminary parse of <exp_list>
	_prefix_explist `exp_list', stub(_pm_)
	local eqlist	`"`s(eqlist)'"'
	local idlist	`"`s(idlist)'"'
	local explist	`"`s(explist)'"'
	local eexplist	`"`s(eexplist)'"'

	_prefix_note `cmdname', `nodots'
	if "`noisily'" != "" {
		di "ritest: First call to `cmdname' with data as is:" _n
		di as inp `". `command'"'
	}
//until here

        if "`permfile'"!="" { //check if permfile is okay and sort
            preserve
            qui use `permfile', clear
            qui sort `permmatchvar', stable
            qui desc
            if (r(k)-1)<`reps' {
                di as err "Permutation dataset does not contain enough permutations to complete `reps' repetitions"
                exit 2001
            }
            qui save `permfile', replace
            restore
        }

	// run the command using the entire dataset
	preserve
	_prefix_clear, e r
	capture noisily quietly `noisily'		///
                `command'
//	local rc = c(rc)
	//local checkmat 0
	//capture confirm matrix e(b) e(V)
        //if !_rc {
         //       tempname fullmat
           //     _check_omit `fullmat',get
		//local checkmat 1
//        }
	// error occurred while running on entire dataset
	//if `rc' {
	//	_prefix_run_error `rc' permute `cmdname'
	//}
	// check for rejection of results from entire dataset
	//if `"`reject'"' != "" {
	//	_prefix_reject permute `cmdname' : `reject'
	//	local reject `"`s(reject)'"'
	//}

	// check e(sample)
//	_prefix_check4esample permute `cmdname'
//	if "`drop'" == "" {
//		local keepesample `"`s(keep)'"'
//	}
//	if "`warn'" == "" {
//		local diwarn	`"`s(diwarn)'"'
//	}

	// expand eexp's that may be in eexplist, and build a matrix of the
	// computed values from all expressions
	tempname b
	_prefix_expand `b' `explist',		///
		stub(_pm_)			///
		eexp(`eexplist')		///
		colna(`idlist')			///
		coleq(`eqlist')			///

        local k_eq	`s(k_eq)'
	local k_exp	`s(k_exp)'   //number of expressions
	local k_eexp	`s(k_eexp)'  //number of eexpressions
	local K = `k_exp' + `k_eexp' //number of expression + eexprsessions
	local k_extra	`s(k_extra)'
	local names	`"`s(enames)' `s(names)'"'
	local coleq	`"`s(ecoleq)' `s(coleq)'"'
	local colna	`"`s(ecolna)' `s(colna)'"'
	forval i = 1/`K' {
		local exp`i' `"`s(exp`i')'"'
	}
	// setup list of missings
	forvalues j = 1/`K' {
		local mis `mis' (.)
		if missing(`b'[1,`j']) {
			di as err ///
			`"'`exp`j''' evaluated to missing in full sample"'
			exit 322
		}
	}


	local ropts	///eps(`eps')		///
			`left' `right'		///
			level(`level')		///
			`header'		///
			`verbose'		///
			`title'			///
			`table'			///
			`diopts'

	// check options
	if `reps' < 1 {
		di as err "reps() must be a positive integer"
		exit 198
	}
	if `"`saving'"'=="" {
		tempfile saving
		local filetmp "yes"
	}
	else {
		_prefix_saving `saving'
		local saving	`"`s(filename)'"'
		if "`double'" == "" {
			local double	`"`s(double)'"'
		}
		local replace	`"`s(replace)'"'
	}

	if `"`strata'"' != "" {
		if `:list permvar in strata' {
			di as err "permutation variable may not be specified in strata() option"
			exit 198
		}
//		tempvar sflag touse
//		mark `touse'
//		markout `touse' `strata'
//		sort `touse' `strata', stable
//		by `touse' `strata': gen `sflag' = _n==1 if `touse'
//		qui replace `sflag' = sum(`sflag')
//		local nstrata = `sflag'[_N]
//		local ustrata `strata'
//		local strata `sflag'
		sort `strata' , stable
	}
	if `"`cluster'"' != "" {
		if `:list permvar in strata' {
			di as err "cluster variable may not be specified in strata() option"
			exit 198
		}
		sort `cluster' , stable
        }
	local obs = _N
	if "`strata'"!="" {
		local bystrata "bys `strata',stable:"
	}
	if "`cluster'"!="" {
		local bycluster "bys `cluster',stable:"
	}
        local method 0
	if "`permfile'"!="" | "`permmatchvar'"!="" {
            local method extfile
            
	}
	else if "`permprogram'"!="" {
            local method program
			cap program list `permprogram'
			if _rc!=0 {
				di as err "permuation proceedure (`permprogram') does not exists"
				exit 198
			}
	}
	else {
            local method permute
        }

	// temp variables for post
	local stats
	forvalues j = 1/`K' {    //fore each expression generate a tempvar
		tempname x`j'
		local stats `stats' (`b'[1,`j'])
		local xstats `xstats' (`x`j'')
	}

	// prepare post
	tempname postnam
	postfile `postnam' `names' using `"`saving'"', ///
		`double' `every' `replace'
	post `postnam' `stats'

	// check if `permvar' is a single dichotomous variable
//	tempvar v
//	qui summarize `permvar'
//	local binary 0
//	capture assert r(N)==_N & (`permvar'==r(min) | `permvar'==r(max))
//	if c(rc)==0 {
//		tempname min max
//		scalar `min' = r(min)
//		scalar `max' = r(max)
//
//		qui `bystrata' gen long `v' = sum(`permvar'==`max')
//		qui `bystrata' replace `v' = `v'[_N]
//
//		local binary 1
//	}
//	else	gen `c(obs_t)' `v' = _n

	//methods such as "external file" or "automatic permuations" are wrapped in the third one
	if "`method'"=="permute" {
		local permprogram permute_simple
		local permprogramoptions "strata(`strata')     cluster(`cluster')"
    }
	else if "`method'"=="extfile" {
		local permprogram permute_extfile
		local permprogramoptions "file(`permfile')      matchvars(`permmatchvar')"
    }
	
	if ("`noanalytics'"=="") 	{ //This is the GOOGLE-ANALYTICS bitL
		set timeout1 1
		set timeout2 1
		tempfile foo
		cap copy "https://www.google-analytics.com/collect?payload_data&z=`:di round(runiform()*1000)'&v=1&tid=UA-65758570-2&cid=5555&t=pageview&dp=`method'&dt=Stata`di:  version'-$S_OS-$S_OSDTL&el=plain`kdensityplot'" `foo', replace
		set timeout1 30
		set timeout2 180
	}
	if "`dots'" == "*" {
		local noiqui noisily quietly
	}

	// do permutations
	if "`nodots'" == "" | "`noisily'" != "" {
		di
		_dots 0, title(Permutation replications) reps(`reps') `nodots'
	}
	local rejected 0
	forvalues i = 1/`reps' {
		cap `permprogram', run(`i') permvar(`permvar') `permprogramoptions'
		if _rc!=0 {
			di as err "Failed while calling permuation proceedure. Call was: " _n "{stata `permprogram', run(`i') permvar(`permvar') `permprogramoptions'}" _n as text "Error was: " 
			error _rc
		}	
        
		// analyze permuted data
		`noi' di as inp `". `command'"'
		capture `noiqui' `noisily'  `command'
		if (c(rc) == 1) error 1
		local bad = c(rc) != 0
		if c(rc) {
			`noi' di in smcl as error `"{p 0 0 2}an error occurred when I executed `cmdname', "' ///
                                                  `"posting missing values{p_end}"'
			post `postnam' `mis'
		}
		else {
//			if `checkmat' {
                            //_check_omit `fullmat', check result(res)
                              //  if `res' {
                                //        local bad 1
                                  //      `noi' di as error ///
//`"{p 0 0 2}collinearity in replicate sample is "' ///
//`"not the same as the full sample, posting missing values{p_end}"'
//					post `postnam' `mis'
  //                                      `dots' `i' `bad'
    //                                    continue
      //                          }
        //                }
			//if `"`reject'"' != "" {
			//	capture local rejected = `reject'
			//	if c(rc) {
			//		local rejected 1
			//	}
			//}
			//if `rejected' {
			//	local bad 1
			//	`noi' di as error ///
//`"{p 0 0 2}rejected results from `cmdname', "' ///
//`"posting missing values{p_end}"'
//				post `postnam' `mis'
//			}
//			else {
				forvalues j = 1/`K' {
					capture scalar `x`j'' = `exp`j''
					if (c(rc) == 1) error 1
					if c(rc) {
						local bad 1
						`noi' di in smcl as error ///
`"{p 0 0 2}captured error in `exp`j'', posting missing value{p_end}"'
						scalar `x`j'' = .
					}
					else if missing(`x`j'') {
						local bad 1
					}
				}
				post `postnam' `xstats'
//			}
		}
		`dots' `i' `bad'
	}
	`dots' `reps'

	// cleanup post
	postclose `postnam'

	// load file `saving' with permutation results and display output
	capture use `"`saving'"', clear
	if c(rc) {
		if c(rc) >= 900 & c(rc) <= 903 {
			di as err "insufficient memory to load file with permutation results"
		}
		error c(rc)
	}
	label data `"permute `permvar' : `cmdname'"'
	// save permute characteristics and labels to data set
	forvalues i = 1/`K' {
		local name : word `i' of `names'
		local x = `name'[1]
		char `name'[permute] `x'
		local label = substr(`"`exp`i''"',1,80)
		label variable `name' `"`label'"'
		char `name'[expression] `"`exp`i''"'
		if `"`coleq'"' != "" {
			local na : word `i' of `colna'
			local eq : word `i' of `coleq'
			char `name'[coleq] `eq'
			char `name'[colname] `na'
			if `i' <= `k_eexp' {
				char `name'[is_eexp] 1
			}
		}
	}
	if ("`kdensityplot'" != "") {
		foreach var of varlist * {
			qui sum `var' in 1, meanonly
			local a=r(mean)
			kdensity `var' in 2/-1, xline(`a') name(`var')
		}
	}
	char _dta[k_eq] `k_eq'
	char _dta[k_eexp] `k_eexp'
	char _dta[k_exp] `k_exp'
	char _dta[N_strata] `nstrata'
/*HERE I NEED TO ADD STUFF*/
	char _dta[strata] `ustrata'
	char _dta[N] `obs'
	char _dta[permvar] "`permvar'"
	char _dta[command] "`command'"
	
	quietly drop in 1

	if `"`filetmp'"' == "" {
		quietly save `"`saving'"', replace
	}

	ClearE
	rit_Results, `ropts'
	return add
	return scalar N_reps = `reps'
end
program permute_simple
    syntax , strata(varname) cluster(varname) permvar(varname) *
    
    tempvar ind nn newt rorder
	//create a random variable
    gen `rorder'=runiform()
    qui {
		//mark first obs in each cluster
		bys `strata' `cluster': gen `ind' = 1 if _n==1
		sum `ind'
		if r(N)==_N { //this means that all clusters are of size 1
			sort `permvar' //this is to shuffle all ovs
		}
		//across all first observations, generate a count variable
		bys `strata' `ind': gen `nn'=_n if `ind'!=.
		//now, reshuffle and across all first observations, take the treatment status from the observation which was at this position before
		sort `strata' `ind' `rorder'
		by `strata' `ind': gen `newt'=`permvar'[`nn']
		//place the first observations on top of each cluster
		sort `strata' `cluster' `ind'
		//copy down the treatment status
		by `strata' `cluster': replace `newt'=`newt'[_n-1] if missing(`newt')
		drop `permvar'  `nn' `ind' `rorder'
		rename `newt' `permvar' 
    }
end
program permute_extfile
    syntax ,file(string) matchvars(varlist) run(integer) permvar(varlist)
    sort `matchvars'
    cap isid `matchvars'
    if c(rc) {
        capture qui merge m:1 `matchvars' using `file', keepusing(`permvar'`run') nogen 
        if c(rc) {
            di as err "`permvar'`run' does not exist in the permutation data set"
        }
    }
    else {
        capture qui merge 1:1 `matchvars' using `file', keepusing(`permvar'`run') nogen 
        if c(rc) {
            di as err "`permvar'`run' does not exist in the permutation data set"
        }
    }
    drop `permvar'
    rename `permvar'`run' `permvar'
end
program rit_Results  //output the results in a nice table
	syntax [anything(name=namelist)]	///
		[using/] [,			///
			eps(real 1e-7)		/// -GetResults- options
			left			///
			right			///
			TItle(passthru)		///
			Level(cilevel)		/// -DisplayResults- options
			noHeader		///
			noLegend		///
			Verbose			///
			notable			/// not documented
			*			///
		]

	_get_diopts diopts, `options'
	if `"`using'"' != "" {
		preserve
		qui use `"`using'"', clear
	}
	else if `"`namelist'"' != "" {
		local namelist : list uniq namelist
		preserve
	}
	local 0 `namelist'
	syntax [varlist(numeric)]
	if "`namelist'" != "" {
		keep `namelist'
		local 0
		syntax [varlist]
	}

	rit_GetResults `varlist',	///
		eps(`eps')	///
		`left' `right'	///
		level(`level')	///
		`title'
	rit_DisplayResults, `header' `table' `legend' `verbose' `diopts'
end


program rit_GetResults, rclass
	syntax varlist [,		///
		Level(cilevel)		///
		eps(real 1e-7)		///
		left			///
		right			///
		TItle(string asis)	///
	]

	// get data characteristics
	// data version
	local version : char _dta[pm_version]
	capture confirm integer number `version'
	if c(rc) | "`version'" == "" {
		local version 1
	}
	else if `version' <= 0 {
		local version 1
	}
	// original number of observations
	local obs : char _dta[N]
	if "`obs'" != "" {
		capture confirm integer number `obs'
		if c(rc) {
			local obs
		}
		else if `obs' <= 0 {
			local obs
		}
	}
	// number of strata
	local nstrata : char _dta[N_strata]
	if "`nstrata'" != "" {
		capture confirm integer number `nstrata'
		if c(rc) {
			local nstrata
		}
	}
	// strata variable
	if "`nstrata'" != "" {
		local strata : char _dta[strata]
		if "`strata'" != "" {
			capture confirm names `strata'
			if c(rc) {
				local strata
			}
		}
	}
	// permutation variable
	local permvar : char _dta[permvar]
	capture confirm name `permvar'
	if c(rc) | `:word count `permvar'' != 1 {
		local permvar
	}
	if `"`permvar'"' == "" {
		di as error ///
"permutation variable name not present as data characteristic"
		exit 9
	}

	// requested event
	rit_GetEvent, `left' `right' eps(`eps')
	local event `s(event)'
	local rel `s(rel)'
	local abs `s(abs)'
	local minus `"`s(minus)'"'

	tempvar diff
	gen `diff' = 0
	local K : word count `varlist'
	tempname b c reps p se ci
	matrix `b' = J(1,`K',0)
	matrix `c' = J(1,`K',0)
	matrix `reps' = J(1,`K',0)
	matrix `p' = J(1,`K',0)
	matrix `se' = J(1,`K',0)
	matrix `ci' = J(1,`K',0) \ J(1,`K',0)

	local seed : char _dta[seed]
	local k_eexp 0
	forvalues j = 1/`K' {
		local name : word `j' of `varlist'
		local value : char `name'[permute]
		capture matrix `b'[1,`j'] = `value'
		if c(rc) | missing(`value') {
			di as err ///
`"estimates of observed statistic for `name' not found"'
			exit 111
		}
		quietly replace ///
		`diff' = (`abs'(`name') `rel' `abs'(`value') `minus' `eps')
		sum `diff' if `name'<., meanonly
		if r(N) < c(N) {
			local missing missing
		}
		mat `c'[1,`j'] = r(sum)
		mat `reps'[1,`j'] = r(N)
		quietly cii `=`reps'[1,`j']' `=`c'[1,`j']', level(`level')
		mat `p'[1,`j'] = r(mean)
		mat `se'[1,`j'] = r(se)
		mat `ci'[1,`j'] = r(lb)
		mat `ci'[2,`j'] = r(ub)
		local coleq `"`coleq' `"`:char `name'[coleq]'"'"'
		local colname `colname' `:char `name'[colname]'
		if `version' >= 2 {
			local exp`j' : char `name'[expression]
		}
		if `"`:char `name'[is_eexp]'"' == "1" {
			local ++k_eexp	
		}
	}
	local coleq : list clean coleq

	if `version' >= 2 {
		// command executed for each permutation
		local command : char _dta[command]
		local k_exp = `K' - `k_eexp'
	}
	else {
		local k_eexp 0
		local k_exp 0
	}

	// put stripes on matrices
	if `"`coleq'"' == "" {
		version 11: matrix colnames `b' = `varlist'
	}
	else {
		version 11: matrix colnames `b' = `colname'
		if `"`coleq'"' != "" {
			version 11: matrix coleq `b' = `coleq'
		}
	}
	matrix rowname `b' = y1
	_copy_mat_stripes `c' `reps' `p' `se' `ci' : `b', novar
	matrix rowname `ci' = ll ul
	matrix roweq `ci' = _ _

	// Save results
	return clear
	return hidden scalar version = `version'
	if "`obs'" != "" {
		return scalar N = `obs'
	}
	return scalar level = `level'
	return scalar k_eexp = `k_eexp'
	return scalar k_exp = `k_exp'
	return matrix reps `reps'
	return matrix c `c'
	return matrix b `b'
	return matrix p `p'
	return matrix se `se'
	return matrix ci `ci'
	return hidden local seed `seed'
	return local rngstate `seed'
	return local missing `missing'
	return local permvar `permvar'
	if "`nstrata'" != "" {
		return scalar N_strata = `nstrata'
		if "`strata'" != "" {
			return local strata `strata'
		}
	}
	return local event `event'
	return local left `left'
	return local right `right'
	forval i = 1/`K' {
		return local exp`i' `"`exp`i''"'
	}
	if `"`title'"' != "" {
		return local title `"`title'"'
	}
	else	return local title "Monte Carlo permutation results"
	return local command `"`command'"'
	return local cmd permute
end


program rit_DisplayResults, rclass
	syntax [,			///
		noHeader		///
		noLegend		///
		Verbose			///
		notable			///
		*			///
	]

	_get_diopts diopts, `options'
	if "`header'" == "" {
		_coef_table_header, rclass
		if r(version) >= 2 & "`legend'" == "" {
			_prefix_legend ritest, rclass `verbose'
			di as txt %`s(col1)'s "permute var" ":  `r(permvar)'"
		}
	}

	// NOTE: _coef_table_header needs the results in r() to work properly,
	// thus the following line happens here instead of at the very top.
	return add

	if ("`table'" != "") {
		exit
	}
	else if "`header'" == "" {
		di
	}

	tempname Tab results
	.`Tab' = ._tab.new, col(8) lmargin(0) ignore(.b)
	ret list
	// column           1      2     3     4     5     6     7     8
	.`Tab'.width	   13    |12     8     8     8     8    10    10
	.`Tab'.titlefmt %-12s      .     .     .     .     .  %20s     .
	.`Tab'.pad	    .      2     0     0     0     0     0     1
	.`Tab'.numfmt       .  %9.0g     .     . %7.4f %7.4f     .     .

	local cil `=string(`return(level)')'
	local cil `=length("`cil'")'
	if `cil' == 2 {
		local cititle "Conf. Interval"
	}
	else {
		local cititle "Conf. Int."
	}
                                                                                
	// begin display
	.`Tab'.sep, top
	.`Tab'.titles "T" "T(obs)" "c" "n" "p=c/n" "SE(p)" ///
		"[`return(level)'% `cititle']" ""

	tempname b c reps p se ci
	matrix `b' = return(b)
	matrix `c' = return(c)
	matrix `reps' = return(reps)
	matrix `p' = return(p)
	matrix `se' = return(se)
	matrix `ci' = return(ci)
	local K = colsof(`b')
	local colname : colname `b'
	local coleq   : coleq `b', quote
	local coleq   : list clean coleq
	if `"`:list uniq coleq'"' == "_" {
		local coleq
		.`Tab'.sep
	}
	local error5 "  (omitted)"
	local error6 "  (base)   "
	local error7 "  (empty)  "
	gettoken start : colname
	local ieq 0
	local i 1
	local output 0
	local first	// starts empty
	forvalues j = 1/`K' {
		local curreq : word `j' of `coleq'
		if "`curreq'" != "`eq'" {
			.`Tab'.sep
			di as res %-12s abbrev("`curreq'",12) as txt " {c |}"
			local eq `curreq'
			local i 1
			local ++ieq
		}
		else if "`name'" == "`start'" {
			.`Tab'.sep
		}
		_ms_display, el(`i') eq(#`ieq') matrix(`b') `first' `diopts'
		if r(output) {
			local first
			if !`output' {
				local output 1
			}
		}
		else {
			if r(first) {
				local first first
			}
			local ++i
			continue
		}
		local note	`"`r(note)'"'
		local err 0
		if "`note'" == "(base)" {
			local err 6
		}
		if "`note'" == "(empty)" {
			local err 7
		}
		if "`note'" == "(omitted)" {
			local err 5
		}
		.`Tab'.width . 13 . . . . . ., noreformat
		if `err' {
			local note : copy local error`err'
			.`Tab'.row "" "`note'" .b .b .b .b .b .b
		}
		else {
			.`Tab'.row ""		///
				`b'[1,`j']	///
				`c'[1,`j']	///
				`reps'[1,`j']	///
				`p'[1,`j']	///
				`se'[1,`j']	///
				`ci'[1,`j']	///
				`ci'[2,`j']	///
				// blank
		}
		.`Tab'.width . |12 . . . . . ., noreformat
		local ++i
	}
	.`Tab'.sep, bottom
	rit_TableFoot "`return(event)'" `K' `return(missing)'
end

program ClearE, eclass
	ereturn clear
end

program rit_GetEvent, sclass
	sret clear
	syntax [, left right eps(string)]
	if "`left'"!="" & "`right'"!="" {
		di as err "only one of left or right can be specified"
		exit 198
	}
	if "`left'"!="" {
		sreturn local event "T <= T(obs)"
		sreturn local rel "<="
		sreturn local minus "+"
	}
	else if "`right'"!="" {
		sreturn local event "T >= T(obs)"
		sreturn local rel ">="
		sreturn local minus "-"
	}
	else {
		sreturn local event "|T| >= |T(obs)|"
		sreturn local rel ">="
		sreturn local abs "abs"
		sreturn local minus "-"
	}
end

//program PermVars // "byvars" k var
//	version 11
//	local vv = _caller()
//	args strata k x
//	tempvar r y
//	quietly {
//		if `vv' <= 9 {
//			if "`strata'"!="" {
//				by `strata': gen double `r' = uniform()
//			}
//			else	gen double `r' = uniform()
//		}
//		else {
//			tempname w
//			gen double `r' = uniform()
//			gen double `w' = uniform()
//		}
//
//		sort `strata' `r' `w'
//		local type : type `x'
//		gen `type' `y' = `x'[`k']
//		drop `x'
//		rename `y' `x'
//	}
//end

//program PermDiV // "byvars" k min max var
//	version 11
//	args strata k min max x
//	tempvar y
//	if "`strata'"!="" {
//		sort `strata'
//		local bystrata "by `strata':"
//	}
//	quietly {
//		gen byte `y' = . in 1
//		`bystrata' replace `y' = ///
//			uniform()<(`k'-sum(`y'[_n-1]))/(_N-_n+1)
//		replace `x' = cond(`y',`max',`min')
//	}
//end

program rit_TableFoot 
	args event K missing
	if `K' == 1 {
		di as txt ///
"Note: Confidence interval is with respect to p=c/n."
	}
	else {
		di as txt ///
"Note: Confidence intervals are with respect to p=c/n."
	}
	if "`event'"!="" {
		di in smcl as txt "Note: c = #{`event'}"
	}
	if "`missing'" == "missing" {
		di as txt ///
"Note: Missing values observed in permutation replicates."
	}
end

exit
