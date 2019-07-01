*! version 2.0 01jul2019	David Rosnick
program define buildCodes

	syntax anything(name=filename) [, REPLACE CLEAR]

	capture: confirm file `filename'.dta
	if (_rc~=0 | "`replace'"=="replace") {

	tempfile df cf
	
	*	Start with UNSD codes
	getUNData, clear
	d
	sample 1, count by(CountryID)
	keep Country*
	ren CountryID num_UNSD
	ren Country name_UNSD
	lab var num_UNSD "UNSD numeric country code"
	lab var name_UNSD "UNSD country name"
	*	set match variable
	gen MatchName = name_UNSD
	*	Not correct, but useful anyway
	replace MatchName = "Czech Republic" if regexm(MatchName,"Czechia")
	save `cf'
	
	*	Add WB-WDI codes
	getWDIData, clear
	d
	sample 1, count by(countrycode)
	keep country*
	ren countrycode code_WDI
	ren countryname name_WDI
	lab var code_WDI "World Bank WDI country code"
	lab var name_WDI "World Bank WDI country name"
	*	set match variable
	gen tempName = name_WDI
	*	Corrections
	replace tempName = "State of Palestine" if regexm(tempName,"West Bank")
	save `df'
	*	Match to other names
	fuzzyMatch tempName MatchName using `cf', sim t(0.1)
	*	False positives
	drop if regexm(MatchName,"Cook Islands") | regexm(MatchName,"Zanzibar")
	*	Merge with other names
	merge 1:1 tempName using `df', nogen
	replace MatchName = tempName if mi(MatchName)
	drop tempName
	merge 1:1 MatchName using `cf'
	*	Checks
	gsort -sim
	li MatchName name_WDI sim if _merge==3 & sim<1
	li MatchName name_WDI if _merge==1
	li MatchName if _merge==2
	drop sim _merge
	*	Incorrect, but useful
	replace MatchName = "Swaziland" if regexm(MatchName,"Eswatini")
	save `cf', replace	

	*	Add GCB codes
	getGCBData, clear
	d
	sample 1, count by(name_GCB)
	lab var name_GCB "Global Carbon Budget country name"
	lab var name_GCB2 "Global Carbon Budget country name"
	*	set match variable
	gen tempName = name_GCB2
	*	Corrections
	replace tempName = "United States" if tempName=="USA"
	replace tempName = "Macedonia" if regexm(tempName,"Macedonia")
	replace tempName = "DR Congo" if regexm(tempName,"Democratic Repu")
	save `df', replace
	*	Match to other names
	fuzzyMatch tempName MatchName using `cf', sim t(0.3)
	*	False positives
	drop if regexm(MatchName,"Cayman")
	*	Merge with other names
	merge 1:1 tempName using `df', nogen
	replace MatchName = tempName if mi(MatchName)
	drop tempName
	merge 1:1 MatchName using `cf'
	*	Checks
	gsort -sim
	li MatchName name_GCB2 sim if _merge==3 & sim<1
	li MatchName name_GCB2 if _merge==1
	li MatchName if _merge==2
	drop sim _merge
	save `cf', replace	

	*	Add TED codes
	getTEDData, clear
	d
	sample 1, count by(ISO)
	keep ISO COU
	ren ISO code_TED
	ren COU name_TED
	lab var code_TED "Conference Board TED country code"
	lab var name_TED "Conference Board TED country name"
	*	set match variable
	gen tempName = name_TED
	*	Corrections
	replace tempName = "D.R. of the Congo" if regexm(tempName,"DR Congo")
	replace tempName = "Syran Arab Rep" if regexm(tempName,"Syria")
	replace tempName = "Republic of Korea" if regexm(tempName,"South Korea")
	replace tempName = "Iran Islamic Rep" if regexm(tempName,"Iran")
	replace tempName = "Bolivia Plurinational" if regexm(tempName,"Bolivia")
	replace tempName = "Kyrgyzstan" if regexm(tempName,"Kyrg")
	save `df', replace
	*	Match to other names
	fuzzyMatch tempName MatchName using `cf', sim // t(0.3)
	*	False positives
	drop if regexm(MatchName,"Montenegro")
	*	Merge with other names
	merge 1:1 tempName using `df', nogen
	replace MatchName = tempName if mi(MatchName)
	drop tempName
	merge 1:1 MatchName using `cf'
	*	Checks
	gsort -sim
	li MatchName name_TED sim if _merge==3 & sim<1
	sort MatchName
	li MatchName name_TED if _merge==1
	li MatchName if _merge==2
	drop sim _merge
	save `cf', replace	
	
	*	Add WEO codes
	getWEOData, clear
	d
	sample 1, count by(ISO)
	keep WEOC-Cou
	ren WEOC num_WEO
	ren ISO code_WEO
	ren Cou name_WEO
	lab var num_WEO "I.M.F. WEO numeric country code"
	lab var code_WEO "I.M.F. WEO country code"
	lab var name_WEO "I.M.F. WEO country name"
	destring num_WEO, force replace
	*	set match variable
	gen tempName = name_WEO
	*	Corrections
	replace tempName = "Republic of Korea" if regexm(tempName,"Korea")
	replace tempName = "Republic of Moldova" if regexm(tempName,"Moldova")
	replace tempName = "Syrian Arab Republic" if regexm(tempName,"Syria")
	replace tempName = "Swaziland" if regexm(tempName,"Eswatini")
	save `df', replace
	*	Match to other names
	fuzzyMatch tempName MatchName using `cf', sim // t(0.3)
	*	False positives
	*	Merge with other names
	merge 1:1 tempName using `df', nogen
	replace MatchName = tempName if mi(MatchName)
	drop tempName
	merge 1:1 MatchName using `cf'
	*	Checks
	gsort -sim
	li MatchName name_WEO sim if _merge==3 & sim<1
	sort MatchName
	li MatchName name_WEO if _merge==1
	li MatchName if _merge==2
	drop sim _merge
	save `cf', replace	
	
	*	Add PWT codes
	getPWTData, clear
	d
	sample 1, count by(countrycode)
	keep country*
	ren countrycode code_PWT
	ren country name_PWT
	lab var code_PWT "GGDC PWT country code"
	lab var name_PWT "GGDC PWT country name"
	*	set match variable
	gen tempName = name_PWT
	*	Corrections
	replace tempName = "Swaziland" if regexm(tempName,"Eswatini")
	save `df', replace
	*	Match to other names
	fuzzyMatch tempName MatchName using `cf', sim // t(0.3)
	*	False positives
	*	Merge with other names
	merge 1:1 tempName using `df', nogen
	replace MatchName = tempName if mi(MatchName)
	drop tempName
	merge 1:1 MatchName using `cf'
	*	Checks
	gsort -sim
	li MatchName name_PWT sim if _merge==3 & sim<1
	sort MatchName
	li MatchName name_PWT if _merge==1
	li MatchName if _merge==2
	drop sim _merge
	save `cf', replace	

	order *, alpha
	sort MatchName
	drop MatchName
	compress
	save `filename', replace
	export excel using `filename', replace firstrow(var)
	}
	else {
		use CodeData/Clean/PWT, `clear'
	}

end

program define fuzzyMatch

	* This program does a fuzzy match of string variables
	*	- it is mostly a wrapper for an iterated —matchit—, putting aside
	*		mutual best matches in each iteration
	*	namelist is <master data varname> [<using data varname>]
	*	threshold is the similarity cutoff-- any below this will be dropped
	*	sim keeps the similarity value

	syntax namelist(min=1 max=2) using/ [,Threshold(real 0) SIM]
	
	tokenize `namelist'
	if (`"`2'"'=="") {
		*	Assume same variable name if missing
		local 2 `1'
	}
	macro li _1 _2
	macro li _using
	tempvar sim1 sim2 ismatch
	tempfile tf
	*	Generate lists of unique values of each variable
	forvalues ii=1/2 {
		tempvar id`ii'
		tempfile tf`ii'
		if (`ii'>1) {
			use `using', clear
		}
		sample 1, count by(``ii'')
		keep ``ii''
		sort ``ii''
		gen `id`ii'' = _n
		compress
		save `tf`ii''
	}
	*	Use —matchit— to generate similarity scores
	matchit `id2' `2' using `tf1', idu(`id1') txtu(`1') override t(`threshold')
	local iter 0
	count
	while (r(N) & `iter'<2000) {
		bys `2': egen `sim2' = max(sim)
		bys `1': egen `sim1' = max(sim)
		* identify mutual best matches
		gen `ismatch' = `sim2'==sim & `sim1'==sim
		drop `sim2' `sim1'
		preserve
		* add mutual best matches to tempfile
		keep if `ismatch'
		drop `ismatch'
		if ("`replace'"=="replace") {
			append using `tf'
		}
		save `tf', `replace'
		restore
		* drop matched countries from active data
		bys `2': egen `sim2' = total(`ismatch')
		bys `1': egen `sim1' = total(`ismatch')
		drop if `sim2' | `sim1'
		drop `sim2' `sim1' `ismatch'
		local replace replace
		local ++iter
		count
	}
	use `tf', clear
	gsort -sim `1' `2'
	*	only keep similarity score if requested
	if ("`sim'"=="") {
		drop sim
	}
	
