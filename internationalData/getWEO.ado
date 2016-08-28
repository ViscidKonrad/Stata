*! version 0.8	20apr2016	David Rosnick
program define getWEO

	syntax [anything] [, WEOYear(integer 2016) WEOVersion(integer 1) Start(integer 1980) ///
		End(integer 2021) ISO MAD MPD OECD TED WDI WEO Numeric ALPHA2 ALPHA3 Countryname RAW CLEAN ESTimates UNITS SCALE NOTES]

	tempfile mtemp htmlfile mrmfile
	
	tokenize `anything'
	local countryvar `1'
	macro shift
	local variables `*'
	
	local start=max(`start',1980)
	local end=min(`end',`weoyear'+5)
	if (`weoyear'==2007) {
		local end = min(`end',2008)
	}
	idCodes `countryvar', `iso' `mad' `mpd' `ted' `wdi' `weo' `numeric' `alpha2' `alpha3' `countryname'
	local mname `r(codeVar)'
	if ("`variables'"=="") {
		local variables NGDP_R
	}

	preserve
	capture: rename `countryvar' `mname'
	keep `mname'
	keep if ~mi(`mname')
	merge 1:n `mname' using CountryCodes, keep(match) nogen
	keep `mname' WEO*
	keep if ~mi(WEONumeric)
	save `mtemp', replace
	*
	*	WEO URL parameters:				(default)	note
	*	sy:		start year				(2014)*
	*	ey:		end year				(2021)*					
	*	ssm:	subject notes?			(0)
	*	scsm:	country-specific notes?	(0)
	*	scc: 	WEO country codes?		(0)
	*	ssd:	subject description?	(0)
	*	sic:	WEO alpha-3 code?		(0)
	*	ssc:	subject code?			(0)
	*	sort:	sort by?				(country)	alt: subject
	*	ds:		decimal symbol			(.)			alt: ,
	*	br:		show blank rows?		(0)
	*	c:		list of country codes				comma-delimited
	*	s:		list of subject codes				comma-delimited
	*	grp:	groups? (vs countries)	(0)
	*	a:		header for groups?		(0)
	*
	*	pr.x, pr.y, pr1.x, pr1.y:	"prepare report" button click location
	*		- pr (pr1) indicates upper (lower) button
	*		- x (y) indicates pixels across (down) from upper left corner of button
	*
	*	* year defaults depend on WEO version
	*
	levelsof WEONumeric, local(wcodes) s("%2C")
	local vpars = subinstr("`variables'"," ","%2C",.)
	local baseurl http://www.imf.org/external/pubs/ft/weo/`weoyear'/0`weoversion'/weodata/weoreptc.aspx?
	local fixedpars br=1&scc=1&sic=1&ssc=1&ssd=1&pr.x=1&pr.y=1
	local optpars sy=`start'&ey=`end'&c=`wcodes'&s=`vpars'
	local url `baseurl'&`fixedpars'&`optpars'

	copy "`url'" `htmlfile', replace text
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
	import delimited using `mrmfile', delim("\t") bindquotes(nobind) stripquotes(no) clear case(preserve)
	replace Country = subinstr(Country,"Â","",.)
		
	if ("`raw'"~="raw") {
		rename Country WEOCountryName
		rename ISO WEOAlpha3
		rename WEOCountryCode WEONumeric
		destring WEONumeric, force replace
		keep if ~mi(WEONumeric)
		merge m:1 WEONumeric using `mtemp', nogen
		macro li _mname
		sort `mname'
		if ("`clean'"=="clean") {
			destring v*, force replace ig(",")
			compress
			keep if ~mi(WEOS)
			reshape long v, i(`mname' WEOSubjectCode) j(Year)
			sum Year, meanonly
			replace Year = Year+`start'-r(min)
			destring v, force replace ig(",")
			local slist SubjectDescriptor
			if ("`estimates'"=="estimates") {
				local slist "`slist' EstimatesStartAfter"
			}
			if ("`units'"=="units") {
				local slist "`slist' Units"
			}
			if ("`scale'"=="scale") {
				local slist "`slist' Scale"
			}
			local wlist WEONumeric WEOAlpha3 WEOCountryName
			local wlist: list wlist | mname
			keep `wlist' Year WEOSub v `slist'
			reshape wide v `slist', i(`mname' Year) j(WEOSub) string
			renpfix v
			local clist `mname' WEONumeric WEOAlpha3 WEOCountryName Year `variables'
			local clist: list uniq clist
			order `clist'
			foreach var of varlist `variables' {
				local slab = SubjectDescriptor`var'[1]
				lab var `var' "`slab'"
			}
			drop SubjectDesc*
			compress
			sort `mname' Year

		}
		capture: rename `mname' `countryvar'
		compress
	}
	notes drop _dta
	notes: WEO data (`weoyear'v`weoversion') downloaded from `url' on TS
	notes
	restore, not

end
