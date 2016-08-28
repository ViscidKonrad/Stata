*! version 0.3	20apr2016	David Rosnick
program define idCodes, rclass

	syntax varname [, ISO OECD PWT TED WEO WDI Numeric ALPHA2 ALPHA3 Countryname]
	
	tempfile sources types codes
	
	preserve
	local codeSources = trim(`"`iso' `oecd' `pwt' `ted' `wdi' `weo'"')
	local codeSources : list retokenize codeSources
	local nSources : list sizeof codeSources
	if (`nSources'==0) {
		local codeSources "iso oecd pwt ted wdi weo"
	}
	tokenize `codeSources'
	local nSources : list sizeof codeSources
	local firstSource `1'
	foreach s of local codeSources {
		clear
		if ("`s'"=="iso") {
			local codeTypesTmp "numeric alpha2 alpha3 countryname"
		}
		if ("`s'"=="oecd") {
			local codeTypesTmp "alpha3 countryname"
		}
		if ("`s'"=="pwt") {
			local codeTypesTmp "aloha3 countryname"
		}
		if ("`s'"=="ted") {
			local codeTypesTmp "alpha3 countryname"
		}
		if ("`s'"=="wdi") {
			local codeTypesTmp "alpha2 alpha3 countryname"
		}
		if ("`s'"=="weo") {
			local codeTypesTmp "numeric alpha3 countryname"
		}
		local nTypes : list sizeof codeTypesTmp
		set obs `nTypes'
		gen codeSources = "`s'"
		gen codeTypes = ""
		tokenize `codeTypesTmp'
		forvalues t=1/`nTypes' {
			replace codeTypes = "``t''" in `t'
		}
		if ("`s'"~="`firstSource'") {
			append using `sources'
		}
		save `sources', replace
	}
	local codeTypes = trim(`"`numeric' `alpha2' `alpha3' `countryname'"')
	local codeTyples : list retokenize codeTypes
	local nTypes : list sizeof codeTypes
	if (`nTypes'==0) {
		local codeTypes "numeric alpha2 alpha3 countryname"
	}
	tokenize `codeTypes'
	local firstType `1'
	foreach s of local codeTypes {
		clear
		if ("`s'"=="numeric") {
			local codeSourcesTmp "iso ted weo"
		}
		if ("`s'"=="alpha2") {
			local codeSourcesTmp "iso wdi"
		}
		if ("`s'"=="alpha3") {
			local codeSourcesTmp "iso oecd pwt wdi weo"
		}
		if ("`s'"=="countryname") {
			local codeSourcesTmp "iso oecd pwt ted wdi weo"
		}
		local nSources : list sizeof codeSourcesTmp
		set obs `nSources'
		gen codeSources = ""
		gen codeTypes = "`s'"
		tokenize `codeSourcesTmp'
		forvalues t=1/`nSources' {
			replace codeSources = "``t''" in `t'
		}
		if ("`s'"~="`firstType'") {
			append using `types'
		}
		save `types', replace
	}
	merge m:m codeSource codeType using `sources', keep(match) nogen
	if (`=_N'==0) {
		di as error "No" as result "`codeTypes'" as error " country identifier in" as result "`codeSources'"
	}
	else {
		gen codeVar = cond(codeS=="iso","ISO",cond(codeS=="oecd","OECD",cond(codeS=="pwt","PWT", ///
cond(codeS=="ted","TED",cond(codeS=="wdi","WDI","WEO"))))) ///
			+ cond(codeT=="numeric","Numeric",cond(codeT=="alpha2","Alpha2",cond(codeT=="alpha3","Alpha3","CountryName")))
		save `types', replace
		qui levelsof codeVar, local(codeVars) clean
		*
		*	Auto-detection of country code source and type
		*
		*	Start by checking to see if variable name is canonical
		*
		local varMatch : list posof "`varlist'" in codeVars
		if (`varMatch'~=0) {
			*	Variable is canonical and matches options constraints
			qui levelsof codeSource if codeVar=="`varlist'", local(cS)
			qui levelsof codeType if codeVar=="`varlist'", local(cT)
			return local codeVar = "`varlist'"
			return local codeType = `cT'
			return local codeSource = `cS'
		}
		else {
			*	No canonical matches.  Try to guess based on characteristics of variable
			restore, preserve
			compress
			*	Distinguish between alpha and numeric codes (note that numeric codes may be string or int)
			ds `varlist', has(type numeric)
			local rvlist `r(varlist)'
			count if ~mi(`varlist') & ~regexm(`varlist',"^[0-9][0-9][0-9]$")
			if (`r(N)'==0 | "`rvlist'"=="`varlist'") {
				*	is numeric
				if ("`rvlist'"=="") {
					*	Destring variable if necessary
					tempvar dsvar
					destring `varlist', gen(`dsvar')
				}
				else {
					local dsvar `varlist'
				}
				sum `dsvar', meanonly
				if (`r(min)'<100) {
					local varps = "ISONumeric TEDNumeric"
				}
				else {
					local varps = "ISONumeric TEDNumeric WEONumeric"
				}
			}
			else {
				*	is alpha
				ds `varlist', has(type 2)
				if ("`r(varlist)'"=="`varlist'") {
					local varps = "ISOAlpha2 WDIAlpha2"
				}
				else {
					ds `varlist', has(type 3)
					if ("`r(varlist)'"=="`varlist'") {
						local varps = "ISOAlpha3 OECDAlpha3 PWTAlpha3 WDIAlpha3 WEOAlpha3"
					}
					else {
						local varps = "ISOCountryName OECDCountryName PWTCountryName TEDCountryName WDICountryName WEOCountryName"
					}
				}
			}
			local codeVars : list codeVars & varps
			local ncv : list sizeof codeVars
			if (`ncv'==0) {
				di as error "Unable to determine variable type.  Try loosening constraints"
			}
			else if (`ncv'==1) {
				return local codeVar = "`codeVars'"
			}
			else {
				di as error "Unable to determine variable type.  Likely one of: " as result "`varps'"
				return local codeVars = "`varps'"
			}
		}
	}
	
end
