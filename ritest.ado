*! version 1.21 mar2024.
***** Changelog
*1.21 added the "reseed" option to set the seed in every loop iteration. This can ensure that code is replicable even if function that is called on changes 
*1.20 added xtset support to permute_simple
*1.19 fixed a bug that in introduced in 1.1.8 (not relevant for results, only caused an error message when saving the resampled treatment)
*1.18. the external file permuations method was overwriting the permutation file with a sorted version of itself. fixed that.
*1.17.1 changed the interpreter to stata 17
*1.1.8 saveresampling now accepts , replace
*1.1.7 restore results of original estimation
*1.1.6 fixes for spaces in filenames
*1.1.5 some fixes for filenames
*1.1.4 Added the reject() option, works as in permute
*1.1.3 Updated version statement, because older versions (11) of Stata couldn't handle some of the code
*1.1.2 Fixed the issue that data sanity checks were applied to the full sample, even if and [if] or [in]-statement was used to restrict analysis to a subsample. h/t fred finan
*1.1.0 added a new option "fixlevels" to contstraint he rerandomization to certain levels of the treatment variable
*1.0.9 added the strict and the eps option to the helpfile and added parameter-checks so that "strict" enforces "eps(0)". h/t Katharina Nesselrode
*1.0.8 fixed (removed `') the "replace" option for the postfile statement as it was causing trouble when running ritest in wine and also I deactivated google analytics tracking
*1.0.7 made sure that string cluster-identifiers are also treated correctly.
*1.0.6 fixed an error message that appeared when the "saveresampling()" option was used. h/t Jason Kerwin
*1.0.5 sped up the execution time for the permutation commmand (permute_simple) by dropping unneeded parts
*1.0.5 made sure that string strata-identifiers are also treated correctly.
*1.0.4 fixed the missing ",stable" for a sort in permute_simple, as suggested by david mckenzie.
*1.0.3 hide the warnings introduced with 1.0.1, as requested by stata jounral 
*1.0.2 "if" and  "in" for the subcommand will now be considered irrespective of "drop" or "nodrop" are specified 
*1.0.1 now can be called with the option RANDOMIZATIONProgram OR SAMPLINGprogram



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
	version 13

	set prefix ritest

	capture syntax [anything] using [, * ]
	if !c(rc) {
		if _by() {
			error 190
		}
		Results `0'
		exit
	}

	quietly ssd query
	if (r(isSSD)) {
		di as err " not possible with summary statistic data"
		exit 111
	}
	

	preserve
	`version' RItest `0'
end