end

program define getREST

	syntax [, REPLACE FETCH]

	if ("`fetch'"=="fetch") {
		local replace replace
	}
	
	capture: confirm file CodeData/Clean/REST.dta
	if (_rc~=0 | "`replace'"=="replace") {
		capture: mkdir CodeData
		capture: mkdir CodeData/Clean
		capture: confirm file CodeData/Raw/REST.xml
		if (_rc~=0 | "`fetch'"=="fetch") {
			capture: mkdir CodeData/Raw
			local URL http://data.un.org/ws/rest/codelist
			copy `"`URL'"' CodeData/Raw/REST.xml, replace
		}
		clear
		tempfile tf
		gen merge_code = "_placeholder_"
		save `tf'
		import delimited CodeData/Raw/REST.xml, clear enc("utf-8") delim("|||", asstring)
		gen agency = regexs(1) if regexm(v1,`"agencyID=\"([^"]+)\""')
		gen id = regexs(1) if regexm(v1,`"<Codelist id=\"([^"]+)\""')
		replace agency = agency[_n-1] if mi(agency)
		replace id = id[_n-1] if mi(id)
		gen agency_id = agency+"__"+id
		gen code = regexs(1) if regexm(v1,`"<Code id=\"([^"]+)\""')
		gen name = regexs(1) if ~mi(code) & regexm(v1[_n+1],`"<Name[^>]+>([^<]+)</Name>"')
		levelsof agency_id if regexm(id,"AREA"), clean local(ail)
		keep if ~mi(name)
		drop v1
		foreach ai of local ail {
			/*
			preserve
			keep if agency_id=="`ai'"
			ren code CODE__`ai'
			ren name NAME__`ai'
			keep CODE NAME
			gen merge_code = CODE
			merge 1:1 merge_code using `tf', nogen
			save `tf', replace
			restore
			*/
			tab name if agency_id=="`ai'"
		}
	}
	}
	else {
		use `filename', `clear'
	}
	

