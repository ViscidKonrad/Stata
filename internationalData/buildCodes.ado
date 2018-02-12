*! version 1.3	12feb2018	David Rosnick
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
	
		tempfile isofile weofile wbfile tedfile oecdfile pwtfile allfiles

		readWikiISO `isofile'

		readWEO `weofile'
		gen ISOAlpha3 = WEOAlpha3
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
		save `allfiles', replace
		notes
										
		readPWT `pwtfile', pwt(pwt90)
		gen ISOAlpha3 = PWTAlpha3
		merge 1:1 ISOAlpha3 using `allfiles', nogen
		save `allfiles', replace
		notes
						
		readOECD `oecdfile'
		gen ISOAlpha3 = OECDAlpha3 if OECDAlpha3~="DEW"
		merge 1:1 ISOAlpha3 using `allfiles', nogen
		save `allfiles', replace
		notes
		
		readWDI `wbfile'
		gen ISOAlpha3 = WDIAlpha3
		replace ISOAlpha3 = "UVK" if WDIAlpha3 == "XKX"
		merge 1:1 ISOAlpha3 using `allfiles'
		qui levelsof WDIAlpha3 if _merge==1 | ISOAlpha3=="UVK", local(isolevs) clean
		if ("`isolevs'"~="") {
			local inum : list sizeof isolevs
			local addnote `"WDI data include non-ISO-official alpha-3 code`=cond(`inum'>1,"s","")' "'
			foreach iso of local isolevs {
				qui levelsof WDICountryName if WDIAlpha3=="`iso'", local(ccode) clean
				local addnote `"`addnote' `iso' (`ccode')"'
			}
			notes WDIAlpha3: `addnote'
		}
		drop _merge
		save `allfiles', replace
		notes
		
		readTED `tedfile'
		gen ISOAlpha3 = TEDAlpha3
		replace ISOAlpha3 = "CHN" if substr(TEDA,1,3)=="CHN"
		merge n:1 ISOAlpha3 using `allfiles'
		qui levelsof TEDAlpha3 if _merge==1, local(isolevs) clean
		if ("`isolevs'"~="") {
			local inum : list sizeof isolevs
			local addnote `"TED data include non-ISO-official alpha-3 code`=cond(`inum'>1,"s","")' "'
			foreach iso of local isolevs {
				qui levelsof TEDCountryName if TEDAlpha3=="`iso'", local(ccode) clean
				local addnote `"`addnote' `iso' (`ccode')"'
			}
			notes TEDAlpha3: `addnote'
		}
		drop _merge
		save `allfiles', replace
		notes
		
		compress
		replace ISOAlpha3 = "" if mi(ISOC)
		lab var ISOAlpha3 "ISO 3166-1 three-letter country code"
		local vorder ISONumeric WEONumeric 
		local vorder `vorder' ISOAlpha2 TEDAlpha3 WDIAlpha2
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

	syntax anything [, REPLACE PWTlocal(string asis) XLSX] 
	
	tempfile pf cj
	local suffix dta
	if (c(version)<14 | "`xlsx'"=="xlsx") {
		local suffix xlsx
	}
	local url https://www.rug.nl/ggdc/docs/pwt90.`suffix'
	
	capture: confirm file `"`anything'"'
	if (_rc~=0 | "`replace'"=="replace") {
		if ("`suffix'"=="xlsx") {
			import excel using `"`url'"', sheet(Data) clear firstrow case(preserve)
		}
		else {
			capture: use pwt90, clear
			if (_rc~=0) {
				copy `"`url'"' pwt90.dta, replace
			}
			use pwt90, clear
		}
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
		! file `htmlfile'
		if (c(version)<14 & c(os)=="MacOSX") {
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
		import delimited using `mrmfile', delim("||||", asstring) bindquotes(nobind) stripquotes(no) clear charset("utf8") 
		replace v1 = regexr(v1,`"<span style="display[^>]*>[^>]+>"',"")
		gen ISOCountryName = regexs(2) if regexm(v1,`"<td>(<span[^>]*>)?<a href="[^:>]+>([^<]+)</a>(</span>)?(<sup.*</sup>)?</td>"')
		gen ISOAlpha2 = regexs(1) if ~mi(ISOCou) & regexm(v1[_n+1],`"<td><a href="/wiki/ISO_3166-1_alpha-2#[A-Z][A-Z]" title="ISO 3166-1 alpha-2"><span [^>]*>([A-Z][A-Z])</span></a></td>"')
		gen ISOAlpha3 = regexs(1) if ~mi(ISOCou) & regexm(v1[_n+2],`"<td><span [^>]*>([A-Z][A-Z][A-Z])</span></td>"')
		gen ISONumeric = regexs(1) if ~mi(ISOCou) & regexm(v1[_n+3],`"<td><span [^>]*>([0-9][0-9][0-9])</span></td>"')
		keep if ~mi(ISOC) & ~mi(ISOAlpha2)
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

	local url https://www.imf.org/external/pubs/ft/weo/2017/02/weodata/weoreptc.aspx?sy=1980&ey=1980&scc=1&sic=1&sort=country&ds=.&br=1&c=512%2c672%2c914%2c946%2c612%2c137%2c614%2c546%2c311%2c962%2c213%2c674%2c911%2c676%2c193%2c548%2c122%2c556%2c912%2c678%2c313%2c181%2c419%2c867%2c513%2c682%2c316%2c684%2c913%2c273%2c124%2c868%2c339%2c921%2c638%2c948%2c514%2c943%2c218%2c686%2c963%2c688%2c616%2c518%2c223%2c728%2c516%2c836%2c918%2c558%2c748%2c138%2c618%2c196%2c624%2c278%2c522%2c692%2c622%2c694%2c156%2c142%2c626%2c449%2c628%2c564%2c228%2c565%2c924%2c283%2c233%2c853%2c632%2c288%2c636%2c293%2c634%2c566%2c238%2c964%2c662%2c182%2c960%2c359%2c423%2c453%2c935%2c968%2c128%2c922%2c611%2c714%2c321%2c862%2c243%2c135%2c248%2c716%2c469%2c456%2c253%2c722%2c642%2c942%2c643%2c718%2c939%2c724%2c644%2c576%2c819%2c936%2c172%2c961%2c132%2c813%2c646%2c199%2c648%2c733%2c915%2c184%2c134%2c524%2c652%2c361%2c174%2c362%2c328%2c364%2c258%2c732%2c656%2c366%2c654%2c734%2c336%2c144%2c263%2c146%2c268%2c463%2c532%2c528%2c944%2c923%2c176%2c738%2c534%2c578%2c536%2c537%2c429%2c742%2c433%2c866%2c178%2c369%2c436%2c744%2c136%2c186%2c343%2c925%2c158%2c869%2c439%2c746%2c916%2c926%2c664%2c466%2c826%2c112%2c542%2c111%2c967%2c298%2c443%2c927%2c917%2c846%2c544%2c299%2c941%2c582%2c446%2c474%2c666%2c754%2c668%2c698&s=NGDP_RPCH&grp=0&a=
	capture: confirm file `"`anything'"'
	if (_rc~=0 | "`replace'"=="replace") {
		copy "`url'" `htmlfile'
		if (c(version)<14 & c(os)=="MacOSX") {
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
		*replace Country = subinstr(Country,"Â","",.)
		keep WEOCountryCode ISO Country
		destring WEOCountryCode, force replace
		rename WEOCountryCode WEONumeric
		rename ISO WEOAlpha3
		rename Country WEOCountryName
		keep if ~mi(WEOAlpha3)
		set obs `=_N+1'
		replace WEOC = "Somalia" in l
		replace WEOAlpha3 = "SOM" in l
		
		lab var WEONumeric "IMF's WEO numeric country code"
		lab var WEOCountryName "IMF's WEO country name"
		lab var WEOAlpha3 "IMF's WEO three-letter country code"
		notes: Downloaded WEO codes from `url' on TS
		notes: - Added Somalia (SOM) to WEO codes though neither numeric country code nor data is available
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

	syntax anything [, REPLACE]
			
	local url https://www.conference-board.org/retrievefile.cfm?filename=TED_1_NOV20171.xlsx&type=subsite
	capture: confirm file `"`anything'"'
	if (_rc~=0 | "`replace'"=="replace") {
		import excel TEDAlpha3=B TEDCountryName=C using `"`url'"', sheet("TCB_ADJUSTED") clear
		keep if ~mi(TEDA) & TEDA~="ISO"
		egen tedt = tag(TEDA)
		keep if tedt
		drop tedt
		lab var TEDCountryName "Conference Board's TED country name"
		lab var TEDAlpha3 "Conference Board's TED three-letter country code"
		notes: Downloaded TED codes from `url' on TS
		compress
		save `"`anything'"', replace
	
	}
	else {
		use `"`anything'"', clear
	}

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
		gen prep = "Downloaded OECD codes from `oecdlocal' on "+regexs(1) if regexm(v1,`"<Prepared>([^<]*)</Prepared>"')
		levelsof prep if ~mi(prep), local(plist) clean
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
