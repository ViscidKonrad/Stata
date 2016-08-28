*! version 1.0	22oct2015	David Rosnick
program define buildCodes

	syntax anything [, REPLACE LOCAL]
	
	if (regexm(`"`anything'"',".dta$")) {
		capture: confirm file `"`anything'"'
	}
	else {
		capture: confirm file `"`anything'.dta"'
	}
	if (_rc~=0 | "`replace'"=="replace") {
	
		if ("`local'"=="local") {
			local local , `replace'
		}
	
		tempfile isofile weofile wbfile tedfile oecdfile pwtfile

		readWikiISO `isofile'	

		readWEO `weofile'
		gen ISOAlpha3 = WEOAlpha3
		replace ISOAlpha3 = "UNK" if WEOAlpha3 == "UVK"
		gen byte ISOtemp = WEOAlpha3~=ISOAlpha3
		merge 1:1 ISOAlpha3 using `isofile'
		qui levelsof WEOAlpha3 if _merge==1, local(isolevs) clean
		if ("`isolevs'"~="") {
			local inum : list sizeof isolevs
			local addnote `"WEO data include non-ISO-official alpha-3 code`=cond(`inum'>1,"s","")' "'
			foreach iso of local isolevs {
				qui levelsof WEOCountryName if WEOAlpha3=="`iso'", local(ccode) clean
				local addnote `"`addnote' `iso' (`ccode')"'
			}
			notes WEOAlpha3: `addnote'
		}
		drop _merge
		save `"`anything'"', replace
		notes
				
		readPWT `pwtfile', pwt(pwt81.zip`local')
		gen ISOAlpha3 = PWTAlpha3
		merge 1:1 ISOAlpha3 using `"`anything'"', nogen
		save `"`anything'"', replace
		notes
				
		readOECD `oecdfile'
		gen ISOAlpha3 = OECDAlpha3 if OECDAlpha3~="DEW"
		merge 1:1 ISOAlpha3 using `"`anything'"', nogen
		save `"`anything'"', replace
		notes

		readWDI `wbfile'
		gen ISOAlpha3 = WDIAlpha3
		replace ISOAlpha3 = "UNK" if WDIAlpha3 == "KSV"
		gen byte ISOtemp = WDIAlpha3~=ISOAlpha3
		merge 1:1 ISOAlpha3 using `"`anything'"'
		qui levelsof WDIAlpha3 if _merge==1 | ISOAlpha3=="UNK", local(isolevs) clean
		if ("`isolevs'"~="") {
			local inum : list sizeof isolevs
			local addnote `"WDI data include non-ISO-official alpha-3 code`=cond(`inum'>1,"s","")' "'
			foreach iso of local isolevs {
				qui levelsof WDICountryName if WDIAlpha3=="`iso'", local(ccode) clean
				local addnote `"`addnote' `iso' (`ccode')"'
			}
			notes WDIAlpha3: `addnote'
		}
		drop _merge ISOtemp
		gen MergeName = ""
		foreach var of varlist ISOC WEOCountryN WDIC OECDC {
			replace MergeName = `var' if mi(MergeName)
		}
		save `"`anything'"', replace
		notes

		readTED `tedfile', ted(TED`local')
		gen MergeName = TEDC
		replace MergeName = "Former Federal Republic of Germany" if MergeName=="West Germany"
		replace MergeName = "United Kingdom of Great Britain and Northern Ireland" if MergeName=="United Kingdom"
		replace MergeName = "United States of America" if MergeName=="United States"
		replace MergeName = "Bosnia and Herzegovina" if MergeName=="Bosnia & Herzegovina"
		replace MergeName = "Kyrgyzstan" if MergeName=="Kyrgyz Republic"
		replace MergeName = "Macedonia (the former Yugoslav Republic of)" if MergeName=="Macedonia"
		replace MergeName = "Moldova (Republic of)" if MergeName=="Moldova"
		replace MergeName = "Slovakia" if MergeName=="Slovak Republic"
		replace MergeName = "Korea (Republic of)" if MergeName=="South Korea"
		replace MergeName = "Taiwan, Province of China" if MergeName=="Taiwan"
		replace MergeName = "Viet Nam" if MergeName=="Vietnam"
		replace MergeName = "Bolivia (Plurinational State of)" if MergeName=="Bolivia"
		replace MergeName = "Saint Lucia" if MergeName=="St. Lucia"
		replace MergeName = "Trinidad and Tobago" if MergeName=="Trinidad & Tobago"
		replace MergeName = "Venezuela (Bolivarian Republic of)" if MergeName=="Venezuela"
		replace MergeName = "Iran (Islamic Republic of)" if MergeName=="Iran"
		replace MergeName = "Syrian Arab Republic" if MergeName=="Syria"
		replace MergeName = "Congo (Democratic Republic of the)" if MergeName=="DR Congo"
		replace MergeName = "Tanzania, United Republic of" if MergeName=="Tanzania"
		merge 1:1 MergeName using `"`anything'"', nogen
		drop MergeName
		save `"`anything'"', replace
		notes
		
		compress
		lab var ISOAlpha3 "ISO 3166-1 three-letter country code"
		local vorder ISONumeric TEDNumeric WEONumeric 
		local vorder `vorder' ISOAlpha2 WDIAlpha2
		local vorder `vorder' ISOAlpha3 OECDAlpha3 PWTAlpha3 WDIAlpha3 WEOAlpha3
		local vorder `vorder' ISOCountryName OECDCountryName PWTCountryName TEDCountryName WDICountryName WEOCountryName
		order `vorder' 
		sort  `vorder'
		save `"`anything'"', replace
		d
		notes
	}
	else {
		use `"`anything'"', clear
	}

end

program define readPWT

	syntax anything [, REPLACE PWTlocal(string asis)] 
	
	tempfile pf cj
	local url http://www.rug.nl/research/ggdc/data/pwt/v81/pwt81.zip
	
	capture: confirm file `"`anything'"'
	if (_rc~=0 | "`replace'"=="replace") {
		! curl  -c `cj' `url' > `pf'
		unzipfile `pf', replace
		use pwt81, clear
		egen ctag = tag(countrycode)
		keep if ctag
		keep country*
		ren countrycode PWTAlpha3
		ren country PWTCountryName
		lab var PWTCou "PWT country name"
		lab var PWTAlpha3 "PWT three-letter country code"
		notes: Downloaded PWT codes from `url' on TS
		compress
		save `"`anything'"', replace
	}
	else {
		use `"`anything'"', clear
	}
	notes

end

program define readWikiISO

	syntax anything [, REPLACE]
	
	tempfile htmlfile mrmfile destination
	
	local url https://en.wikipedia.org/wiki/ISO_3166-1
	
	capture: confirm file `"`anything'"'
	if (_rc~=0 | "`replace'"=="replace") {
		copy "`url'" `htmlfile', replace text
		if (c(os)=="MacOSX") {
			if (c(charset)=="mac") {
				! iconv -c -f UTF8 -t MACROMAN `htmlfile' > `mrmfile'
			}
			else {
				! iconv -c -f UTF8 -t LATIN1 `htmlfile' > `mrmfile'
			}
		}
		else {
			local mrmfile `htmlfile'
		}
		import delimited using `mrmfile', delim("||||", asstring) bindquotes(nobind) stripquotes(no) clear charset("mac") 
		replace v1 = regexr(v1,`"<span style="display[^>]*>[^>]+>"',"")
		gen ISOCountryName = regexs(2) if regexm(v1,`"<td>(<span[^>]*>)?<a href="[^:>]+>([^<]+)</a>(</span>)?</td>"')
		gen ISOAlpha2 = regexs(1) if ~mi(ISOCou) & regexm(v1[_n+1],`"<td><a href="/wiki/ISO_3166-1_alpha-2#[A-Z][A-Z]" title="ISO 3166-1 alpha-2"><span style="font-family: monospace, monospace;">([A-Z][A-Z])</span></a></td>"')
		gen ISOAlpha3 = regexs(1) if ~mi(ISOCou) & regexm(v1[_n+2],`"<td><span style="font-family: monospace, monospace;">([A-Z][A-Z][A-Z])</span></td>"')
		gen ISONumeric = regexs(1) if ~mi(ISOCou) & regexm(v1[_n+3],`"<td><span style="font-family: monospace, monospace;">([0-9][0-9][0-9])</span></td>"')
		keep if ~mi(ISOC)
		drop v1
		order *, alpha
		lab var ISON "ISO 3166-1 numeric country code"
		lab var ISOCou "ISO 3166   English short country name"
		lab var ISOAlpha2 "ISO 3166-1 two-letter country code"
		lab var ISOAlpha3 "ISO 3166-1 three-letter country code"
		lab data "ISO 3166-1 Country Codes"
		notes: Downloaded ISO 3166-1 codes from `url' on TS
		notes: - Only official assignments included
		compress
		save `"`anything'"', replace
	}
	else {
		use `"`anything'"', clear
	}
	notes

end

program define readWEO

	syntax anything [, REPLACE]

	tempfile htmlfile mrmfile destination

	local url https://www.imf.org/external/pubs/ft/weo/2013/02/weodata/weoreptc.aspx?sy=1980&ey=1980&scc=1&sic=1&sort=country&ds=.&br=1&c=512%2C446%2C914%2C666%2C612%2C668%2C614%2C672%2C311%2C946%2C213%2C137%2C911%2C962%2C193%2C674%2C122%2C676%2C912%2C548%2C313%2C556%2C419%2C678%2C513%2C181%2C316%2C682%2C913%2C684%2C124%2C273%2C339%2C921%2C638%2C948%2C514%2C943%2C218%2C686%2C963%2C688%2C616%2C518%2C223%2C728%2C516%2C558%2C918%2C138%2C748%2C196%2C618%2C278%2C522%2C692%2C622%2C694%2C156%2C142%2C624%2C449%2C626%2C564%2C628%2C283%2C228%2C853%2C924%2C288%2C233%2C293%2C632%2C566%2C636%2C964%2C634%2C182%2C238%2C453%2C662%2C968%2C960%2C922%2C423%2C714%2C935%2C862%2C128%2C135%2C611%2C716%2C321%2C456%2C243%2C722%2C248%2C942%2C469%2C718%2C253%2C724%2C642%2C576%2C643%2C936%2C939%2C961%2C644%2C813%2C819%2C199%2C172%2C733%2C132%2C184%2C646%2C524%2C648%2C361%2C915%2C362%2C134%2C364%2C652%2C732%2C174%2C366%2C328%2C734%2C258%2C144%2C656%2C146%2C654%2C463%2C336%2C528%2C263%2C923%2C268%2C738%2C532%2C578%2C944%2C537%2C176%2C742%2C534%2C866%2C536%2C369%2C429%2C744%2C433%2C186%2C178%2C925%2C436%2C869%2C136%2C746%2C343%2C926%2C158%2C466%2C439%2C112%2C916%2C111%2C664%2C298%2C826%2C927%2C542%2C846%2C967%2C299%2C443%2C582%2C917%2C474%2C544%2C754%2C941%2C698&s=NGDP_RPCH&grp=0&a=
	capture: confirm file `"`anything'"'
	if (_rc~=0 | "`replace'"=="replace") {
		copy "`url'" `htmlfile'
		if (c(os)=="MacOSX") {
			if (c(charset)=="mac") {
				! iconv -c -f ISO-8859-1 -t MACROMAN `htmlfile' > `mrmfile'				
			}
			else {
				! iconv -c -f ISO-8859-1 -t LATIN1 `htmlfile' > `mrmfile'
			}
		}
		else {
			local mrmfile `htmlfile'
		}
		import delimited using `mrmfile', ///
			delim("\t") bindquotes(nobind) stripquotes(no) clear case(preserve)
		replace Country = subinstr(Country,"Â","",.)
		keep WEOCountryCode ISO Country
		destring WEOCountryCode, force replace
		rename WEOCountryCode WEONumeric
		rename ISO WEOAlpha3
		rename Country WEOCountryName
		keep if ~mi(WEOAlpha3)
		lab var WEONumeric "IMF's WEO numeric country code"
		lab var WEOCountryName "IMF's WEO country name"
		lab var WEOAlpha3 "IMF's WEO three-letter country code"
		notes: Downloaded WEO codes from `url' on TS
		compress
		save `"`anything'"', replace
	}
	else {
		use `"`anything'"', clear
	}

end

program define readWDI

	syntax anything [, REPLACE]
	
	capture: confirm file `"`anything'"'
	if (_rc~=0 | "`replace'"=="replace") {
		wbopendata, indicator(ny.gdp.mktp.kd.zg) latest nometadata clear
		keep countryname countrycode iso2code
		rename countryname WDICountryName
		rename countrycode WDIAlpha3
		rename iso2code WDIAlpha2
		lab var WDICountryName "World Bank's WDI country name"
		lab var WDIAlpha3 "World Bank's WDI three-letter country code"
		lab var WDIAlpha2 "World Bank's WDI two-letter country code"
		notes: Downloaded WDI codes from wbopendata on TS
		compress
		save `"`anything'"', replace
	}
	else {
		use `"`anything'"', clear
	}

end

program define readTED

	syntax anything [, REPLACE TEDlocal(string asis)]
			
	tempfile csvfilebase	
	local url https://www.conference-board.org/retrievefile.cfm?filename=TED---Output-Labor-and-Labor-Productivity-1950-2015.xlsx&type=subsite

	capture: confirm file `"`anything'"'
	if (_rc~=0 | "`replace'"=="replace") {
		tokenize `"`tedlocal'"', parse(",")
		local tedfile `"`1'"'
		macro shift
		if (`"`tedfile'"'=="") {
			tempfile tedfile
		}
		else {
			local treplace `"`1'"'
		}
		capture: confirm file `"`tedfile'"'
		if (_rc~=0 | "`treplace'"=="replace") {
			copy `"`url'"' `"`tedfile'"', replace
		}
		import excel TEDNumeric=A TEDCountryName=B using `"`tedfile'"', sheet("Population") clear
		destring TEDN, force replace
		keep if ~mi(TEDN)
		lab var TEDCountryName "Conference Board's TED country name"
		lab var TEDN "Conference Board's TED numeric code"
		notes: Downloaded TED codes from `url' on TS
		compress
		save `"`anything'"', replace
	
	}
	else {
		use `"`anything'"', clear
	}
	notes

end

program define readOECD

	syntax anything [, REPLACE OECDlocal(string asis)]

	if (`"`oecdlocal'"'=="") {
		local oecdlocal `"http://stats.oecd.org/restsdmx/sdmx.ashx/GetDataStructure/QNA"'
	}
	capture: confirm file `"`anything'"'
	if (_rc~=0 | "`replace'"=="replace") {
		tempfile tt tf
		copy `oecdlocal' `tt'
		filefilter `tt' `tf', from("<Code") to("\U")
		import delimited using `tf', delim(`"<Code"', asstring) clear
		gen prep = "Downloaded OECD codes from `oecdlocal' on "+regexs(1) if 			regexm(v1,`"<Prepared>([^<]*)</Prepared>"')
		levelsof prep if ~mi(prep), local(plist)
		notes: `plist'
		gen listid = regexs(1) if regexm(v1,`"List id="([^"]*)"')
		gen listnum = sum(~mi(listid))
		levelsof listnum if listid=="CL_QNA_LOCATION", local(ln)
		keep if mi(listid) & listnum==`ln'
		keep v1
		gen details = regexs(1)+"|"+regexs(3) if regexm(v1,`"value="([^"]*)"( parentCode="[^"]*")*><Description xml:lang="en">([^<]*)<"')
		split details, parse("|")
		drop v1 details
		ren details1 OECDAlpha3
		ren details2 OECDCountryName
		keep if regexm(OECDAlpha3,"^[A-Z][A-Z][A-Z]$")
		drop if OECDAlpha3=="OTF"

		lab var OECDCountryName "OECD's Economic Outlook country name"
		lab var OECDAlpha3 "OECD's Economic Outlook three-letter country code"
		compress
		save `"`anything'"', replace
	}
	else {
		use `"`anything'"', replace
	}
	notes
	
end