end

program define getUNData

	syntax [, REPLACE FETCH CLEAR]

	if ("`fetch'"=="fetch") {
		local replace replace
	}
	
	capture: confirm file CodeData/Clean/UN.dta
	if (_rc~=0 | "`replace'"=="replace") {

		tempfile tf
		capture: mkdir CodeData
		capture: mkdir CodeData/Clean

		*	GNI (countrynames may be out of date)
		capture: confirm file CodeData/Raw/GNI_UN.xls
		if (_rc~=0 | "`fetch'"=="fetch") {
			capture: mkdir CodeData/Raw
			local URL https://unstats.un.org/unsd/amaapi/api/file/23
			copy `"`URL'"' CodeData/Raw/GNI_UN.xls, replace
		}
		import excel using CodeData/Raw/GNI_UN, sheet(Download-GNIcurrent-NCU-countri) ///
			cellrange(a3) firstrow `clear'
		drop Curren
		ren * GNI*
		ren GNICountry* Country*
		local yc 1970
		foreach var of varlist GNI* {
			ren `var' GNI`yc'
			local ++yc
		}
		reshape long GNI, i(CountryID) j(Year)
		compress
		order CountryID Country
		sort CountryID Year
		save `tf'
		
		*	GDP
		capture: confirm file CodeData/Raw/GDP_UN.xls
		if (_rc~=0 | "`fetch'"=="fetch") {
			capture: mkdir CodeData/Raw
			local URL https://unstats.un.org/unsd/amaapi/api/file/1
			copy `"`URL'"' CodeData/Raw/GDP_UN.xls, replace
		}
		import excel using CodeData/Raw/GDP_UN, sheet(Download-GDPcurrent-NCU-countri) ///
			cellrange(a3) firstrow clear
		keep if regexm(Ind,"\(GDP\)")
		drop Curren Ind
		ren * GDP*
		ren GDPCountry* Country*
		local yc 1970
		foreach var of varlist GDP* {
			ren `var' GDP`yc'
			local ++yc
		}
		reshape long GDP, i(CountryID) j(Year)
		compress
		order CountryID Country
		sort CountryID Year
		
		*	merge
		merge 1:1 CountryID Year using `tf', nogen
		drop if regexm(Country,"(Former)")
		save CodeData/Clean/UN, replace

	}
	else {
		use CodeData/Clean/UN, `clear'
	}