program RItest, rclass
	version 13
	local ritestversion "1.1.4"
	// get name of variable to permute
	gettoken resampvar 0 : 0, parse(" ,:")
	confirm variable `resampvar'
	unab resampvar : `resampvar'

	// <my_stuff> : <command>
	_on_colon_parse `0'
	local command `"`s(after)'"'
	local 0 `"`s(before)'"'
	
	syntax anything(name=exp_list			///
		id="expression list" equalok)		///
		[fw iw pw aw] [if] [in] [,		///
			FORCE				///
			Level(passthru)			///
			*				/// other options
		]

	if "`weight'" != "" {
		local wgt [`weight'`exp']
	}

	// parse the command and check for conflicts
	// check all weights and stuff
	`version' _prefix_command ritest `wgt' `if' `in' , ///
		`efopt' `level': `command'
	
	if "`force'" == "" & `"`s(wgt)'"' != "" {
		// ritest does not allow weights unless force is used
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
	local command	`"`s(command)'"'
	local ifin `"`s(if)' `s(in)'"'
	
	//now check the options
	local 0 `", `options'"'
	syntax  [,			///
		noDOTS			///
		lessdots		/// not documented, only displays 1/10 dots
		Reps(integer 100)	///
		SAving(string)		///  
		SAVEResampling(string)		///  save resampvar for every round
		SAVERAndomization(string) ///  synonym for the above
		DOUBle			/// not documented (handles double precision)
		STRata(varlist)		///
		CLUster(varlist)        ///
		FIXlevels(string)        ///
		SEED(string)		///
		reseed                  /// resets the seed in every iteration
		EPS(real 1e-7)		/// -Results- options
		SAMPLINGSourcefile(string)          ///
		RANDOMIZATIONSourcefile(string) ///syno ^
		SAMPLINGMatchvar(varlist)   ///
		RANDOMIZATIONMatchvar(string) ///syno ^
		SAMPLINGProgram(name)		///
		RANDOMIZATIONProgram(string) ///syno ^
		SAMPLINGPROGRAMOptions(string) ///
		RANDOMIZATIONPROGRAMOptions(string) ///syno ^
		null(string) ///
		REJECT(string asis)	///
		NOIsily			/// "prefix" options
		LEft RIght		/// 
		STRict			///
		noHeader		///  not documented
		noLegend		///  not documented
		NOANALYtics		/// now obsolete
		COLLApse		/// not documented and not recommended
		KDENSityplot	/// 
		KDENSITYOptions(string)	///  not documented
		*			///
	]
	_get_diopts diopts, `options' //this makes sure no false options are passed

	//AT version 1.0.3 I switched from calling things "Sampling*" to calling them "Randomization*".
	//The following is to create backwardscompatibility and to make sure the code doesnt need to be changed
	//as long as the errs are commented out, the different options are just synonyms
	if ("`saveresampling'"=="") {
		local saveresampling  `saverandomization'
	} 
	else {
		//di as err "You're using deprecated syntax -saveresampling-, please use -saverandomization- instead"
	}
	if ("`samplingsourcefile'"=="") {
		local samplingsourcefile  `"`randomizationsourcefile'"'
	}
	else {
		//di as err "You're using deprecated syntax -samplingsourcefile-, please use -randomizationsourcefile- instead"
	}
	if ("`samplingmatchvar'"=="") {
		local samplingmatchvar `randomizationmatchvar'
	}
	else {
		//di as err "You're using deprecated syntax -samplingmatchvar-, please use -randomizationmatchvar- instead"
	}
	if ("`samplingprogram'"=="") {
		local samplingprogram  `randomizationprogram'
	}
	else {
		//di as err "You're using deprecated syntax -samplingprogram-, please use -randomizationprogram- instead"
	}
	if ("`samplingprogramoptions'"=="") {
		local samplingprogramoptions  `randomizationprogramoptions'
	}
	else {
		//di as err "You're using deprecated syntax -samplingprogramoptions-, please use -randomizationprogramoptions- instead"
	}
	
	if (("`strata'" != "" | "`cluster'" !=  "" | `"`fixlevels'"' !=  "") + ("`samplingsourcefile'" != "" | "`samplingmatchvar'" !=  "")  + ("`samplingprogram'" != "" | "`samplingprogramoptions'" !=  "") )>1    {
		di as err "Alternative sampling methods may not be combined."
		exit 198
	}
	if "`saveresampling'"!="" {
		tempvar originalorder
		tempfile preservetemp
		tempfile resamplingtemp
		gen `originalorder'=_n
		qui save `"`resamplingtemp'"'
		
		_prefix_saving `saveresampling'
		local fname = s(filename)
		local freplace = s(replace)
		local sr_replace : subinstr local freplace "." ""
		local sr_filename : subinstr local fname ".dta" ""
	}
	if "`strata'" == "" {
            tempvar strata
            gen `strata' = 1
		local strata_orignal_varnames none
    }
	else {
		local strata_orignal_varnames "`strata'"
	}

    if "`cluster'" == "" {
            tempvar cluster 
            gen `cluster' = _n
    }

        
    // set the seed
	if "`seed'" != "" {
		local origseed `seed'
		`version' set seed `seed'
	}
	local seed `c(seed)'
   
	if "`noisily'" != "" {
		local dots nodots
	}
	local nodots `dots'
	local dots = cond("`dots'" != "", "*", "_dots")
	local noi = cond("`noisily'"=="", "*", "noisily")

	if "`samplingsourcefile'"!="" { //check if samplingsourcefile is okay and sort
			tempfile samplingsourcefilesorted
            preserve
            qui use `"`samplingsourcefile'"', clear
            qui sort `samplingmatchvar', stable
            qui desc
            if (r(k)-1)<`reps' {
                di as err "Permutation dataset does not contain enough permutations to complete `reps' repetitions"
                exit 2001
            }
            qui save `"`samplingsourcefilesorted'"', replace
			local samplingsourcefile `"`samplingsourcefilesorted'"'
            restore
    }

	// preliminary parse of <exp_list>
	_prefix_explist `exp_list', stub(_pm_)
	local eqlist	`"`s(eqlist)'"'
	local idlist	`"`s(idlist)'"'
	local explist	`"`s(explist)'"'
	local eexplist	`"`s(eexplist)'"'

	_prefix_note `cmdname', `nodots'

	`noi' di as inp `". `command'"'

	if "`noisily'" != "" {
		di "ritest: First call to `cmdname' with data as is:" _n
	}
     
	// run the command using the entire dataset (for output) //this needs to be done before the data set is altered to account for `null'
	`noisily' `command'
	//mark the sample to be used
	tempvar touse
	mark `touse' `ifin'
	
	preserve  //this will only be restored in the very end 
	if ("`null'"!="") {
		di as text "User specified non-zero null hypothesis" 
		local vari : word 1 of `null'
		local valu : word 2 of `null'
		capture confirm variable `vari'
		if (_rc != 0) {
			di as err "Hypotheses seem to be misspecified, `vari' is not a variable in the current data set"
			exit 9
		}
		cap confirm number `valu'
		if (_rc!=0) {
			capture confirm variable `valu'
		}
		if (_rc != 0) {
			di as err "Hypotheses seem to be misspecified, second argument to hypothesis has to be numeric or a varialbe name"
			exit 9
		}
		di as text "Under the null hypothesis:" 
		di as text " `vari' has treatment effect: `resampvar'*`valu'"
		qui replace `vari' = `vari' - `resampvar'*`valu'
		di as text " (these values are being subtracted from the outcome)"
	}


	_prefix_clear, e r
	// run the command using the entire dataset (to get the estimate) after imposing `null'
	qui `noisily'		///
                `command'
	tempname originalestimates
	est store `originalestimates'
				
				
	// check for rejection of results from entire dataset
	if `"`reject'"' != "" {
		_prefix_reject ritest `cmdname' : `reject'
		local reject `"`s(reject)'"'
	}
	
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
	


	local ropts	eps(`eps')		///
			`left' `right'		///
			`strict'             ///
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
	if `"`fixlevels'"' != "" {
		tempvar fixedvalues_indicator
		qui gen `fixedvalues_indicator'=.
		local ccc 0
		foreach value of local fixlevels {
			qui sum `resampvar'  if `resampvar'==`value' & `touse'
			if r(N)==0 {
				di as err "you specified to hold observations with `resampvar'==`value' fixed, but it seems there are no such observations"
			}
			else {
				qui replace  `fixedvalues_indicator' = `ccc++' if `resampvar'==`value'
			}
		}
	
	}
	if `"`strata'"' != "" {
		if `:list resampvar in strata' {
			di as err "permutation variable may not be specified in strata() option"
			exit 198
		}
		//I replace strata by single varialbe to simply computation and 
		tempvar strata_
		egen `strata_' = group(`strata' `fixedvalues_indicator'), missing
		if `"`fixlevels'"' != "" {
				local strata_orignal_varnames `"`strata_orignal_varnames' (created separate strata for `resampvar'-values: `fixlevels')"'
		}
		local strata  `strata_'
		
		tempvar sflag 
		markout `touse' `strata', strok
		sort `touse' `strata', stable
		by `touse' `strata': gen `sflag' = _n==1 if `touse'
		qui replace `sflag' = sum(`sflag')
		local nstrata = `sflag'[_N]
		local ustrata `strata'
		local strata `sflag'
		sort `strata' , stable
		
		qui loneway `resampvar' `strata'  if `touse'
		if (r(sd_w) == 0){
			di as err "Warning: some strata contain no variation in `resampvar'"
			if `"`fixlevels'"' != "" {
				di as err "You specified fixlevels(`fixlevels'). This may be responsible for this warning and is not necessarily a problem."
			}
		}
	}
	if `"`cluster'"' != "" {
		if `:list resampvar in strata' {
			di as err "permutation variable may not be specified in strata() option"
			exit 198
		}
		tempvar cflag 

		markout `touse' `strata' `cluster'  , strok

		sort  `touse' `strata' `cluster' , stable
		by `touse' `strata' `cluster': gen `cflag' = _n==1 if `touse'
		qui replace `cflag' = sum(`cflag')
		local N_clust = `cflag'[_N]
		local clustvar `cluster'
		local cluster `cflag'
		sort  `strata' `cluster', stable
		
		qui loneway `resampvar' `cflag'  if `touse'
		if (r(sd_w) != 0 & !missing(r(sd_w))) {
			di as err "`resampvar' does not seem to be constant within clusters"
			exit 9999
		}

	}
    
	
	local obs = _N
	local method 0
	if "`samplingsourcefile'"!="" | "`samplingmatchvar'"!="" {
            local method extfile
	}
	else if "`samplingprogram'"!="" {
            local method program
			cap program list `samplingprogram'
			if _rc!=0 {
				di as err "proceedure -`samplingprogram'- does not exists"
				exit 198
			}
	}
	else {
            local method permute
    }

	if `eps' < 0 {
		di as err "eps() must be greater than or equal to zero"
		exit 198
	}
	if "`strict'"!="" {
		if `eps' > 0 {
			di as err "Warning: if the strict option is specified, eps must be set to 0 using -eps(0)"
			exit 198
		} 
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
	qui postfile `postnam' `names' using `"`saving'"', ///
		`double' `every' replace
	post `postnam' `stats'

	
	
	//methods such as "external file" or "automatic permuations" are wrapped in the third one
	if "`method'"=="permute" {
		local samplingprogram permute_simple
		local samplingprogramoptions "strata(`strata')     cluster(`cluster')"
    }
	else if "`method'"=="extfile" {
		local samplingprogram permute_extfile
		local samplingprogramoptions `"file(`"`samplingsourcefile'"')      matchvars(`samplingmatchvar')"'
    }
	
	if "`dots'" == "*" {
		local noiqui noisily quietly
	}

	// do permutations
	if "`nodots'" == "" | "`noisily'" != "" {
		di
		`dots' 0, title(Resampling replications) reps(`reps') `nodots'
	}
	local rejected 0
	forvalues i = 1/`reps' {
		
		if "`origseed'" != "" & "`reseed'" != "" {
			local currseed = `origseed'+`i'
			`version' set seed `currseed'
		}

		cap `samplingprogram', run(`i') resampvar(`resampvar') `samplingprogramoptions'
		if _rc!=0 {
			di as err "Failed while calling resampling proceedure. Call was: " _n "{stata `samplingprogram', run(`i') resampvar(`resampvar') `samplingprogramoptions'}" _n as text "Error was: " 
			error _rc
		}	
     	if "`saveresampling'"!="" {
			qui save `"`preservetemp'"',replace
			rename `resampvar' `resampvar'`i'
			cap qui merge 1:1 `originalorder' using `"`resamplingtemp'"', nogen
			rename `originalorder' keep`originalorder'
			drop __*
			rename keep`originalorder' `originalorder'
			cap order `resampvar'* , last
			qui save `"`resamplingtemp'"', replace
			use `"`preservetemp'"', clear
		}
		
		// analyze permuted data
		`noi' di as inp `". `command'"'
		capture `noiqui' `noisily' `command'
		if (c(rc) == 1) error 1
		local bad = c(rc) != 0
		if c(rc) {
			`noi' di in smcl as error `"{p 0 0 2}an error occurred when I executed `cmdname', "' ///
                                                  `"posting missing values{p_end}"'
			post `postnam' `mis'
		}
		else {
		
			if `"`reject'"' != "" {
				capture local rejected = `reject'
				if c(rc) {
					local rejected 1
				}
			}
			if `rejected' {
				local bad 1
				`noi' di as error ///
`"{p 0 0 2}rejected results from `cmdname', "' ///
`"posting missing values{p_end}"'
				post `postnam' `mis'
			}
			else {
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
			}
		}
		if "`lessdots'"=="" {
			`dots' `i' `bad'
		} 
		else if mod(`i',10)==0 {
			if mod(`i',500)==0 {
				`dots' `i' `bad'
			}
			else {
				`dots' 4 `bad'
			}
		}
	}
	`dots' `reps'

	// cleanup post
	postclose `postnam'
	if `"`saveresampling'"'!="" {
		cp "`resamplingtemp'" `"`sr_filename'.dta"', `sr_replace'
		
	}

	// load file `saving' with permutation results and display output
	capture use `"`saving'"', clear
	if c(rc) {
		if c(rc) >= 900 & c(rc) <= 903 {
			di as err "insufficient memory to load file with permutation results"
		}
		error c(rc)
	}
	if ("`collapse'" != "") {
		di as err "collapsing"
		gen uh=0
		collapse uh,by(_*)
		drop uh
	}	
	
	label data `"ritest `resampvar' : `cmdname'"'
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
			local realization=r(mean)
			local kopt=subinstr(`"`kdensityoptions'"',"{realization}","`realization'",.)
			kdensity `var' in 2/-1, xline(`realization') name(`var', replace)  graphregion(color(white)) `kopt'
		}
	}

		
	char _dta[k_eq] `k_eq'
	char _dta[k_eexp] `k_eexp'
	char _dta[k_exp] `k_exp'
	char _dta[N_strata] `nstrata'
	char _dta[N_clust] `N_clust'
	char _dta[seed] "`origseed'"
	char _dta[strata] `ustrata'
	char _dta[strata_orignal_varnames] `"`strata_orignal_varnames'"'
	char _dta[clustvar] `clustvar'
	char _dta[N] `obs'
	char _dta[resampvar] "`resampvar'"
	char _dta[command] "`command'"
	char _dta[sampling_method] "`method'"
	
	quietly drop in 1

	if `"`filetmp'"' == "" {
		quietly save `"`saving'"', replace
	}

	ClearE
	qui est restore `originalestimates'
	rit_Results, `ropts' 
	return add
	return scalar N_reps = `reps'
end
program permute_simple
    syntax , strata(varname) cluster(varname) resampvar(varname) *
    //
    cap xtset
    if (_rc == 0) {
	local xt1 = r(panelvar)
	local xt2 = r(timevar)
    }
    tempvar ind nn newt rorder
	//create a random variable
    gen `rorder'=runiform()
    qui {
		//mark first obs in each cluster, for those i will perform the permutations
		sort `strata' `cluster', stable
		by `strata' `cluster': gen `ind' = 1 if _n==1
		
		//across all first observations within clusters, save their position in the data set
		sort `strata' `ind', stable
		by `strata' `ind': gen `nn'=_n if `ind'!=.
		
		//now, reshuffle these first observations within strata, take the treatment status from the observation which was at this position before
		sort `strata' `ind' `rorder', stable
		by `strata' `ind': gen `newt'=`resampvar'[`nn']

		//place the first observations on top of each cluster
		//copy the treatment status to all observations in the same cluster
		sort `strata' `cluster' `ind', stable
		by `strata' `cluster': replace `newt'=`newt'[_n-1] if missing(`newt')

		//clean up
		drop `resampvar'  `nn' `ind' `rorder'
		rename `newt' `resampvar' 
    }
    cap xtset `xt1' `xt2'
