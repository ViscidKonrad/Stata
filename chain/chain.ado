*! version 0.1	14may2014	David Rosnick
program define chain

	syntax varlist, Base(string asis) Generate(namelist) [PQ(varlist numeric) P(varlist numeric) Q(varlist numeric) FISHER LASPEYRES PAASCHE]
	
	local nopts 0
	local cuse
	if ("`fisher'"=="fisher") {
		local ++nopts
		local cuse Fisher
	}
	if ("`laspeyres'"=="laspeyres") {
	    if (`nopts'==0) {
			local cuse Laspeyres
		}
		local ++nopts
	}
	if ("`paasche'"=="paasche") {
	    if (`nopts'==0) {
			local cuse Paasche
		}
		local ++nopts
	}
	if (`nopts'>1) {
		di as error "Only one of fisher, laspeyres, or paasche may be selected.  `cuse' assumed"
	}
	if (`nopts'==0) {
		local fisher fisher
	}
	
	*
	*	varlist contains nominal expenditures for the aggregate(s)
	*
		
	local nvars 0
	foreach pre in p q pq {
		local `pre'vars
		if ("``pre''"~="") {
			local `pre'num 0
			foreach var of local `pre' {
				local ++`pre'num
				tempvar `pre'``pre'num'
				local `pre'vars ``pre'vars' ``pre'``pre'num''
				gen ``pre'``pre'num'' = `var'
			}
			if (`nvars') {
				if (``pre'num'~=`nvars') {
					di as error "Variable count mismatch"
				}
			}
			else {
				local nvars ``pre'num'
			}
		}
	}
	foreach pre in p q pq {
		if ("``pre''"=="") {
			forvalues nn=1/`nvars' {
				tempvar `pre'`nn'
				local `pre'vars ``pre'vars' ``pre'`nn''
				if ("`pre'"=="pq") {
					gen ``pre'`nn'' = `p`nn''*`q`nn''
				}
				else if ("`pre'"=="p") {
					gen ``pre'`nn'' = `pq`nn''/`q`nn''
				}
				else if ("`pre'"=="q") {
					gen ``pre'`nn'' = `pq`nn''/`p`nn''
				}
			}	
		}
	}

	macro li _pvars _qvars _pqvars

	forvalues nn=1/`nvars' {
		tempvar pmqm`nn' pqm`nn' pmq`nn'
		gen `pmqm`nn'' = L.`pq`nn''
		gen `pmq`nn'' = `pq`nn''*(L.`p`nn''/`p`nn'')
		gen `pqm`nn'' = `pmqm`nn''*(`p`nn''/L.`p`nn'')
	}
	
	tempvar isbase
	markBase `isbase', base(`base')

	tsset
	ret li
	local gvar = "`r(panelvar)'"
	tokenize `generate'
	macro li _gvar _generate
	local vnum 0
	foreach var of local varlist {
		local ++vnum
		tempvar mvar`vnum' bvar`vnum'
		foreach pf in PQ PmQm PmQ PQm {
			tempvar `pf'`vnum'
			gen ``pf'`vnum'' = 0
		}
		reg `var' `pqvars', noc
		mat eb = e(b)
		forvalues nn=1/`nvars' {
			local c = round(eb[1,`nn'],1)
			foreach pf in PQ PmQm PmQ PQm {
				local pfl = lower("`pf'")
				replace ``pf'`vnum'' = ``pf'`vnum'' + `c'*``pfl'`nn''
			}
		}
		gen `1' = 1 if ~mi(`PQ`vnum'')
		if ("`fisher'"=="fisher") {
			replace `1' = L.`1'*sqrt((`PmQ`vnum''/`PmQm`vnum'')*(`PQ`vnum''/`PQm`vnum'')) if ~mi(L.`1')
		}
		if ("`laspeyres'"=="laspeyres") {
			replace `1' = L.`1'*(`PmQ`vnum''/`PmQm`vnum'') if ~mi(L.`1')
		}
		if ("`paasche'"=="paasche") {
			replace `1' = L.`1'*(`PQ`vnum''/`PQm`vnum'') if ~mi(L.`1')
		}
		if ("`gvar'"=="") {
			egen `mvar`vnum'' = mean(cond(`isbase',`1',.))
			egen `bvar`vnum'' = mean(cond(`isbase',`var',.))
		}
		else {
			by `gvar': egen `mvar`vnum'' = mean(cond(`isbase',`1',.))
			by `gvar': egen `bvar`vnum'' = mean(cond(`isbase',`var',.))
		}
		replace `1' = `1'*`bvar`vnum''/`mvar`vnum''
		macro shift
	}
	
end

program define markBase

	syntax newvarname, Base(string asis)
	
	if (regexm("`base'","^([0-9]*)$")) {
		local baseunit = "y"
		tsset
		if ("`r(unit1)'"==".") {
			gen `varlist' = `baseunit'ofd(dofy(`r(timevar)'))==`base'
		}
		else {
			gen `varlist' = `baseunit'ofd(dof`r(unit1)'(`r(timevar)'))==`base'
		}
	}
	else if (regexm("`base'","^[0-9]*([mqh])[0-9]*$")) {
		local baseunit = regexs(1)
		tsset
		gen `varlist' = `baseunit'ofd(dof`r(unit1)'(`r(timevar)'))==t`baseunit'(`base')
	}
	else {
		di as error "Base must be m, q, h, or y"
	}
	li if `varlist'

	
end