end

program define getWDIData

	syntax [, REPLACE FETCH CLEAR]

	if ("`fetch'"=="fetch") {
		local replace replace
	}
	
	capture: confirm file CodeData/Clean/WDI.dta
	if (_rc~=0 | "`replace'"=="replace") {

		capture: mkdir CodeData
		capture: mkdir CodeData/Clean

		*	Working-Age (15-64) Population
		*	 - percent of total population
		capture: confirm file CodeData/Raw/WAP_WDI
		if (_rc~=0 | "`fetch'"=="fetch") {
			capture: mkdir CodeData/Raw
			wbopendata, indicator(SP.POP.1564.TO.ZS) long `clear' full
			save CodeData/Raw/WAP_WDI, replace
		}
		else {
			use CodeData/Raw/WAP_WDI, `clear'
		}
		drop if region=="NA"
		keep country* capital lat longi year sp
		compress
		sort countrycode year
		save CodeData/Clean/WDI, replace
	}
	else {
		use CodeData/Clean/WDI, clear
	}
	
end

program define getGCBData

	syntax [, REPLACE FETCH CLEAR]

	if ("`fetch'"=="fetch") {
		local replace replace
	}
	
	capture: confirm file CodeData/Clean/GCBcodes.dta
	if (_rc~=0 | "`replace'"=="replace") {

		capture: mkdir CodeData
		capture: mkdir CodeData/Clean

		*	Carbon Emissions
		local filename CodeData/Raw/National_Carbon_Emissions_2018v1.0.xlsx
		capture: confirm file `filename'
		if (_rc~=0 | "`fetch'"=="fetch") {
			di as error "Please download National Carbon Emissions Data located at " as result "https://www.icos-cp.eu/GCP/2018" as error " to " as result "`filename'"
		}
		
		tempfile tf
		import excel using `filename', sheet(Consumption Emissions) cellrange(a9:hf68) ///
			firstrow case(preserve) `clear'
		ren * CC*
		ren CCA Year
		destring CC*, force replace
		reshape long CC, i(Year) j(CountryName) string
		destring CC, force replace
		compress
		save `tf'
		
		import excel using `filename', sheet(Territorial Emissions) cellrange(a17:hf76) ///
			firstrow case(preserve) clear
		ren * TC*
		ren TCA Year
		destring TC*, force replace
		reshape long TC, i(Year) j(CountryName) string
		destring TC, force replace
		compress
		merge 1:1 CountryName Year using `tf', nogen
		
		compress
		order CountryName Year
		sort CountryName Year
		save CodeData/Clean/GCB, replace
		
		import excel using `filename', sheet(Consumption Emissions) cellrange(b8:hf9) ///
			case(preserve) clear
		unab allvars: *
		local nv: list sizeof allvars
		set obs `=2+`nv''
		local cn 3
		foreach var of local allvars {
			replace B = `var'[1] in `cn'
			replace C = `var'[2] in `cn'
			local ++cn
		}
		drop in 1/2
		ren * drop*
		ren dropB name_GCB
		ren dropC name_GCB2
		drop drop*
		save CodeData/Clean/GCBcodes, replace
		
	}
	else {
		use CodeData/Clean/GCBcodes, `clear'
	}
	
end

program define getTEDData

	syntax [, REPLACE FETCH CLEAR]

	if ("`fetch'"=="fetch") {
		local replace replace
	}
	
	capture: confirm file CodeData/Clean/TED.dta
	if (_rc~=0 | "`replace'"=="replace") {

		capture: mkdir CodeData
		capture: mkdir CodeData/Clean

		*	Carbon Emissions
		local filename CodeData/Raw/TED.xlsx
		capture: confirm file `filename'
		if (_rc~=0 | "`fetch'"=="fetch") {
			di as error "Please download (semi-gated) Total Economy Database Data located at " as result "" as error " to " as result "`filename'"
		}
		local variant ADJUSTED
		import excel using `filename', ///
			sheet(TCB_`variant') cellrange(a5) firstrow case(preserve) `clear'
		local yc 1950
		foreach var of varlist * {
			if (strlen("`var'")<3) {
				ren `var' Value`yc'
				local ++yc
			}
		}
		keep if inlist(IND,"GDP EKS","Employment","Total Hours","Population")
		replace ISO = "CHN" if ISO=="CHN2"
		drop if length(ISO)>3
		drop REG MEA
		replace IND = cond(IND=="Population","POP",cond(IND=="Employment","EMP", ///
			cond(IND=="GDP EKS","EKSGDP","HRS")))
		reshape long Value, i(ISO IND) j(Year)
		reshape wide Value, i(ISO Year) j(IND) string
		ren Value* *

		compress
		order ISO COU
		sort ISO Year
		save CodeData/Clean/TED, replace		
		
	}
	else {
		use CodeData/Clean/TED, `clear'
	}
	
end

program define getWEOData

	syntax [, REPLACE FETCH CLEAR]

	if ("`fetch'"=="fetch") {
		local replace replace
	}
	
	capture: confirm file CodeData/Clean/WEO.dta
	if (_rc~=0 | "`replace'"=="replace") {

		capture: mkdir CodeData
		capture: mkdir CodeData/Clean

		*	Carbon Emissions
		capture: confirm file CodeData/Raw/WEO.txt
		if (_rc~=0 | "`fetch'"=="fetch") {
			local URL https://www.imf.org/external/pubs/ft/weo/2019/01/weodata/weoreptc.aspx?sy=1980&ey=2019&scc=1&sic=1&sort=country&ds=.&br=1&c=512%2c672%2c914%2c946%2c612%2c137%2c614%2c546%2c311%2c962%2c213%2c674%2c911%2c676%2c193%2c548%2c122%2c556%2c912%2c678%2c313%2c181%2c419%2c867%2c513%2c682%2c316%2c684%2c913%2c273%2c124%2c868%2c339%2c921%2c638%2c948%2c514%2c943%2c218%2c686%2c963%2c688%2c616%2c518%2c223%2c728%2c516%2c836%2c918%2c558%2c748%2c138%2c618%2c196%2c624%2c278%2c522%2c692%2c622%2c694%2c156%2c142%2c626%2c449%2c628%2c564%2c228%2c565%2c924%2c283%2c233%2c853%2c632%2c288%2c636%2c293%2c634%2c566%2c238%2c964%2c662%2c182%2c960%2c359%2c423%2c453%2c935%2c968%2c128%2c922%2c611%2c714%2c321%2c862%2c243%2c135%2c248%2c716%2c469%2c456%2c253%2c722%2c642%2c942%2c643%2c718%2c939%2c724%2c644%2c576%2c819%2c936%2c172%2c961%2c132%2c813%2c646%2c199%2c648%2c733%2c915%2c184%2c134%2c524%2c652%2c361%2c174%2c362%2c328%2c364%2c258%2c732%2c656%2c366%2c654%2c734%2c336%2c144%2c263%2c146%2c268%2c463%2c532%2c528%2c944%2c923%2c176%2c738%2c534%2c578%2c536%2c537%2c429%2c742%2c433%2c866%2c178%2c369%2c436%2c744%2c136%2c186%2c343%2c925%2c158%2c869%2c439%2c746%2c916%2c926%2c664%2c466%2c826%2c112%2c542%2c111%2c967%2c298%2c443%2c927%2c917%2c846%2c544%2c299%2c941%2c582%2c446%2c474%2c666%2c754%2c668%2c698&s=NGDP&grp=0&a=
			copy `"`URL'"' CodeData/Raw/WEO.txt, replace
		}
		import delimited using CodeData/Raw/WEO.txt, ///
			delim("\t") bindquotes(nobind) stripquotes(no) `clear' case(preserve)

		keep if ~mi(Cou)
		compress
		save CodeData/Clean/WEO, replace
		
	}
	else {
		use CodeData/Clean/WEO, `clear'
	}

end

program define getPWTData

	syntax [, REPLACE FETCH CLEAR]

	if ("`fetch'"=="fetch") {
		local replace replace
	}
	
	capture: confirm file CodeData/Clean/PWT.dta
	if (_rc~=0 | "`replace'"=="replace") {

		capture: mkdir CodeData
		capture: mkdir CodeData/Clean

		capture: confirm file CodeData/Raw/pwt91.dta
		if (_rc~=0 | "`fetch'"=="fetch") {
			local URL https://www.rug.nl/ggdc/docs/pwt91.dta
			copy `"`URL'"' CodeData/Raw/pwt91.dta, replace
		}
		use CodeData/Raw/pwt91, `clear'
		compress
		save CodeData/Clean/PWT, replace

	}

end