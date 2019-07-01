*! version 2.0	01jul2019	David Rosnick
program define idCodes, rclass

	syntax varname [if] [in] [, GCB PWT TED UNSD WDI WEO CODE NAME NUM]

	marksample touse, novarlist

	qui {
		preserve
		keep if `touse'
		sample 1, count by(`varlist')
		tempfile tf
		save `tf'
		
		count
		local nmu = `r(N)'+1
		local matchlist
		
		local numsources UNSD WEO
		local codesources PWT TED WDI WEO
		local namesources GCB GCB2 PWT TED UNSD WDI WEO
		local typelist int str3 str

		*	List of eligible data sources
		local usources `gcb' `pwt' `ted' `unsd' `wdi' `weo'
		if ("`usources'"=="") {
			local usources `namesources'
		}
		else {
			local usources `=upper("`usources'")'
			if ("`gcb'"~="") {
				local usources `usources' GCB2
			}
		}
		if ("`usources'"=="") {
			di as error "No data sources available. Please respecify " as result "GCB PWT TED UNSD WDI WEO"
		}
		else {
			noi macro li _usources
		}

		*	Lists of data sources by eligible type
		if ("`code'`name'`num'"=="") {
			local code code
			local name name
			local num num
		}
		foreach s in code name num {
			if ("``s''"=="") {
				local `s'sources
			}
			else {
				local `s'sources: list `s'sources & usources
			}
			noi di "`s': ``s'sources'"
		}

		local nc 1
	}
	*	Iterate over the possible types of variables
	qui foreach ty in num code name {
		local tc: word `nc' of `typelist'
		capture: confirm `tc' var `varlist'
		if (_rc==0) {
			*	See if the variable name matches
			foreach db of local `ty'sources {
				if ("`varlist'"=="`ty'_`db'") {
					local matchlist `varlist'
					local nmu = -1
				}
			}
			if ("`matchlist'"=="") {
				if ("``ty'sources'"~="") {
					*	If not, see which match most
					foreach db of local `ty'sources {
						use CountryCodes, clear
						ren `ty'_`db' `varlist'
						drop if mi(`varlist')
						merge 1:1 `varlist' using `tf'
						count if _merge==2
						local rn = `r(N)'
						if (`rn'<=`nmu') {
							if (`rn'==`nmu') {
								local matchlist `matchlist' `ty'_`db'
							}
							if (`rn'<`nmu') {
								local matchlist `ty'_`db'
								local nmu = `rn'
							}
						}
					}
				}
			}
			continue, break
		}
		local ++nc
	}

	local matchlen: list sizeof matchlist
	if (`matchlen'~=1) {
		if (`matchlen'==0) {
			di as error "No sources available. Please specify more sources"
		}
		else {
			di as error "Multiple best matches available: " as result "`matchlist'." ///
				as error " Please (further) restrict sources"
			return local codeVars = "`matchlist'"
		}
	}
	else {
		if (`nmu'>0) {
			di as text "No variable matches all observations. Closest to " as result "`matchlist'"
		}
		else {
			if (`nmu'<0) {
				di as text "Variable name matched"
			}
			else {
				di as text "All observations match " as result "`matchlist'"
				return local var = "`varlist'"
			}
		}
		return local codeVar = "`matchlist'"
		return local N_missed = "`=max(0,`nmu')'"
	}

end