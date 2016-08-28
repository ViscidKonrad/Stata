*! version 0.3	09sep2014	David Rosnick
program define addSCFQuantiles, sortpreserve byable(onecall)

	syntax newvarname=/exp, AT(numlist ascending)
	
	qui svyset
	local su `r(su1)'
	local wvar `r(wvar)'
	
	tempvar expvar
	gen `expvar' = `exp'
	sort `_byvars' `expvar' `=substr("`su'",2,.)'

	if (_by()) {
		local prefix by `_byvars':
	}
	else {
		local prefix
	}

	tempvar wsum
	`prefix' gen `wsum' = sum(`wvar')
	`prefix' replace `wsum' = 100*`wsum'/`wsum'[_N]
	egen byte `varlist' = cut(`wsum'), at(0 `at' 1000) ic
	replace `varlist' = `varlist'+1
	local nat: list sizeof at
	lab def `varlist' 1 "<`:word 1 of `at''", replace
	forvalues ii=2/`nat' {
		lab def `varlist' `ii' "`:word `=`ii'-1' of `at''-`:word `ii' of `at''", add
	}
	lab def `varlist' `=`nat'+1' "`:word `nat' of `at''-100", add
	lab val `varlist' `varlist'

end
