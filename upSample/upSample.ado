*!	version 1.1	02mar2016	David Rosnick
program define upSample

	syntax varlist, [LOCAL] [FM(integer -1)] [Order(integer 3)] [Suffix(string asis)]
		
	local nvars : list sizeof varlist
	di 
	di as result `nvars' as text " variable(s) to upsample: " as result "`varlist'"
	di

	local nobs = _N

	setSample, fm(`fm')
	local fm = `r(fm)'
	local order = max(`order',0)
	di
	di as text "Frequency multiplier = " as result `fm'
	if ("`local'"=="local") {
		di as text "Interpolation polynomial order = " as result `order' as text " (using " as result `order'+1 as text " node(s))
	}
	else {
		di as text "Interpolating with " as result "minimum curvature""
	}
	di
	qui tsset
	local timevar = r(timevar)
	if ("`suffix'"=="") {
		local suffix = "_`r(unit1)'"
	}
		
	foreach var of varlist `varlist' {
		di as text "Next variable: " as result "`var'"
		if ("`local'"=="local") {
			doUpSample `var', fm(`fm') order(`order') suffix(`suffix') timevar(`timevar') n(`nobs')
		}
		else {
			doMinCurveUpSample `var', fm(`fm') suffix(`suffix')
		}
	}

end

program define setSample, rclass

	syntax, [FM(integer -1)]

	tsset
	local timevar = r(timevar)
	local unit1 = r(unit1)
	local tmin = r(tmin)
			
	*
	*	Determine upsampled frequency
	*

	local unit2 = "g"
	local unitbase = 0
	if ("`unit1'"=="y") {
		if (`fm'<2) {
			local fm = 4
		}
		if (`fm'==2) {
			local unit2 = "h"
		}
		else if (`fm'==4) {
			local unit2 = "q"
		}
		else if (`fm'==12) {
			local unit2 = "m"
		}
		local unitbase = 1960
	}
	else if ("`unit1'"=="h") {
		if (`fm'<2) {
			local fm = 6
		}
		if (`fm'==2) {
			local unit2 = "q"
		}
		else if (`fm'==6) {
			local unit2 = "m"
		}
		local unitbase
	}
	else if ("`unit1'"=="q") {
		if (`fm'<2) {
			local fm = 3
		}
		if (`fm'==3) {
			local unit2 = "m"
		}
	}
	else {
		if (`fm'<2) {
			local fm = 3
		}
	}
	replace `timevar' = `fm'*(`tmin'-`unitbase'+_n-1)
	tsset `timevar', `unit2'
	local fmm1 = `fm'-1
	tsappend, add(`fmm1')
		
	return local fm = `fm'

end

capture: program drop doMinCurveUpSample
program define doMinCurveUpSample

	syntax varname, FM(integer) Suffix(string asis)
	
	confirm numeric variable `varlist'
	
	confirm new variable `varlist'`suffix'
	gen `varlist'`suffix' = .

	mata: minCurveUpSample("`varlist'`suffix'", "`varlist'", `fm')

end

program define doUpSample

	syntax varname, FM(integer) Order(integer) Suffix(string asis) Timevar(varname) N(integer)
	
	confirm numeric variable `varlist'
	qui sum `timevar' if ~mi(`varlist')
	local pre = round((`r(min)'-`timevar'[1])/`fm')
	
	confirm new variable `varlist'`suffix'
	gen `varlist'`suffix' = .
	
	mata: st_view(Y=., ., "`varlist'", 0)
	mata: nlo = length(Y)
	mata: C = makeCombMatrix(nlo,`fm')
	mata: B = makeInterpMatrix(nlo,`fm',`order',0,nlo)
	mata: CB = C*B
	mata: X = B*lusolve(CB,Y)
	mata: B = makeInterpMatrix(nlo,`fm',`order',`pre',`n')
	mata: X = B*lusolve(CB,Y)
	mata: st_store(., "`varlist'`suffix'", ., X)

end