end
program permute_extfile
    syntax ,file(string) matchvars(varlist) run(integer) resampvar(varlist)
    sort `matchvars', stable
    cap isid `matchvars'
    if c(rc) {
        capture qui merge m:1 `matchvars' using `"`file'"', keepusing(`resampvar'`run') nogen 
        if c(rc) {
            di as err "`resampvar'`run' does not exist in the permutation data set"
        }
    }
    else {
        capture qui merge 1:1 `matchvars' using `"`file'"', keepusing(`resampvar'`run') nogen 
        if c(rc) {
            di as err "`resampvar'`run' does not exist in the permutation data set"
        }
    }
    drop `resampvar'
    rename `resampvar'`run' `resampvar'
end
program rit_Results  //output the results in a nice table
	syntax [anything(name=namelist)]	///
		[using/] [,			///
			eps(real 1e-7)		/// -GetResults- options
			left			///
			right			///
			strict			///
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
		`left' `right'	`strict' ///
		level(`level')	///
		`title'
		
	rit_DisplayResults, `header' `table' `legend' `verbose' `diopts'
end


program rit_GetResults, rclass
	syntax varlist [,		///
		Level(cilevel)		///
		eps(real 1e-7)		/// -GetResults- options
		left			///
		right			///
		strict			///
		TItle(string asis)	///
	]

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
	// number of cluster
	local N_clust : char _dta[N_clust]
	if "`N_clust'" != "" {
		capture confirm integer number `N_clust'
		if c(rc) {
			local N_clust
		}
	}
	// strata variable
	if "`nstrata'" != "" {
		local strata_orignal_varnames : char _dta[strata_orignal_varnames]
		local strata : char _dta[strata]
		if "`strata'" != "" {
			capture confirm names `strata'
			if c(rc) {
				local strata
			}
		}
	}
	// cluster variable
	if "`N_clust'" != "" {
		local clustvar : char _dta[clustvar]
		if "`clustvar'" != "" {
			capture confirm names `clustvar'
			if c(rc) {
				local clustvar
			}
		}
	}
	// permutation method
	local sampling_method : char _dta[sampling_method]
	// permutation variable
	local resampvar : char _dta[resampvar]
	capture confirm name `resampvar'
	if c(rc) | `:word count `resampvar'' != 1 {
		local resampvar
	}
	if `"`resampvar'"' == "" {
		di as error ///
"permutation variable name not present as data characteristic"
		exit 9
	}

	// requested event
	rit_GetEvent, `left' `right' `strict' eps(`eps')
	local event `s(event)'
	local rel `s(rel)'
	local abs `s(abs)'
	local minus `"`s(minus)'"'
	
	
	
	
	tempvar diff //geqdiff
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
		tempvar ties
		gen `ties' = (`abs'(`name') == `abs'(`value')  )
		qui sum `ties', meanonly
		if `r(mean)'>0.01 {
			noi noi di as err "Warning: `=round(100*r(mean))'% of the resampled realizations for `name' are exactly identical to original value"
			
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
		local exp`j' : char `name'[expression]
		if `"`:char `name'[is_eexp]'"' == "1" {
			local ++k_eexp	
		}
	}
	local coleq : list clean coleq

	// command executed for each permutation
	local command : char _dta[command]
	local k_exp = `K' - `k_eexp'

	
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
	return local resampvar `resampvar'
	if "`nstrata'" != "" {
		return scalar N_strata = `nstrata'
		if "`strata_orignal_varnames'" != "" {
			return local strata_orignal_varnames `"`strata_orignal_varnames'"'
		}
		if "`strata'" != "" {
			return local strata `strata'
		}
	}

	if "`N_clust'" != "" {
		return scalar N_clust = `N_clust'
		if "`clustvar'" != "" {
			return local clustvar `clustvar'
		}
	}
	return local event `event'
	return local left `left'
	return local right `right'
	return local strict `strict'
	forval i = 1/`K' {
		return local exp`i' `"`exp`i''"'
	}
	if `"`title'"' != "" {
		return local title `"`title'"'
	}
	else	return local title "Monte Carlo results"
	return local command `"`command'"'
	return local sampling_method `"`sampling_method'"'
	return local cmd ritest
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
		//this is supposed to produce a nice header, but doesn't because _coef_table_header doesn't no ritest, so I do it manuallly
		//_coef_table_header, rclass
		
		_prefix_legend ritest, rclass `verbose'
		di as txt %`s(col1)'s "res. var(s)" ":  `r(resampvar)'"
		
		if "`r(sampling_method)'"=="extfile" {
			di as txt %`s(col1)'s "Resampling" as text ":  Using an external file"
		}
		else if "`r(sampling_method)'"=="program" {
			di as txt %`s(col1)'s "Resampling" as text ":  Using a user-specified program"
		}
		else if "`r(sampling_method)'"=="permute" {
			di as txt %`s(col1)'s "Resampling" as text ":  Permuting `r(resampvar)'"
			if !missing(r(N_clust)) & "`r(clustvar)'" != "" {
				di as txt %`s(col1)'s "Clust. var(s)" as res ":  `r(clustvar)'"
				di as txt %`s(col1)'s "Clusters" as res ":  `r(N_clust)'"
			}
			if !missing(r(N_strata)) & "`r(strata_orignal_varnames)'" != "" {
				di as txt %`s(col1)'s "Strata var(s)" as res ":  `r(strata_orignal_varnames)'"
				di as txt %`s(col1)'s "Strata" as res ":  `r(N_strata)'"
			}
		}
		else {
			di as txt %`s(col1)'s "Resampling" as text ":  `sampling_method'"
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
	syntax [, left right strict eps(string)]
	if "`left'"!="" & "`right'"!="" {
		di as err "only one of left or right can be specified"
		exit 198
	}
	local unstrict
	if "`strict'"=="" {
			local unstrict="="
	}
	if "`left'"!="" {
		sreturn local event "T <`unstrict' T(obs)"
		sreturn local rel "<`unstrict'"
		sreturn local minus "+"
	}
	else if "`right'"!="" {
		sreturn local event "T >`unstrict' T(obs)"
		sreturn local rel ">`unstrict'"
		sreturn local minus "-"
	}
	else {
		sreturn local event "|T| >`unstrict' |T(obs)|"
		sreturn local rel ">`unstrict'"
		sreturn local abs "abs"
		sreturn local minus "-"
	}
end


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
