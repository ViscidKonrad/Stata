*! version 0.6	02oct2017	David Rosnick
program define buildChartBookData

	syntax anything(name=year) [, REAL ADJINC CPIbase(real 0) VERIFY KEEP]

	set type double
	set maxvar 6144
	
	*	Get SCF Data
	getGlobals `year', cpi(`cpibase')
	scalar CPILAG = r(CPILAG)
	scalar CPIADJ = r(CPIADJ)
	scalar CPIBASE = r(CPIBASE)
	getSCF `year', clear
	keep X* `r(ID)' `r(IID)'
	keep X* `r(ID)' `r(IID)'
	
	*	sample and weight adjustments
	keep if `r(ID)'>0 & `r(IID)'>0 & X42001>0
	clonevar WGT = X42001
	replace WGT = WGT/5
	lab var WGT "sample weight"
	notes WGT: from X42001
	clonevar WGT0 = X42001
	notes WGT0: original weight
	svyset `r(IID)' [pw=WGT]
	
	*   consider all FINANCE COMPANIES reported in mortgage 
    *		grids to be MORTGAGE COMPANIES
	forvalues ii=9083/9085 {
		replace X`ii' = 18 if X`ii'==14
		notes X`ii': may be modified from original (consider all FINANCE COMPANIES reported in mortgage grids to be MORTGAGE COMPANIES)
	}
	forvalues ii=9099/9101 {
		capture: replace X`ii' = 18 if X`ii'==14
		capture: notes X`ii': may be modified from original (consider all FINANCE COMPANIES reported in mortgage grids to be MORTGAGE COMPANIES)
	}

	lab def YESNO 1 "Yes" 0 "No"
	
	*	demographic variables
	di `"addDemographic `year'"'
	qui addDemographic `year'
	
	*	income variables
	di `"addIncome `year', `adjinc' cpilag(`=CPILAG')"'
	qui addIncome `year', `adjinc' cpilag(`=CPILAG')
	
	*	attitudinal and related variables
	di `"addAttitudinal `year'"'
	qui addAttitudinal `year'
	
	if (`year'>=1995) {
		*	shopping for financial services
		di `"addServices `year'"'
		qui addServices `year'
	}

	*	assets, debts, networth, and related variables
	di `"addFinances `year'"'
	qui addFinances `year'

	di `"addCapitalGains `year'"'
	qui addCapitalGains `year'
	
	*	characteristics of loans
	di `"addLoanInfo `year'"'
	qui addLoanInfo `year'
	
	if ("`real'"=="real") {
		di `"adjust all dollar values"'
		*	adjust all dollar values
		qui foreach var of varlist INCOME ASSET NETWORTH FIN LIQ CDS NMMF STOCKS ///
				BOND RETQLIQ SAVBND CASHLI OTHMA OTHFIN NFIN VEHIC HOUSES ORESRE ///
				NNRESRE BUS OTHNFIN DEBT MRTHEL RESDBT OTHLOC CCBAL INSTALL ///
				ODEBT KGTOTAL KGHOUSE KGORE KGBUS KGSTMF TPAY MORTPAY CONSPAY ///
				REVPAY TPLOAN PLOAN1-PLOAN8 TLLOAN LLOAN1-LLOAN12 EQUITY DEQ ///
				VLEASE VOWN RETEQ NORMINC CHECKING SAVING MMA CALL HOMEEQ ///
				IRAKH PENEQ VEH_INST EDN_INST OTH_INST HELOC NH_MORT WAGEINC  ///
				BUSSEFARMINC INTDIVINC KGINC SSRETINC TRANSFOTHINC RENTINC ///
				NHNFIN THRIFT CURRPEN FUTPEN STMUTF TFBMUTF ///
				GBMUTF OBMUTF COMUTF OMUTF ANNUIT TRUSTS ACTBUS NONACTBUS NOTXBND ///
				MORTBND GOVTBND OBND OUTPEN OUTMARG ///
				PAYMORT1 PAYMORT2 PAYMORT3 PAYMORTO PAYLOC1 ///
				PAYLOC2 PAYLOC3 PAYLOCO ///
				PAYHI1 PAYHI2 PAYLC1 PAYLC2 PAYLCO PAYORE1 PAYORE2 PAYORE3 ///
				PAYOREV PAYVEH1 PAYVEH2 PAYVEH3 PAYVEH4 PAYVEHM PAYVEO1 PAYVEO2 ///
				PAYVEOM PAYEDU1 PAYEDU2 PAYEDU3 PAYEDU4 PAYEDU5 PAYEDU6 PAYEDU7 ///
				PAYILN1 PAYILN2 PAYILN3 PAYILN4 PAYILN5 PAYILN6 PAYILN7 PAYMARG ///
				PAYINS PAYPEN1 PAYPEN2 PAYPEN3 PAYPEN4 PAYPEN5 PAYPEN6 FARMBUS_KG MORT1 ///
				MORT2 MORT3 FARMBUS NHNFIN PENACCTWD MMDA MMMF FOODHOME FOODAWAY FOODDELV ///
				PREPAID FAEQUITY {
			replace `var' = `var'*CPIADJ if ~inlist(`var',-1,-2)
		}
	}
	
	*	create categorical variables based on dollar values
	capture: drop INCCL2
	egen byte INCCL2 = cut(INCOME), at(-10000 10000 25000 50000 100000) icodes
	replace INCCL2 = INCCL2+1
	replace INCCL2 = 5 if mi(INCCL2)
		
	lab def INCCL2 1 "<$10,000 ", replace
	local ilev 1
	local ival : di %6.0fc 10000
	foreach ii in 25000 50000 100000 {
		local ++ilev
		local cval: di %7.0fc `ii'
		lab def INCCL2 `ilev' "$`ival'-`cval' ", add
		local ival: di %6.0fc `ii'
	}
	local ++ilev
	lab def INCCL2 `ilev' " $100,000+", modify
	lab val INCCL2 INCCL2
	lab var INCCL2 "`: var lab INCOME', categorical"
	tab INCCL2, m

	addSCFQuantiles NWCAT=NETWORTH, at(25(25)75 90)
	addSCFQuantiles INCCAT=INCOME, at(20(20)80 90)
	addSCFQuantiles ASSETCAT=ASSET, at(20(20)80 90)
	addSCFQuantiles NINCCAT=NORMINC, at(20(20)80 90)

	addSCFQuantiles NINC2CAT=NORMINC, at(50 90)
	/*
	addSCFQuantiles NW10CAT=NETWORTH, at(10(10)90)
	addSCFQuantiles INC10CAT=INCOME, at(10(10)90)
	addSCFQuantiles NINC10CAT=NORMINC, at(10(10)90)
	*/
	addSCFQuantiles NWPCTLECAT=NETWORTH, at(10(10)90 95 99)
	addSCFQuantiles INCPCTLECAT=INCOME, at(10(10)90 95 99)
	addSCFQuantiles NINCPCTLECAT=NORMINC, at(10(10)90 95 99)
	
	
	di `"compressing data"'
	qui compress
	
	if ("`verify'"=="verify") {
		verifySCF `year', `keep'
	}
		
end

capture: program drop getSCF
program define getSCF
	
	syntax anything(name=year) [, CLEAR REPLACE REFRESH]
	
	if ("`refresh'"=="refresh") {
		local replace replace
	}
	if (`year'<2004) {
		local year `=substr("`year'",3,.)'
	}
	capture: confirm file Data
	if (_rc~=0) {
		mkdir Data
	}
	capture: confirm file Data/scf`year'.dta
	if (_rc~=0 | "`replace'"=="replace") {
		cd Data
		local idir: dir . files "*.dta"
		capture: confirm file scf`year's.zip
		if (_rc~=0 | "`refresh'"=="refresh") {
			copy `"https://www.federalreserve.gov/econres/files/scf`year's.zip"' scf`year's.zip, `replace'
		}
		unzipfile scf`year's.zip, replace
		local ndir: dir . files "*.dta"
		local newfile: list ndir - idir
		macro li _newfile
		! mv `newfile' scf`year'.dta
		cd ..
	}
	use Data/scf`year', `clear'
	
end

capture: program drop mconv
program define mconv

	syntax anything(name=varname), F(integer) [REPLACE]
	
	capture: confirm var `varname'
	if (_rc~=0) {
		local comm gen
	}
	else {
		local comm replace
	}
	if ("`comm'"=="gen" | "`replace'"=="replace") {
		`comm' `varname' = (X`f'==2)*52/12+(X`f'==3)*26/12+(X`f'==4)+(X`f'==5)/3 ///
			+(X`f'==6)/12+(X`f'==11)/6+(X`f'==12)/2+(X`f'==31)*2 ///
			+(X`f'==23)*13/12+(X`f'==24)*52/(6*12)
	}
	else {
		di as error "variable `varname' already exists"
		error(1)
	}

end

capture: program drop addPeriodic
program define addPeriodic

	syntax anything(name=varname) [if], Vars(numlist integer) [MINimum(real 0) MULTiplier(real 12)]
	
	tempvar avar
	capture: confirm var `varname'
	if (_rc~=0) {
		gen `varname' = 0
	}
	foreach f of numlist `vars' {
		mconv `avar', f(`=`f'+1') replace
		replace `varname' = `varname'+max(`minimum', (X`f'*`avar')*`multiplier') `if'
	}

end

capture: program drop getGlobals
program define getGlobals, rclass

	syntax anything(name=year) [, CPIbase(real 0)]
	
	if (`year'==1989) {
		return local PIID = "XX1"
		return local PID = "X1"
		return local IID = "XX1"
		return local ID = "X1"
		local curbase 1901
		return scalar CPILAG = 1886/1807
	}
	else {
		return local PIID = "YY1"
		return local PID = "Y1"
		return local IID = "YY1"
		return local ID = "Y1"
	}
	*
	*	NOTE: CPI data from https://www.bls.gov/cpi/research-series-allitems.pdf
	*	curbase is September of year
	*	cpilag is year average / previous year average
	*
	if (`year'==1992) {
		local curbase 2115
		return scalar CPILAG = 2102/2051
	}
	if (`year'==1995) {
		local curbase 2265
		return scalar CPILAG = 2253/2200
	}
	if (`year'==1998) {
		local curbase 2404
		return scalar CPILAG = 2395/2363
	}
	if (`year'==2001) {
		local curbase 2618
		return scalar CPILAG = 2601/2529
	}
	if (`year'==2004) {
		local curbase 2789
		return scalar CPILAG = 2775/2702
	}
	if (`year'==2007) {
		local curbase 3063
		return scalar CPILAG = 3046/2962
	}
	if (`year'==2010) {
		local curbase 3209
		return scalar CPILAG = 3203/3152
	}
	if (`year'==2013) {
		local curbase 3440
		return scalar CPILAG = 3422/3373
	}
	if (`year'==2016) {
		local curbase 3547
		return scalar CPILAG = 3526/3482
	}
	
	if (`cpibase'==0) {
		local cpibase `curbase'
	}
	return scalar CPIADJ = `cpibase'/`curbase'
	return scalar CPIBASE = `cpibase'

end

capture: program drop addDemographic
program define addDemographic

	args year
	
	*	sex of household head
	clonevar HHSEX = X8021
	lab def HHSEX 0 "Inap." 1 "MALE" 2 "FEMALE"
	lab val HHSEX HHSEX
	
	*	age of household head, and categorical variable
	clonevar AGE = X14
	notes AGE: TOP-CODED AT 95
	
	gen byte AGECL = 1
	lab def AGECL 1 "<35"
	local alev 1
	forvalues aa=35(10)75 {
		local ++alev
		replace AGECL = AGECL+1 if AGE>=`aa'
		lab def AGECL `alev' "`aa'-`=`aa'+9'", add
	}
	lab def AGECL `alev' "75+", modify
	lab val AGECL AGECL
	lab var AGECL "`: var lab AGE', categorical"
	
	*	education of the HH head and categorical variable
	if (`year'>=2016) {
		clonevar EDUC = X5931
		gen byte EDCL = cond(inrange(EDUC,12,15),4, ///
			cond(inrange(EDUC,9,11),3, ///
			cond(inrange(X5932,1,2) | EDUC==8,2,1)))
	}
	else {
		gen byte EDUC = cond( ///
			X5901==-1, -1, cond( ///
			inrange(X5901,1,4), 1, cond( ///
			inrange(X5901,5,6), 2, cond( ///
			inrange(X5901,7,8), 3, cond( ///
			X5901==9, 4, cond( ///
			X5901==10, 5, cond( ///
			X5901==11, 6, cond( ///
			X5901==12 & inlist(X5902,0,5), 7, cond( ///
			X5901==12 & inlist(X5902,1,2), 8, cond( ///
			X5901>=13 & X5904==5, 9, cond( ///
			inrange(X5901,13,15) & X5905==11, 10, cond( ///
			X5901>=13 & inlist(X5905,1,10), 11, cond( ///
			(X5901>=13 & X5905==2) | (X5901==16 & X5905==11), 12, cond( ///
			(X5901>=13 & inlist(X5905,3,9)) | (X5901==17 & X5905==11), 13, cond( ///
			X5901>=13 & inlist(X5905,5,6), 14, cond( ///
			X5901>=13 & inlist(X5905,4,12), 15, .))))))))))))))))
		gen byte EDCL = cond(inrange(EDUC,12,15),4, ///
			cond(inrange(EDUC,9,11),3, ///
			cond(inrange(X5902,1,2),2,1)))
			
	}
	lab def EDUC -1 "Less than 1st grade" 0 "Inap. (no spouse/partner)" ///
		1 "1st, 2nd, 3rd, or 4th grade" 2 "5th or 6th grade" 3 "7th or 8th grade"
	forvalues gg=9/11 {
		lab def EDUC `=`gg'-5' "`gg'th grade", add
	}
	lab def EDUC 7 "12th grade, no diploma" 8 "High school graduate (or equivalent)" ///
		9 "Some college but no degree" 10 "Associate degree (occupational/vocational)" ///
		11 "Associate degree (academic)" 12 "Bachelor's degree" 13 "Master's degree" ///
		14 "Professional school degree" 15 "Doctoral degree", add
	
	lab def EDCL 1 "no high school diploma/GED" 2 "high school diploma or GED" ///
		3 "some college" 4 "college degree"
	lab val EDCL EDCL
	lab var EDCL "`: var lab EDUC', categorical"
		
	*	marital status of the HH head
	gen byte MARRIED = cond(inlist(X8023,1,2),1,2)
	lab def MARRIED 1 "married/living with partner" 2 "neither married nor living with partner"
	lab val MARRIED MARRIED
	lab var MARRIED "`: var lab X8023', categorical"

	*   number of children (including natural children/step-children/
	*	foster children of head/spouse/partner)
	gen byte KIDS = 0
	forvalues ii=108(6)132 {
		replace KIDS = KIDS+inlist(X`ii',4,13,36)
	}
	forvalues ii=202(6)226 {
		capture: replace KIDS = KIDS+inlist(X`ii',4,13,36)
	}
	lab var KIDS "number of children"
	notes KIDS: from 1995 forward, household listing information collected for one fewer HH member
	notes KIDS: code 36, foster child not available in the public data set
	
	*   labor force participation
	gen byte LF = cond((X4100>=50 & X4100<=80)|(X4100==97),0,1)
	lab def LF 0 "not working at all" 1 "working in some way"
	lab val LF LF
	lab var LF "labor force participation"
	notes LF: recode of X4100
	
	*	life cycle variables
	gen byte LIFECL = cond(AGE<55, ///
		cond(KIDS==0,cond(MARRIED~=1,1,2),cond(MARRIED==1,3,4)), ///
		cond(LF==1,5,6))
	lab def LIFECL 1 "head under 55 + not married/LWP + no children" ///
		2 "head under 55 + married/LWP + no children" ///
		3 "head under 55 + married/LWP + children" ///
		4 "head under 55 + not married/LWP + children" ///
		5 "head 55 or older and working" ///
		6 "head 55 or older and not working"
	lab val LIFECL LIFECL
	lab var LIFECL "life cycle variables"
	notes LIFECL: recode of AGE, KIDS, and LF
	
	*	family structure
	gen byte FAMSTRUCT = cond(MARRIED~=1, ///
		cond(KIDS>0, 1, cond(AGE<55, 2, 3)), ///
		cond(KIDS>0, 4, 5))
	lab def FAMSTRUCT 1 "not married/LWP + children" ///
		2 "not married/LWP + no children + head under 55"  ///
		3 "not married/LWP + no children + head 55 or older" ///
		4 "married/LWP + children" ///
		5 "married/LWP + no children"
	lab val FAMSTRUCT FAMSTRUCT
	lab var FAMSTRUCT "family structure"
	notes FAMSTRUCT: recode of AGE, KIDS, and MARRIED
	
	*	race/ethnicity
	if (`year'>=1998) {
		gen byte RACECL = 1+(X6809~=1 | X6810~=5)	
		gen byte RACECL4 = (X6809==1 & X6810==5) + 2*(X6809==2 & X6810==5) ///
			+ 3*(X6809==3 & X6810==5) + 4*(X6809==-7 | X6810==1)
		gen byte RACE = X6809
		replace RACE = 5 if ~inlist(RACE,1,2,3,4)
	}
	else {
		gen byte RACECL = 1+(X5909~=5)
		gen byte RACECL4= (X5909==5) + 2*(X5909==4) + 3*(X5909==3) + 4*(X5909<=2)
		gen byte RACE = 6-X5909
		replace RACE = 5 if ~inlist(RACE,1,2,3,4)
	}
	lab def RACECL 1 "white non-Hispanic" 2 "nonwhite or Hispanic"
	lab def RACE 1 "white non-Hispanic" 2 "black/African-American" ///
		3 "Hispanic" 5 "other"
	lab val RACECL RACECL
	lab val RACE RACE
	lab var RACE "race/ethnicity"
	lab var RACECL "race/ethnicity, categorical"
	clonevar H_RACECL = RACECL
	clonevar H_RACE = RACE
	if (`year'>=2004) {
		replace H_RACECL = 1+(X6809~=1 | X6810~=5 | X7004==1)
		replace H_RACE = 3 if X6809<4 & X7004==1
	}
	
	*	work status categories for head
	gen byte OCCAT1 = cond(X4106==1, 1, ///
		cond(inlist(X4106,2,3,4), 2, ///
		cond(inlist(X4100,50,52) ///
			| (inlist(X4100,21,23,30,70,80,97,85,-7) & AGE>=65), 3, ///
		cond(X14<65, 4, .a))))
	lab def OCCAT1 1 "work for someone else" 2 "self-employed/partnership" ///
		3 "retired/disabled + (student/homemaker/misc. not working and age 65 or older)" ///
		4 "other groups not working" .a "ERROR: UNCLASSIFIED WORK STATUS"
	lab val OCCAT1 OCCAT1
	lab var OCCAT1 "work status categories for head"
	
	*	occupation classification for head
	recode X7401 (1=1 "mangerial/professional") (2/3=2 "technical/sales/services") ///
		(4/6=3 "other") (0=4 "not working"), gen(OCCAT2)
	lab var OCCAT2 "occupation classification for head"
	
	*	industry classifications for head
	gen byte INDCAT = cond(OCCAT1>=3, 4, cond(inlist(X7402,2,3), 1, 2))
	lab def INDCAT 1 "mining + construction + manufacturing" 2 "other"
	lab val INDCAT INDCAT
	lab var INDCAT "industry classifications for head"
	notes INDCAT: recode of OCCAT1 and X7402
	
	*	Census regions and Urbanicity
	*	Not available in the public version the of dataset
	
	*	Annualized food spending
	gen FOODHOME = 0
	gen FOODAWAY = 0
	gen FOODDELV = 0
	if (`year'>=2004) {
		addPeriodic FOODHOME, v(3024)
		addPeriodic FOODAWAY, v(3029)
		addPeriodic FOODDELV, v(3027)
	}
	foreach var of varlist FOODHOME-FOODDELV {
		notes `var': not asked prior to 2004
	}
	
end

capture: program drop addIncome
program define addIncome

	syntax anything(name=year) [, ADJINC CPILAG(real 1)]
	
	*	HH income in previous calendar year
	recode X5729 min/0=0, gen(INCOME)
	lab var INCOME "HH income in previous calendar year"
	notes INCOME: For 2004 forward, IRA and withdrawals from tax-deferred pension accounts added to INCOME 
	
	*	HH income components in previous calendar year
	clonevar WAGEINC=X5702
	gen BUSSEFARMINC=X5704+X5714
	gen INTDIVINC=X5706+X5708+X5710
	clonevar KGINC=X5712
	clonevar SSRETINC=X5722
	gen TRANSFOTHINC=X5716+X5718+X5720+X5724
	clonevar RENTINC=X5714
	gen PENACCTWD = 0
	if (`year'>=2004) {
		local l1 6489
		local l2 6995
		if (`year'>=2010) {
			local l1 6479
			local l2 6983
		}
		replace PENACCTWD=X6558+X6566+X6574
		addPeriodic PENACCTWD, v(6464(5)`l1' 6965(6)`l2')
		replace INCOME=INCOME+PENACCTWD
		replace SSRETINC=SSRETINC+PENACCTWD
		lab var PENACCTWD "HH income: withdrawals from IRAs and tax-deferred pension accounts"
		notes PENACCTWD: already included prior to 2004

	}
	lab var BUSSEFARMINC "HH income: business, self-employment, and farm"
	lab var INTDIVINC "HH income: interest and dividends"
	lab var TRANSFOTHINC "HH income: transfers and other income"
	
	*	normal income
	clonevar NORMINC=INCOME
	if (`year'>=1995) {
		replace NORMINC=max(0,X7362) if X7650~=3
		if (`year'>=2004) {
			replace NORMINC=NORMINC+PENACCTWD if X7650~=3
		}
	}
	else {
		replace NORMINC=.b
	}
	lab var NORMINC "normal income"
	
	*   if ADJINC=YES, adjust actual/normal income to level of survey year
	if ("`adjinc'"=="adjinc") {
		foreach var of varlist INCOME-RENTINC {
			replace `var'=`var'*`cpilag'
			notes `var': adjusted for inflation to survey year
		}
		if (`year'>=1995) {
			replace NORMINC=NORMINC*`cpilag'
			notes NORMINC: adjusted for inflation to survey year
		}
	}
		
end

capture: program drop addAttitudinal
program define addAttitudinal

	args year
	
	*	adjusting for durables purchases/investments, spent
	*	more/same/less than income in past year
	if (`year'>=1992) {
		gen byte WSAVED=cond(X7508>0, X7508, ///
			cond(X7510==2 & X7509==1, 3, X7510))
		gen byte SAVED=(WSAVED==3)

		lab def WSAVED 1 "spending exceeded income" 2 "spending equaled income" ///
			3 "spending less than income"
		lab val WSAVED WSAVED
		lab def SAVED 1 "spent less than income" 0 "all others"
		lab val SAVED SAVED
		lab var WSAVED "adjusting for durables purchases/investments, spent more/same/less than income in past year"
		lab var SAVED "adjusting for durables purchases/investments, spent less than income in past year"

	}
	
	*	reasons for saving
	egen byte SAVRES1 = anymatch(X3006), v(-2 -1)
	egen byte SAVRES2 = anymatch(X3006), v(1 2)
	egen byte SAVRES3 = anymatch(X3006), v(3 5 6)
	egen byte SAVRES4 = anymatch(X3006), v(11)
	egen byte SAVRES5 = anymatch(X3006), v(12/16 27 29 30 9 18 20 41)
	egen byte SAVRES6 = anymatch(X3006), v(17 22)
	egen byte SAVRES7 = anymatch(X3006), v(23/25 32 92 93)
	egen byte SAVRES8 = anymatch(X3006), v(21 26 28)
	egen byte SAVRES9 = anymatch(X3006), v(31 33 40 90 91 -7)

	lab def SAVRES 1 "is most important reason for saving" 0 "is not most important reason for saving"
	lab val SAVRES1-SAVRES9 SAVRES
	lab var SAVRES1 "reason for saving: can't save"
	lab var SAVRES2 "reason for saving: education"
	lab var SAVRES3 "reason for saving: family"
	lab var SAVRES4 "reason for saving: home"
	lab var SAVRES5 "reason for saving: purchases"
	lab var SAVRES6 "reason for saving: retirement"
	lab var SAVRES7 "reason for saving: liquidity/the future"
	lab var SAVRES8 "reason for saving: investment"
	lab var SAVRES9 "reason for saving: no particular reason"
	
	foreach var of varlist SAVRES1-SAVRES9 {
		notes `var': recode of X3007
	}
	
	*	R would spend more if assets appreciated in value
	if (`year'>=1998) {
		clonevar SPENDMOR=X6789
		lab def SPENDMOR 1 "agree strongly" 2 "agree somewhat" ///
			3 "neither agree nor disagree" 4 "disagree somewhat" 5 "disagree strongly"
		lab val SPENDMOR SPENDMOR
	}

	*	R would spend less if assets depreciated in value
	if (`year'>=2010) {
		clonevar SPENDLESS=X7492
		lab def SPENDLESS 1 "agree strongly" 2 "agree somewhat" ///
			3 "neither agree nor disagree" 4 "disagree somewhat" 5 "disagree strongly"
		lab val SPENDLESS SPENDLESS
	}
	
	*   Households overall expenses over last 12 months
	if (`year'>=2010) {
		clonevar EXPENSHILO=X7491
		lab def EXPENSHILO 1 "unusually high" 2 "unusually low" 3 "normal"
		lab val EXPENSHILO EXPENSHILO
	}
	
	*	household had any late payments in last year
	gen byte LATE:YESNO=(X3004==5)
	lab var LATE "Has household had any late payments in last year?"
	
	*   household had any payments more than 60 days past due in last year
	gen byte LATE60:YESNO=(X3005==1)
	lab var LATE60 "Has household had any payments more than 60 days past due in last year?"
		
	*	have a payday loan
	gen byte HPAYDAY:YESNO = 0
	if (`year'>=2007) {
		replace HPAYDAY=(X7063==1)
	}
	lab var HPAYDAY "Has a payday loan?"
	
	*	bankruptcy in the last five years
	gen byte BNKRUPLAST5:YESNO = 0
	if (`year'>=1998) {
		replace BNKRUPLAST5=(X6774>=`year'-5)
	}
	lab var BNKRUPLAST5 "Has a bankruptcy in the last five years?"
	
	*	PEU knowledge of personal finance
	if (`year'>=2016) {
		clonevar KNOWL = X7556
	}
	else {
		gen byte KNOWL = 0
	}
	lab def KNOWL -1 "Not at all knowledgeable" 0 "Not asked" 10 "Very knowledgeable"
	lab var KNOWL "Knowledge of personal finance?"
	*	PEU willing to take fin risk
	gen byte YESFINRISK:YESNO = (X3014==1)
	gen byte NOFINRISK:YESNO = (X3014==4)
	lab var YESFINRISK "Willing to take SUBSTANTIAL financial risk wen saving?"
	lab var NOFINRISK "NOT willing to take financial risk saving?"
	notes YESFINRISK: recode of X3014
	notes NOFINRISK: recode of X3014
	
	*	credit application
	
	gen byte CRDAPP:YESNO = 0
	gen byte TURNDOWN:YESNO = X407==1
	gen byte FEARDENIAL:YESNO = X409==1
	if (`year'>=1995) {
		if (`year'>=2016) {
			forvalues ii=433/440 {
				replace CRDAPP = 1 if X`ii'==1
			}
			replace FEARDENIAL = X441==3 | X409==1
		}
		else {
			replace CRDAPP = X7131==1
		}
	}
	gen byte TURNFEAR:YESNO = TURNDOWN==1 | FEARDENIAL==1
	lab var CRDAPP "Has applied for any credit in past 12 months?"
	lab var TURNDOWN "Has been turned down for credit?"
	lab var FEARDENIAL "Has feared denial of credit?"
	lab var TURNFEAR "Has been turned down for, or feared denial of credit?"
	notes CRDAPP: 5 year lookback prior to 2016
	notes TURNDOWN: recode of X407
	notes TURNDOWN: 5 year lookback prior to 2016
	notes FEARDENIAL: recode of X409
	notes FEARDENIAL: 5 year lookback prior to 2016
	notes TURNFEAR: recode of X407 and X409
	notes TURNFEAR: 5 year lookback prior to 2016
	
	*	foreclosure
	gen byte FORECLLAST5:YESNO = 0
	if (`year'>=2016) {
		replace FORECLLAST5 = X3033>=`year'-5
	}
	lab var FORECLLAST5 "Foreclosed on in last five years?"
	notes FORECLLAST5: recode of X3033
	
	*	if experience a financial emergency, how would deal with it?
	gen byte EMERGBORR:YESNO = 0
	gen byte EMERGSAV:YESNO = 0
	gen byte EMERGPSTP:YESNO = 0
	gen byte EMERGCUT:YESNO = 0
	if (`year'>=2016) {
		replace EMERGBORR = X7775==1
		replace EMERGSAV = X7775==2
		replace EMERGPSTP = X7775==3
		replace EMERGCUT = X7775==4
	}
	lab var EMERGBORR "BORROW FROM OTHERS to deal with financial emergency?"
	lab var EMERGSAV "SPEND FROM OWN SAVINGS to deal with financial emergency?"
	lab var EMERGPSTP "POSTPONE PAYMENTS to deal with financial emergency?"
	lab var EMERGCUT "CUT BACK SPENDING to deal with financial emergency?"
	*	If borrow, would it be...
	gen byte HBORRFF:YESNO = 0
	gen byte HBORRCC:YESNO = 0
	gen byte HBORRALT:YESNO = 0
	gen byte HBORRFIN:YESNO = 0
	if (`year'>=2016) {
		replace HBORRFF = inrange(X7776,1,2) | inrange(X7777,1,2)
		replace HBORRCC = inrange(X7776,3,3) | inrange(X7777,3,3)
		replace HBORRALT = inrange(X7776,4,9) | inrange(X7777,4,9)
		replace HBORRFIN = inrange(X7776,10,11) | inrange(X7777,10,11)
	}
	lab var HBORRFF "If borrow, from FRIEND/FAMILY?"
	lab var HBORRCC "If borrow, from CREDIT CARD?"
	lab var HBORRALT "If borrow, from ALTERNATIVE SOURCE?"
	lab var HBORRFIN "If borrow, from FINANCIAL SERVICES?"
	*	If spend out of savings, would it be...
	gen byte HSAVFIN:YESNO = 0
	gen byte HSAVNFIN:YESNO = 0
	if (`year'>=2016) {
		replace HSAVFIN = inlist(X7778,1,2,4) | inlist(X7779,1,2,4)
		replace HSAVNFIN = inlist(X7778,3,5,6,7,8,9) | inlist(X7779,3,5,6,7,8,9)
	}
	lab var HSAVFIN "If spend, from OWN FINANCIAL ACCOUNTS?"
	lab var HSAVNFIN "If spend, from NONFINANCIAL SERVICES?"
	*	If postpone payments, would it be...
	gen byte HPSTPPAY:YESNO = 0
	gen byte HPSTPLN:YESNO = 0
	gen byte HPSTPOTH:YESNO = 0
	if (`year'>=2016) {
		replace HPSTPPAY = inrange(X7780,1,3) | inrange(X7781,1,3)
		replace HPSTPLN = inrange(X7780,7,11) | inrange(X7781,7,11)
		replace HPSTPOTH = inrange(X7780,4,6) | inrange(X7781,4,6)
	}
	lab var HPSTPPAY "If postpone payments, for PURCHASES?"
	lab var HPSTPLN "If postpone payments, for LOANS?"
	lab var HPSTPOTH "If postpone payments, for OTHER PAYMENTS?"
	*	If cut back, would it be...
	gen byte HCUTFOOD = 0
	gen byte HCUTENT = 0
	gen byte HCUTOTH = 0
	if (`year'>=2016) {
		replace HCUTFOOD = inrange(X7782,1,2) | inrange(X7783,1,2)
		replace HCUTENT = inrange(X7782,3,4) | inrange(X7783,3,4)
		replace HCUTOTH = inrange(X7782,5,8) | inrange(X7783,5,8)
	}
	lab var HCUTFOOD "If cut back, on FOOD PURCHASES?"
	lab var HCUTENT "If cut back, on ENTERTAINMENT?"
	lab var HCUTOTH "If cut back, on OTHER PURCHASES?"
	
	*	financial literacy: count number correct
	gen byte FINLIT = 0
	if (`year'>=2016) {
		replace FINLIT = (X7558==5) + (X7559==1) + (X7560==5)
	}
	lab var FINLIT "Number of correct answers given"
	
end

capture: program drop addServices
program define addServices

	args year
	
	if (`year'>=2016) {
		gen byte BSHOPNONE:YESNO=inlist(X7561,-1,1,2,3)
		notes BSHOPNONE: recode of X7561
		gen byte BSHOPGRDL:YESNO=inlist(X7561,9,10)
		notes BSHOPGRDL: recode of X7561
		gen byte BSHOPMODR:YESNO=inlist(X7561,4,5,6,7,8)
		notes BSHOPMODR: recode of X7561
		gen byte ISHOPNONE:YESNO=inlist(X7562,-1,1,2,3)
		notes ISHOPNONE: recode of X7562
		gen byte ISHOPGRDL:YESNO=inlist(X7562,9,10)
		notes ISHOPGRDL: recode of X7562
		gen byte ISHOPMODR:YESNO=inlist(X7562,4,5,6,7,8)
		notes ISHOPMODR: recode of X7562
	}
	else {
		gen byte BSHOPNONE:YESNO=(X7100==1)
		notes BSHOPNONE: recode of X7100
		gen byte BSHOPGRDL:YESNO=(X7100==5)
		notes BSHOPGRDL: recode of X7100
		gen byte BSHOPMODR:YESNO=inlist(X7100,2,3,4)
		notes BSHOPMODR: recode of X7100
		gen byte ISHOPNONE:YESNO=(X7111==1)
		notes ISHOPNONE: recode of X7111
		gen byte ISHOPGRDL:YESNO=(X7111==5)
		notes ISHOPGRDL: recode of X7111
		gen byte ISHOPMODR:YESNO=inlist(X7111,2,3,4)
		notes ISHOPMODR: recode of X7111
	}
	lab var BSHOPNONE "ALMOST NO SEARCHING for best terms of credit?"
	lab var BSHOPGRDL "A GREAT DEAL OF SEARCHING for best terms of credit?"
	lab var BSHOPMODR "MODERATE SEARCHING for best terms of credit?"
	lab var ISHOPNONE "ALMOST NO SEARCHING for best terms of saving?"
	lab var ISHOPGRDL "A GREAT DEAL OF SEARCHING for best terms of saving?"
	lab var ISHOPMODR "MODERATE SEARCHING for best terms of saving?"
	
	*	information sources used in borrowing and investment
	if (`year'>=1998) {
		local blist X7101 X7102 X7103 X7104 X7105 X7106 X7107 X7108 X7109 X7110 X6849
		local ilist X7112 X7113 X7114 X7115 X7116 X7117 X7118 X7119 X7120 X7121
		if (`year'>1998) {
			local blist `blist' X6861 X6862 X6863 X6864
			local ilist `ilist' X6865 X6866 X6867 X6868 X6869
		}
		
		egen byte BCALL = anymatch(`blist'), v(1)
		egen byte BMAGZNEWS = anymatch(`blist'), v(2)
		egen byte BMAILADTV = anymatch(`blist'), v(3 6 4 32)
		egen byte BINTERNET = anymatch(`blist'), v(5)
		egen byte BFRIENDWORK = anymatch(`blist'), v(7 18)
		egen byte BFINPRO = anymatch(`blist'), v(10 11 20 21 23 24)
		egen byte BFINPLAN = anymatch(`blist'), v(8 9 12)
		egen byte BSELF = anymatch(`blist'), v(13 17 19 22)
		egen byte BDONT = anymatch(`blist'), v(14 16)
		egen byte BOTHER = anymatch(`blist'), v(-7)
		
		egen byte ICALL = anymatch(`ilist'), v(1)
		egen byte IMAGZNEWS = anymatch(`ilist'), v(2)
		egen byte IMAILADTV = anymatch(`ilist'), v(3 6 4 32)
		egen byte IINTERNET = anymatch(`ilist'), v(5)
		egen byte IFRIENDWORK = anymatch(`ilist'), v(7 18 19)
		egen byte IFINPRO = anymatch(`ilist'), v(10 11 20 23 24 25)
		egen byte IFINPLAN = anymatch(`ilist'), v(8 9 12)
		egen byte ISELF = anymatch(`ilist'), v(13 17 21 22)
		egen byte IDONT = anymatch(`ilist'), v(14 16)
		egen byte IOTHER = anymatch(`ilist'), v(-7)
		
	}
	else {
		foreach var in CALL MAGZNEWS MAILADTV INTERNET FRIENDWORK ///
				FINPRO FINPLAN SELF DONT OTHER {
			gen byte B`var' = 0
			gen byte I`var' = 0
		}
	}
	
	foreach var in CALL MAGZNEWS MAILADTV INTERNET FRIENDWORK ///
			FINPRO FINPLAN SELF DONT OTHER {
		lab val B`var' I`var' YESNO
		lab var B`var' "Is `var' an information source used in borrowing"
		lab var I`var' "Is `var' an information source used in investment"
	}

	local ilist X6600 X6601 X6602 X6603 X6604 X6605 X6606 X6607 ///
		X6608 X6609 X6610 X6611 X6612 X6613 X6614 X6615 ///
		X6616 X6617 X6618 X6619 X6620 X6621 X6622 X6623 ///
		X6624 X6625 X6626 X6627 X6628 X6629 X6630 X6631 ///
		X6632 X6633 X6634 X6635 X6636 X6637 X6638 X6639 ///
		X6640 X6641 X6642 X6643 X6644 X6645 X6646 X6647
*	if (`year'>=2004) {
		local ilist `ilist' ///
			X6870 X6871 X6872 X6873 ///
			X6874 X6875 X6876 X6877 ///
			X6878 X6879 X6880 X6881 ///
			X6882 X6883 X6884 X6885 ///
			X6886 X6887 X6888 X6889 ///
			X6890 X6891 X6892 X6893 ///
			X6656 X6657 X6658 X6659 X6660 X6661 X6662 X6663 ///
			X6894 X6895 X6896 X6897
*	}
*	egen byte INTERNET = anymatch(`ilist'), v(12)
	gen byte INTERNET = 0
	foreach ii of local ilist {
		capture: replace INTERNET = INTERNET | `ii'==12
	}
	replace INTERNET = INTERNET | (BINTERNET==1 | IINTERNET==1)
	lab val INTERNET YESNO
	lab var INTERNET "Internet is used as an information source in finances"
		
end

capture: program drop addFinAssets
program define addFinAssets

	args year
	
	*	checking accounts other than money market
	gen long CHECKING = 0
	forvalues ii=3506(4)3527 {
		replace CHECKING = CHECKING+max(0,X`ii')*(X`=`ii'+1'==5)
	}
	replace CHECKING = CHECKING+max(0,X3529)*(X3527==5)
	lab var CHECKING "amount in checking accounts other than money market"
	
	*	have any checking account
	egen HCHECK = anymatch(X3507 X3511 X3515 X3519 X3523 X3527), v(5)
*	lab val HCHECK YESNO
	lab var HCHECK "Has a checking account?"
	
	
	*	have no checking account
	gen byte NOCHK:YESNO=(X3501==5)
	lab var NOCHK "Has NO checking account?"
	notes NOCHK: recode of X3501
	notes NOCHK: NOCHK=0 may include instances where R has a money market account that is used for checking

	*   people w/o checking accounts: ever had an account?
	clonevar EHCHKG=X3502
	lab def EHCHKG 1 "Yes" 5 "No"
	lab val EHCHK EHCHK

	*   people w/o checking accounts: why have no account?
	clonevar WHYNOCKG=X3503
/*
	lab def WHYNOCKG 1 "don't write enough checks to make it worthwhile" ///
		2 "minimum balance is too high" 3 "do not like dealing with banks" ///
		4 "service charges are too high" 5 "no bank has convenient hours or location" ///
		12 "checkbook has been/could be lost/stolen" 13 "haven't gotten around to it" ///
		14 "R has alternative source of checking services" ///
		15 "R not allowed to have account" ///
		20 "R does not need/want a checking account (NEC)" ///
		21 "credit problems, bankruptcy, R does not meet qualifications" ///
		95 "don't have (enough) money" -1 "can't manage/balance a checking account" ///
		-7 "other" 0 "inapplicable. (R has a checking account: X3501=1)"
*/
	notes WHYNOCKG: codeframe varies over the survey years, so beware of constructing overly specific comparisons of the distribution of households over these categories over time
	
	gen byte DONTWRIT = WHYNOCKG==1
	gen byte MINBAL = WHYNOCKG==2
	gen byte DONTLIKE = WHYNOCKG==3
	gen byte SVCCHG = WHYNOCKG==4
	gen byte NOMONEY = WHYNOCKG==95
	if (`year'<=1992) {
		gen byte CANTMANG = WHYNOCKG==96
		gen byte CREDIT = .
		gen byte DONTWANT = .
		gen byte OTHER = ~inlist(WHYNOCKG,0,1,2,3,4,95,96,21,20)
	}
	else {
		gen byte CANTMANG = WHYNOCKG==-1
		gen byte CREDIT = WHYNOCKG==21
		gen byte DONTWANT = WHYNOCKG==20
		gen byte OTHER = ~inlist(WHYNOCKG,0,1,2,3,4,-1,95,21,20)
	}
	lab val DONTWRIT-OTHER YESNO
	lab var DONTWRIT "reason for no checking account: don't write enough checks"
	lab var MINBAL "reason for no checking account: minimum balance too high"
	lab var DONTLIKE "reason for no checking account: do not like banks"
	lab var SVCCHG "reason for no checking account: service charges too high"
	lab var NOMONEY "reason for no checking account: don't have enough money"
	lab var CANTMANG "reason for no checking account: can't manage/balance account"
	lab var CREDIT "reason for no checking account: credit problems"
	lab var DONTWANT "reason for no checking account: does not need account"
	lab var OTHER "reason for no checking account: other"
	
	*	reason chose main chacking institution
	gen byte CKLOCATION = X3530==3
	gen byte CKLOWFEEBAL = X3530==7
	gen byte CKMANYSVCS = X3530==6
	gen byte CKRECOMFRND = X3530==1
	gen byte CKPERSONAL = X3530==11
	gen byte CKCONNECTN = X3530==35
	gen byte CKLONGTIME = X3530==14
	gen byte CKSAFETY = X3530==8
	gen byte CKCONVPAYRL = X3530==9
	gen byte CKOTHCHOOSE = ~inlist(X3530,0,3,7,6,1,11,35,14,8,9)
	lab val CKLOCATION-CKOTHCHOOSE YESNO
	lab var CKLOCATION "reason chose main checking: location"
	lab var CKLOWFEEBAL "reason chose main checking: lowest fees/min balance"
	lab var CKMANYSVCS "reason chose main checking: many services"
	lab var CKRECOMFRND "reason chose main checking: recommended"
	lab var CKPERSONAL "reason chose main checking: personal relationship"
	lab var CKCONNECTN "reason chose main checking: work/school connection"
	lab var CKLONGTIME "reason chose main checking: always done business there"
	lab var CKSAFETY "reason chose main checking: safety"
	lab var CKCONVPAYRL "reason chose main checking: other convenience"
	lab var CKOTHCHOOSE "reason chose main checking: other"
	foreach var of varlist CKLOCATION-CKOTHCHOOSE {
		notes `var': from X3530
	}
	
	*	prepaid cards
	gen PREPAID = 0
	gen byte HPREPAID:YESNO = 0
	if (`year'>=2016) {
		replace PREPAID = max(0,X7596)
		replace HPREPAID = X7594==1 | X7648==1
	}
	lab var PREPAID "amount on prepaid cards"
	lab var HPREPAID "Has prepaid cards"
	notes PREPAID: new question in 2016
	notes PREPAID: new question in 2016
	
	*	savings accounts
	gen SAVING = 0
	if (`year'<=2001) {
		forvalues ii=3804(3)3816 {
			replace SAVING = SAVING+max(0,X`ii')
		}
		replace SAVING = SAVING+max(0,X3818)
	}
	else {
		forvalues ii=3730(6)3760 {
			replace SAVING = SAVING+max(0,X`ii') if ~inlist(X`=`ii'+2',4,30)
		}
		replace SAVING = SAVING+max(0,X3765)
	}
	lab var SAVING "amount in savings accounts"
	
	*	have savings account
	gen byte HSAVING=(SAVING>0)
	lab val HSAVING YESNO
	lab var HSAVING "Has savings account?"
	
	*	money market deposit accounts
	*	money market mutual funds
	gen MMDA=0
	gen MMMF=0
	local jj = 9112
	forvalues ii=3506(4)3526 {
		local ++jj
		replace MMDA = MMDA+max(0,X`ii') if X`=`ii'+1'==1 & inlist(X`jj',11,12,13)
		replace MMMF = MMMF+max(0,X`ii') if X`=`ii'+1'==1 & ~inlist(X`jj',11,12,13)
	}
	replace MMDA = MMDA+max(0,X3529) if X3527==1 & inlist(X`jj',11,12,13)
	replace MMMF = MMMF+max(0,X3529) if X3527==1 & ~inlist(X`jj',11,12,13)
	if (`year'<=2001) {
		local jj = 9130
		forvalues ii=3706(5)3716 {
			local ++jj
			replace MMDA = MMDA+max(0,X`ii') if inlist(X`jj',11,12,13)
			replace MMMF = MMMF+max(0,X`ii') if ~inlist(X`jj',11,12,13)
		}
		replace MMDA = MMDA+max(0,X3718) if inlist(X`jj',11,12,13)
		replace MMMF = MMMF+max(0,X3718) if ~inlist(X`jj',11,12,13)
	}
	else {
		local jj = 9258
		forvalues ii=3730(6)3760 {
			local ++jj
			replace MMDA = MMDA+max(0,X`ii') if inlist(X`=`ii'+2',4,30) & inlist(X`jj',11,12,13)
			replace MMMF = MMMF+max(0,X`ii') if inlist(X`=`ii'+2',4,30) & ~inlist(X`jj',11,12,13)
		}
		replace MMDA = MMDA+max(0,X3765) if inlist(X3762,4,30) & inlist(X`jj',11,12,13)
		replace MMMF = MMMF+max(0,X3765) if inlist(X3762,4,30) & ~inlist(X`jj',11,12,13)
	}
	lab var MMDA "amount in money market deposit accounts"
	lab var MMMF "amount in money market mutual funds"
	
	*	all types of money market accounts
	gen MMA = MMDA+MMMF
	lab var MMA "amount in all money market accounts"
	
	*	have any type of money market account
	gen byte HMMA=(MMA>0)
	lab val HMMA YESNO
	lab var HMMA "Has any money market account?"
	
	*	call accounts at brokerages
	gen CALL = max(0,X3930)
	lab var CALL "amount in call accounts at brokerages"
	notes CALL: recode of X3930
	
	*	have call account
	gen byte HCALL=(CALL>0)
	lab val HCALL YESNO
	lab var HCALL "Has call account?"
	
	*	all types of transaction accounts (liquid assets)
	gen LIQ=CHECKING+SAVING+MMA+CALL+PREPAID
	lab var LIQ "liquid assets: amount in transaction accounts"
	
	*	have any types of transaction accounts
	if (`year'>=2004) {
		gen byte HLIQ = LIQ>0 | X3501==1 | X3727==1 | X3929==1
	}
	else {
		gen byte HLIQ = LIQ>0 | X3501==1 | X3701==1 | X3801==1 | X3929==1
	}
	lab val HLIQ YESNO
	lab var HLIQ "Has any transaction account?"
	
	*	include accounts with zero assets (for tabling program)
	replace LIQ = max(HLIQ,LIQ)
	notes LIQ: includes at least one dollar if has account (even if all balances are zero)
	
	*	certificates of deposit
	gen CDS = max(0,X3721)
	lab var CDS "amount in certificates of deposit"
	notes CDS: recode of X3721
	
	*	have CDs
	gen byte HCDS = (CDS>0)
	lab val HCDS YESNO
	lab var HCDS "Has certificates of deposit?"
	
	*	mututal funds
	*	stock mutual funds
	gen STMUTF = (X3821==1)*max(0,X3822)
	lab var STMUTF "amount in stock mutual funds"
	*	tax-free bond mutual funds
	gen TFBMUTF = (X3823==1)*max(0,X3824)
	lab var TFBMUTF "amount in tax-free bond mutual funds"
	*	government bond mutual funds
	gen GBMUTF = (X3825==1)*max(0,X3826)
	lab var GBMUTF "amount in government bond mutual funds"
	*	other bond mutual funds
	gen OBMUTF = (X3827==1)*max(0,X3828)
	lab var OBMUTF "amount in other bond mutual funds"
	*	combination and other mutual funds
	gen COMUTF = (X3829==1)*max(0,X3830)
	lab var COMUTF "amount in combination and other mutual funds, n.e.c."
	*	total directly-held mutual funds, excluding MMMFs
	gen NMMF=STMUTF+TFBMUTF+GBMUTF+OBMUTF+COMUTF
	gen OMUTF = 0
	if (`year'>=2004) {
		*	other mutual funds
		replace OMUTF = (X7785==1)*max(0,X7787)
		replace NMMF=NMMF+OMUTF
	}
	lab var OMUTF "amount in other mutual funds, n.e.c."
	lab var NMMF "amount in all directly-held mutual funds, excluding MMMFs"
	
	*	have any mutual funds, excluding MMMFs
	gen byte HNMMF = (NMMF>0)
	lab val HNMMF YESNO
	lab var HNMMF "Has any mutual funds, excluding MMMFs?"
	
	*	stocks
	gen STOCKS=max(0,X3915)
	lab var STOCKS "amount in stocks"
	notes STOCKS: recode of X3915
	
	*	have stocks
	gen byte HSTOCKS = (STOCKS>0)
	lab val HSTOCKS YESNO
	lab var HSTOCKS "Has stocks?"
	
	*	number of different companies in which hold stock
	clonevar NSTOCKS=X3914
	
	*	Wilshire index of stock prices
	if (`year'>=1998) {
		gen WILSH = X33001
	}
	else {
		gen WILSH = .b
	}
	lab var WILSH "Wilshire index of stock prices"
	notes WILSH: missing before 1998
	
	*	bonds, not including bond funds or savings bonds
	*	tax-exempt bonds (state and local bonds)
	clonevar NOTXBND=X3910
	*	mortgage-backed bonds
	clonevar MORTBND=X3906
	*	US government and government agency bonds and bills
	clonevar GOVTBND=X3908
	*	corporate and foreign bonds
	if (`year'>=1992) {
		gen OBND = X7634+X7633
		lab var OBND "amount in corporate and foreign bonds"
		notes OBND: before 1992, clone of X3912
	}
	else {
		clonevar OBND=X3912
		notes OBND: after 1989, X7634 and X7633
	}
	*	total bonds, not including bond funds or savings bonds
	gen BOND=NOTXBND+MORTBND+GOVTBND+OBND
	lab var BOND "total amount in bonds, not including bond funds or savings bonds"
	*	have bonds
	gen byte HBOND=(BOND>0)
	lab val HBOND YESNO
	lab var HBOND "Has bonds?"
	
	*	quasi-liquid retirement accounts (IRAs and thrift-type accounts)
	*	individual retirement accounts/Keoghs
	gen IRAKH = 0
	if (`year'>=2004) {
		forvalues ii=6551(8)6567 {
			forvalues jj=`ii'/`=`ii'+3' {
				replace IRAKH = IRAKH+X`jj'
			}
		}
	}
	else {
		forvalues ii=3610(10)3630 {
			replace IRAKH = IRAKH+max(0,X`ii')
		}
	}
	lab var IRAKH "amount in IRA/Keogh"
	
	tempvar HOLD PMOP RTHRIFT STHRIFT REQ SEQ
	foreach var in HOLD REQ SEQ {
		gen ``var'' = .
	}
	foreach var in `RTHRIFT' `STHRIFT' THRIFT PENEQ {
		gen `var' = 0
	}
		
	if (`year'<2004) {
		local PTYPE1 16
		local PTYPE2 16
		local PAMT 26
		local PBOR 27
		local PWIT 31
		local PALL 34

		local i1list 42 43 44
		local i2list 48 49 50
		
		local v1list 1,2,7,11,12,18
		local v2list 3
		local v3list `v1list'
		
		local mop1 4436
		local mop2 5036
	}
	else {
		local PTYPE1 00
		local PTYPE2 01
		local PAMT 32
		local PBOR 25
		local PWIT 31
		local PALL 36
		local PPCT 37
		
		local i1list 110 111
		local i2list 113 114
		
		local v1list 5,6,10,21
		local v2list 3
		
		if (`year'<2010) {
			local i1list `i1list' 112
			local i2list `i2list' 115
		}
		else {
			local v1list 1
			local v2list 3,30
		}
		local v3list 2,3,4,6,20,21,22,26
		
		local mop1 11259
		local mop2 11559
	}
	
	*	account-type pension plans (included if type is 401k, 403b,
	*	thrift, savings, SRA, or if participant has option to borrow or
	*	withdraw)
	foreach ii in `i1list' `i2list' {
		replace `HOLD' = max(0,X`ii'`PAMT')*(inlist(X`ii'`PTYPE1',`v1list') ///
			| inlist(X`ii'`PTYPE2',`v3list') ///
			| X`ii'`PBOR'==1 | X`ii'`PWIT'==1)
		if (`ii'<`:word 1 of `i2list'') {
			replace `RTHRIFT'=`RTHRIFT'+`HOLD'
		}
		else {
			replace `STHRIFT'=`STHRIFT'+`HOLD'
		}
		replace THRIFT=THRIFT+`HOLD'
		if (`year'>=2004) {
			replace PENEQ=PENEQ+`HOLD'*((X`ii'`PALL'==1) ///
				+inlist(X`ii'`PALL',`v2list')*(max(0,X`ii'`PPCT')/10000))
		}
		else {
			replace PENEQ=PENEQ+`HOLD'*((X`ii'`PALL'==1) ///
				+inlist(X`ii'`PALL',`v2list')*0.5)
		}
		if (`ii'<`:word 1 of `i2list'') {
			replace `REQ'=PENEQ
		}
		else {
			replace `SEQ'=PENEQ-`REQ'
		}
	}
	*	allocate the pension mopups;
	*	where possible, use information for first three pensions to infer
	*	characteristics of this amount;
	*	where not possible to infer whether R can borrow/make withdrawals,
	*	assume this is possible;
	*	where not possible to determine investment direction, assume half
	*	in stocks
	replace `HOLD' = 0
	foreach ii in `i1list' {
		replace `HOLD' = `HOLD' | inlist(X`ii'`PTYPE1',`v1list') ///
			| inlist(X`ii'`PTYPE2',`v3list') ///
			| X`ii'`PWIT'==1 | X`ii'`PBOR'==1
	}
	replace `HOLD' = ~`HOLD'
	foreach ii in `i1list' {
		di `ii'
		replace `HOLD' = `HOLD' & X`ii'`PTYPE1'~=0 & X`ii'`PWIT'~=0
	}
	gen `PMOP' = max(0,cond(`HOLD',0,X`mop1'))
	replace THRIFT = THRIFT+`PMOP'
	replace PENEQ=PENEQ+`PMOP'*cond(`REQ'>0,`REQ'/`RTHRIFT',0.5)
	replace `HOLD' = 0
	foreach ii in `i2list' {
		replace `HOLD' = `HOLD' | inlist(X`ii'`PTYPE1',`v1list') ///
			| inlist(X`ii'`PTYPE2',`v3list') ///
			| X`ii'`PWIT'==1 | X`ii'`PBOR'==1
	}
	replace `HOLD' = ~`HOLD'
	foreach ii in `i2list' {
		replace `HOLD' = `HOLD' & X`ii'`PTYPE1'~=0 & X`ii'`PWIT'~=0
	}
	replace `PMOP' = max(0,cond(`HOLD',0,X`mop2'))
	replace THRIFT = THRIFT+`PMOP'
	replace PENEQ=PENEQ+`PMOP'*cond(`SEQ'>0,`SEQ'/`STHRIFT',0.5)
	lab var THRIFT "amount in account-type pension plans"
	lab var PENEQ "amount (equities only) in account-type pension plans"
	/*
	di
	di	"erm?"
	di
	
	gen tcheck = 0
	gen t1 = 0
	gen domop1 = .
	gen domop2 = .
	foreach jj in 110 113 {
		replace domop1 = 0
		replace domop2 = 0
		forvalues ii=`jj'/`=`jj'+1' {
			replace t1 = X`ii'00==1 | inlist(X`ii'01,2,3,4,6,20,21,22,26) ///
				| X`ii'25==1 | X`ii'31==1
			replace domop1 = domop1 | t1
			replace domop2 = domop2 & X`ii'00~=1 & X`ii'31~=1
			replace tcheck = tcheck+max(0,X`ii'32) if t1
		}
		replace tcheck = tcheck+max(0,X`=`jj'+2'59) if domop1 | ~domop2
	}
	
		count if round(THRIFT)~=round(tcheck)
		if (`r(N)'==0) {
			notes THRIFT: THRIFT check passed at TS
		}
		else {
			notes THRIFT: THRIFT check failed at TS with `r(N)' discrepancies
			li THRIFT tcheck X11259 X11559 if round(THRIFT)~=round(tcheck)
		}

		notes THRIFT
		svy, subpop(if THRIFT>0): mean THRIFT
		svy, subpop(if tcheck>0): mean tcheck
		
		mata: ZZZ
		*/
		
	*	future pensions (accumulated in an account for the R/S)
	local imax = 5644
	if (`year'>=2010) {
		local imax = 5628
	}
	gen FUTPEN=0
	forvalues ii=5604(8)`imax' {
		replace FUTPEN=FUTPEN+max(0,X`ii')
	}
	lab var FUTPEN "amount accumulated toward future pension"
	
	*	NOTE: there is very little evidence that pensions with currently
	*	received benefits recorded in the SCFs before 2001 were any type
	*	of 401k or related account from which the R was making
	*	withdrawals:  the questions added in 2001 allow one to distinguish
	*	such account, and there are 55 of them in that year:
	*	create a second version of RETQLIQ to include this information
	local imax = 6477
	if (`year'<2010) {
		local imax = 6487
		if (`year'<2001) {
			local imax = 0
		}
	}
	gen CURRPEN=0
	forvalues ii=6462(5)`imax' {
		replace CURRPEN = CURRPEN+X`ii'
	}
	if (`year'>=2004) {
		replace CURRPEN = CURRPEN+X6957
	}
	lab var CURRPEN "amount in currently-received pension"
	gen RETQLIQ = IRAKH+THRIFT+FUTPEN+CURRPEN
	lab var RETQLIQ "total amount in quasi-liquid retirement assets"
	gen byte HRETQLIQ=(RETQLIQ>0)
	lab val HRETQLIQ YESNO
	lab var HRETQLIQ "Has quasi-liquid assets?"

	*	other pension characteristics
	egen ANYPEN=anymatch(X4135 X4735 X5313 X5601), v(1)
	lab var ANYPEN "Has any type of pension?"
		
	tempvar db1
	if (`year'>=2004) {
		local i1list X110 X111 X113 X114
		if (`year'<2010) {
			local i1list `i1list' X112 X115
		}
	}
	else {
		local i1list X42 X43 X44 X48 X49 X50
	}
	local i2list X5316 X5324 X5332 X5416
	local i3list X6461 X6466 X6471 X6476
	if (`year'<2010) {
		local i2list `i2list' X5424 X5432
		local i3list `i3list' X6481 X6486
	}
	if (`year'>=2004) {
		local i1suff 01
		local i2suff 32
		local ivals -1
	}
	else {
		local i1suff 03
		local i2suff 03
		local ivals 2 3
	}
	egen byte DBPLANCJ = anymatch(`=subinstr("`i1list'"," ","`i1suff' ",.)'`i1suff'), v(1)
	egen byte DCPLANCJ = anymatch(`=subinstr("`i1list'"," ","`i2suff' ",.)'`i2suff'), v(`ivals')
	egen byte `db1' = anymatch(`i2list'), v(1)
	if (`year'>=2001) {
		tempvar db2 dc2
		gen byte `db2' = 0
		gen byte `dc2' = 0
		forvalues ii=1/`: list sizeof i2list' {
			local i2: word `ii' of `i2list'
			local i3: word `ii' of `i3list'
			replace `db2' = 1 if `i2'==1 & `i3'==5
			replace `dc2' = 1 if `i2'==1 & `i3'==1
		}
	}
	if (`year'>=2001) {
		replace DBPLANCJ = DBPLANCJ | `db2'
		replace DCPLANCJ = DCPLANCJ | `dc2'
	}
	else {
		replace DBPLANCJ = DBPLANCJ | `db1'
	}
	if (`year'>=2004) {
		if (`year'>=2010) {
			local ival 5
		}
		else {
			local ival 4
		}
		foreach ii in `i1list' {
			replace DBPLANCJ = DBPLANCJ | (`ii'00==`ival' & `ii'01~=30)
			replace DCPLANCJ = DCPLANCJ | (`ii'32>0)
		}
	}
	lab var DBPLANCJ "Has defined-benefit pension on current job?"
	lab var DCPLANCJ "Has account-type pension on current job?"

	local i1list X5603 X5611 X5619 X5627
	local i2list X6461 X6466 X6471 X6476
	if (`year'<2010) {
		local i1list `i1list' X5635 X5643
		local i2list `i2list' X6481 X6486
	}
	egen byte DBPLANT = anymatch(`i1list'), v(1 3)
	if (`year'>=2001) {
		tempvar dt
		egen byte `dt' = anymatch(`i2list'), v(5)
		replace DBPLANT = DBPLANT | `dt'
	}
	else {
		replace DBPLANT = DBPLANT | (X5314>0)
	}
	replace DBPLANT = DBPLANT | (DBPLANCJ==1)
	lab var DBPLANT "Has any defined-benefit pension?"
	
	gen byte BPLANCJ = DBPLANCJ==1 & DCPLANCJ==1
	lab var BPLANCJ "Has both defined-benefit and account-type plans on current job?"
	
	lab val ANYPEN DBPLANCJ DCPLANCJ DBPLANT BPLANCJ YESNO
		
	*	savings bonds
	clonevar SAVBND=X3902
	*	have savings bonds
	gen byte HSAVBND = (SAVBND>0)
	lab val HSAVBND YESNO
	lab var HSAVBND "Has savings bonds?"
	
	*	cash value of whole life insurance
	gen CASHLI=max(0,X4006)
	lab var CASHLI "cash value of whole life insurance"
	notes CASHLI: recode of X4006
	*	have cash value
	gen byte HCASHLI = (CASHLI>0)
	lab val HCASHLI YESNO
	lab var HCASHLI "Has cash value of whole life insurance?"
	
	*	other managed assets (trusts, annuities and managed investment
	*	accounts in which HH has equity interest)
	if (`year'>=2004) {
		gen ANNUIT = max(0,X6577)
		gen TRUSTS = max(0,X6587)
		gen OTHMA = ANNUIT+TRUSTS
	}
	else if (`year'>=1998) {
		gen ANNUIT = max(0,X6820)
		gen TRUSTS = max(0,X6835)
		gen OTHMA = ANNUIT+TRUSTS
	}
	else {
	  gen OTHMA=max(0,X3942)
	  gen ANNUIT=((X3935==1)/max(1,((X3934==1)+(X3935==1)+(X3936==1)+(X3937==1))))*max(0,X3942)
	  gen TRUSTS=OTHMA-ANNUIT
	}
	lab var ANNUIT "amount in annuities"
	lab var TRUSTS "amount in trusts"
	lab var OTHMA "amount in other managed assets, including annuities and trusts"
	*	have other managed assets
	gen byte HOTHMA = (OTHMA>0)
	lab val HOTHMA YESNO
	lab var HOTHMA "Has other managed assets?"
	
	*	other financial assets: includes loans from the household to
	*	someone else, future proceeds, royalties, futures, non-public
	*	stock, deferred compensation, oil/gas/mineral invest., cash
	*	n.e.c.
	gen OTHFIN = X4018
	forvalues ii=4022(4)4030 {
		replace OTHFIN = OTHFIN+X`ii' if inlist(X`=`ii'-2',61,62,63,64,65,66,71,72,73,74,77,80,81,-7)
	}
	lab var OTHFIN "amount in other financial assets"
	*	have other financial assets
	gen byte HOTHFIN = (OTHFIN>0)
	lab val HOTHFIN YESNO
	lab var HOTHFIN "Has other financial assets?"
		
	*	financial assets invested in stocks
	gen EQUITY = STOCKS+STMUTF+0.5*COMUTF+PENEQ
	if (`year'>=2004) {
		replace EQUITY = EQUITY+OMUTF
		local vlist 3
		if (`year'>=2010) {
			local vlist `vlist',30
		}
		tempvar val
		gen `val' = .
		forvalues ii=6551(8)6567 {
			if (`year'>=2010) {
				replace `val' = max(0,X`=`ii'+5')
			}
			else {
				replace `val' = X`=`ii'+5'
			}
			replace EQUITY = EQUITY+(X`ii'+X`=`ii'+1'+X`=`ii'+2'+X`=`ii'+3')* ///
				((X`=`ii'+4'==1)+inlist(X`=`ii'+4',`vlist')*`val'/10000)
		}
		replace `val' = X6582
		if (`year'>=2010) {
			replace `val' = max(0,`val')
		}
		replace EQUITY = EQUITY+ANNUIT*((X6581==1)+inlist(X6581,`vlist')*`val'/10000)
		replace `val' = X6592
		if (`year'>=2010) {
			replace `val' = max(0,`val')
		}
		replace EQUITY = EQUITY+TRUSTS*((X6591==1)+inlist(X6591,`vlist')*`val'/10000)
		local nd 6
		if (`year'>=2010) {
			local nd 4
		}
		forvalues dd=0/`=`nd'-1' {
			local ii = 6461+5*`dd'
			local jj = 6933+4*`dd'
			if (`year'>=2010) {
				replace `val' = max(0,X`=`jj'+1')
			}
			else {
				replace `val' = X`=`jj'+1'
			}
			replace EQUITY = EQUITY+(X`ii'==1)*X`=`ii'+1'*((X`jj'==1) ///
				+inlist(X`jj',`vlist')*`val'/10000)
			local ii = 5604+8*`dd'
			local jj = 6962+6*`dd'
			if (`year'>=2010) {
				replace `val' = max(0,X`=`jj'+1')
			}
			else {
				replace `val' = X`=`jj'+1'
			}
			replace EQUITY = EQUITY+X`ii'*((X`jj'==1) ///
				+inlist(X`jj',`vlist')*`val'/10000)
		}
		if (`year'>=2007) {
			forvalues dd=0/5 {
				local ii = 3730+6*`dd'
				local jj = 7074+3*`dd'
				replace EQUITY = EQUITY+X`ii'*((X`jj'==1) ///
					+inlist(X`jj',`vlist')*max(0,X`=`jj'+1')/10000)
			}
		}
	}
	else {
		replace EQUITY=EQUITY+IRAKH*((X3631==2)+0.5*(X3631==5 | X3631==6)+0.3*(X3631==4))
		if (`year'>=1998) {
			replace EQUITY=EQUITY+ANNUIT*((X6826==1)+0.5*(X6826==5 | X6826==6)+0.3*(X6826==-7))
			replace EQUITY=EQUITY+TRUSTS*((X6841==1)+0.5*(X6841==5 | X6841==6)+0.3*(X6841==-7))
		}
		else {
			replace EQUITY=EQUITY+OTHMA*((X3947==1)+0.5*(X3947==5 | X3947==6)+0.3*(X3947==4 | X3947==-7))
		}
		if (`year'>=2001) {
			forvalues ii=6462(5)6487 {
				replace EQUITY=EQUITY+X`ii'*((X`=`ii'+1'==1)+0.5*(X`=`ii'+1'==3))
			}
			forvalues ii=6491/6496 {
				local jj = 5604+(`ii'-6491)*8
				replace EQUITY=EQUITY+X`jj'*((X`ii'==1)+0.5*(X`ii'==3))
			}
		}
	}
	lab var EQUITY "stock equity"
	*	have stock equity
	gen byte HEQUITY = (EQUITY>0)
	lab val HEQUITY YESNO
	lab var HEQUITY "Has stock equity?"
	
	*	equity in directly-held stocks, some types of mutual funds,
	*	combination mutual funds, and other mutual funds
	gen DEQ=STOCKS+STMUTF+0.5*COMUTF
	if (`year'>=2004) {
		replace DEQ = DEQ+OMUTF
	}
	lab var DEQ "equity in directly-held stocks, stock mutual funds, and comination mutual funds"

	*	equity in directly-held stocks, some types of mutual funds,
	*	plus equity in OTHMA, plus equity in IRAs, and C-Corps
	gen FAEQUITY = STOCKS+cond(`year'==1998,STMUTF+0.5*COMUTF,NMMF)+max(0,X3420)
	forvalues ii=31/`=32+(`year'<2010)' {
		replace FAEQUITY = FAEQUITY ///
			+(max(0,X`ii'29)+max(0,X`ii'24)-max(0,X`ii'26)*(X`ii'27==5) ///
				+max(0,X`ii'21)*inlist(X`ii'22,1,6))*(X`ii'19==4)
	}
	if (`year'>=2004) {
		forvalues ii=6555(8)6571 {
			replace FAEQUITY = FAEQUITY ///
				+(X`=`ii'-4'+X`=`ii'-3'+X`=`ii'-2'+X`=`ii'-1')*((X`ii'==1)+(X`ii'==3)*X`=`ii'+1'/10000)
		}
	}
	else {
		replace FAEQUITY = FAEQUITY ///
			+IRAKH*((X3631==2)+0.5*inlist(X3631,5,6)+0.3*(X3631==4))
	}
	if (`year'>=1998) {
		if (`year'>=2004) {
			local alist 3
			if (`year'>=2010) {
				local alist 3,30
			}
			replace FAEQUITY = FAEQUITY ///
				+ANNUIT*((X6581==1)+inlist(X6581,`alist')*max(0,X6582)/10000) ///
				+TRUSTS*((X6591==1)+inlist(X6591,`alist')*max(0,X6592)/10000)
		}
		else {
			replace FAEQUITY = FAEQUIT ///
				+ANNUIT*((X6826==1)+0.5*inlist(X6826,5,6)+0.3*inlist(X6826,-7))	///
				+TRUSTS*((X6841==1)+0.5*inlist(X6841,5,6)+0.3*inlist(X6841,-7))
		}
	}
	else {
		replace FAEQUITY = FAEQUITY ///
			+OTHMA*((X3947==1)+0.5*inlist(X3947,5,6)+0.3*inlist(X3947,4,-7))	
	}
	lab var FAEQUITY "equity in directly-held stocks, some types of mutual funds, plus equity in OTHMA, plus equity in IRAs, and C-Corps"
	
	*	equity held in savings accounts such as 529s, Coverdells or other
    *	types with investment choice
	gen SAVEQ = 0
	if (`year'>=2007) {
		forvalues ii=0/5 {
			local jj = 3730+6*`ii'
			local kk = 7074+3*`ii'
			local ll = `kk'+1
			replace SAVEQ = SAVEQ+X`jj'*((X`kk'==1)+(X`kk'==3)*(max(0,X`ll')/10000))
		}
	}
	lab var SAVEQ "equity held in savings accounts such as 529s, Coverdells or other types with investment choice"
	
	*	equity in quasi-liquid retirement assets
	gen RETEQ = PENEQ
	if (`year'<=2001) {
		replace RETEQ = RETEQ+IRAKH*((X3631==2)+0.5*inlist(X3631,5,6)+0.3*(X3631==4))
		if (`year'==2001) {
			forvalues ii=6462(5)6487 {
				replace RETEQ = RETEQ+X`ii'*((X`=`ii'+1'==1)+0.5*(X`=`ii'+1'==3))
			}
			local jj = 6491
			forvalues ii=5604(8)5644 {
				replace RETEQ = RETEQ+X`ii'*((X`jj'==1)+0.5*(X`jj'==3))
				local ++jj
			}
		}
	}
	else {
		if (`year'>=2010) {
			local peval max(0,X
			local vlist 3,30
			local dmax 3
		}
		else {
			local peval (X
			local vlist 3
			local dmax 5
		}
		local seval )
		forvalues ii=6551(8)6567 {
			replace RETEQ=RETEQ+(X`ii'+X`=`ii'+1'+X`=`ii'+2'+X`=`ii'+3')* ///
				((X`=`ii'+4'==1)+inlist(X`=`ii'+4',`vlist')*`peval'`=`ii'+5'`seval'/10000)
		}
		forvalues dd=0/`dmax' {
			local ii=6461+5*`dd'
			local jj=6933+4*`dd'
			replace RETEQ=RETEQ+(X`ii'==1)*X`=`ii'+1'* ///
				((X`jj'==1)+inlist(X`jj',`vlist')*`peval'`=`jj'+1'`seval'/10000)
		}
		forvalues dd=0/`dmax' {
			local ii=5604+8*`dd'
			local jj=6962+6*`dd'
			replace RETEQ=RETEQ+X`ii'* ///
				((X`jj'==1)+inlist(X`jj',`vlist')*`peval'`=`jj'+1'`seval'/10000)
		}
	}
	lab var RETEQ "equity in quasi-liquid retirement assets"
	
	*	ratio of equity to normal income
	gen EQUITINC = EQUITY/max(100,NORMINC) if `year'>=1995
	lab var EQUITINC "ratio of equity to normal income"
	
	*	brokerage account info
	*	have a brokerage account
	gen byte HBROK = (X3923==1)
	lab val HBROK YESNO
	lab var HBROK "Has brokerage account?"
	notes HBROK: recode of X3923
	
	*	traded in the past year
	gen byte HTRAD = (X3928>0)
	lab val HTRAD YESNO
	lab var HTRAD "Has traded in the past year?"
	notes HTRAD: recode of X3928
	
	*	number of trades per year
	gen NTRAD=max(0,X3928)
	if (`year'>=1995) {
		gen PTRAD = (X7193==1)*250 + (X7193==2)*52 + (X7193==3)*26 + (X7193==4)*12 ///
			+ (X7193==5)*4 + (X7193==6) + (X7193==8) + (X7193==11)*2 ///
			+ (X7193==12)*6 + (X7193==18)*8*250 + (X7193==25)/2
		notes PTRAD: recode of X7193
		replace NTRAD = NTRAD*PTRAD
	}
	lab var NTRAD "number of trades per year"
	
	*	total financial assets
	gen FIN=LIQ+CDS+NMMF+STOCKS+BOND+RETQLIQ+SAVBND+CASHLI+OTHMA+OTHFIN+PREPAID
	lab var FIN "total financial assets"
	*   have any financial assets
	gen byte HFIN=(FIN>0)
	lab val HFIN YESNO
	lab var HFIN "Has any financial assets?"

end

capture: program drop addNonFinAssets
program define addNonFinAssets

	args year
		
	*	value of all vehicles (includes autos, motor homes, RVs, airplanes,
	*	boats)
	local ilist 8166 8167 8168 2422 2506 2606 2623
	if (`year'>=1995) {
		local ilist `ilist' 8188
	}
	gen VEHIC = 0
	foreach ii in `ilist' {
		replace VEHIC = VEHIC + max(0,X`ii')
	}
	lab var VEHIC "value of all vehicles"
	
	*	have any vehicles
	gen byte HVEHIC = (VEHIC>0)
	lab val HVEHIC YESNO
	lab var HVEHIC "Has any vehicle?"
	
	*	vehicle supplied by a business
	gen byte BUSVEH = (X2501==1)
	lab val BUSVEH YESNO
	lab var BUSVEH "Has vehicle supplied by a business?"
	notes BUSVEH: recode of X2501
	
	*	number of business vehicles
	clonevar NBUSVEH = X2502
	
	*   owned vehicles (excludes motorcycles, RVs, motor homes,
	*	tractors, snow blowers etc)
	*   have an owned vehicle
	gen byte OWN=(X2201==1)
	lab val OWN YESNO
	lab var OWN "Has an owned vehicle?"
	notes OWN: recode of X2201
	
	*	number of owned vehicles
	clonevar NOWN=X2202
	
	*	value of owned vehicles
	gen VOWN=X8166+X8167+X8168
	if (`year'>=1995) {
		replace VOWN = VOWN+X8188
	}
	lab var VOWN "value of owned vehicles"
	
	*	leased vehicles
	*	have leased vehicle
	gen byte LEASE=(X2101==1)
	lab val LEASE YESNO
	lab var LEASE "Has leased vehicle?"
	notes LEASE: recode of X2101
	
	*	number of leased vehicles
	clonevar NLEASE=X2102
	
	*	value of leased vehicles
	gen VLEASE=X8163+X8164
	lab var VLEASE "value of leased vehicles"
	
	*	total number of vehicles (owned and leased)
	gen NVEHIC=NOWN+NLEASE
	lab var NVEHIC "total number of vehicles (owned and leased)
	
	*	new model-year car (owned or leased)
	local ilist 2104 2111 2205 2305 2405
	if (`year'>=1995) {
		local ilist `ilist' 7152
	}
	gen byte NEWCAR1 = 0
	gen byte NEWCAR2 = 0
	foreach ii in `ilist' {
		replace NEWCAR1 =  NEWCAR1+(X`ii'>=`year'-2)
		replace NEWCAR2 =  NEWCAR2+(X`ii'>=`year'-1)
	}
	lab var NEWCAR1 "number of car/truck/SUV with model year no older than two years before the survey"
	lab var NEWCAR2 "number of car/truck/SUV with model year no older than one year before the survey"
	
	*	primary residence
	*	for farmers, assume X507 (percent of farm used for
	*	farming/ranching) is maxed at 90%
	replace X507=min(9000,X507)
	notes X507: changed from original SCF data
	*	compute value of business part of farm net of outstanding mortgages
	gen FARMBUS=0
	replace FARMBUS=(X507/10000)*(X513+X526-X805-X905-X1005) if X507>0
	foreach ii in 805 808 813 905 908 913 1005 1008 1013 {
		replace X`ii'=X`ii'*((10000-X507)/10000) if X507>0
		notes X`ii': changed from original SCF data
	}
	forvalues ii=1103(11)1125 {
		replace FARMBUS=FARMBUS-X`=`ii'+5'*(X507/10000) if X507>0 & X`ii'==1
		replace X`=`ii'+5'=X`=`ii'+5'*((10000-X507)/10000) if X507>0 & X`ii'==1
		replace X`=`ii'+6'=X`=`ii'+6'*((10000-X507)/10000) if X507>0 & X`ii'==1
		notes X`=`ii'+5': changed from original SCF data
		notes X`=`ii'+6': changed from original SCF data
	}
	replace FARMBUS=FARMBUS-X1136*(X507/10000)*((X1108*(X1103==1) ///
		+X1119*(X1114==1)+X1130*(X1125==1))/(X1108+X1119+X1130)) ///
			if X507>0 & X1136>0 & (X1108+X1119+X1130>0)
	replace X1136=X1136*((10000-X507)/10000)*((X1108*(X1103==1) ///
		+X1119*(X1114==1)+X1130*(X1125==1))/(X1108+X1119+X1130)) ///
			if X507>0 & X1136>0 & (X1108+X1119+X1130>0)
	lab var FARMBUS "value of business part of farm net of outstanding mortgages"
	notes X1136: changed from original SCF data
	
	*	value of primary residence
	gen HOUSES=X604+X614+X623+X716+((10000-max(0,X507))/10000)*(X513+X526)
	lab var HOUSES "value of primary residence"
	notes HOUSES: if R only owns a part of the property, the values reported should be only Rs share	
	*	have owned principal residence
	gen byte HHOUSES = HOUSES~=0
	lab val HHOUSES YESNO
	lab var HHOUSES "Have owned principal residence?"
	
	*	homeownership class
	local vlist 1,3,4,5,6
	if (`year'>=1995) {
		local vlist `vlist',8
	}
	gen byte HOUSECL=cond(inlist(X508,1,2)|inlist(X601,1,2,3)|inlist(X701,`vlist'),1,2)
	if (`year'>=1995) {
		replace HOUSECL=1 if X701==-7 & X7133==1
	}
	lab def HOUSECL 1 "Yes" 2 "No"
	lab val HOUSECL HOUSECL
	lab var HOUSECL "Owns ranch/farm/mobile home/house/condo/coop/etc.?"
	
	*	other residential real estate: includes land contracts/notes
	*	household has made, properties other than the principal
	*	residence that are coded as 1-4 family residences, time shares,
	*	and vacations homes
	*		and
	*	net equity in nonresidential real estate: real estate other than
	*	the principal residence, properties coded as 1-4 family
	*	residences, time shares, and vacation homes net of mortgages and
	*	other loans taken out for investment real estate
	local imax 1903
	if (`year'>=2010) {
		local imax 1803 
	}
	local ibase 1405
	local iskip 100
	if (`year'>=2013) {
		local ibase 1306
		local iskip 19 
	}
	local iadd 1619
	if (`year'>=2013) {
		local iadd 1339
	}
	local v1list 12,14,21,22,25,40,41,42,43,44,49,50,52,999
	local v2list 1,2,3,4,5,6,7,10,11,13,15,24,45,46,47,48,51,53,-7
	gen ORESRE = max(0,X`iadd')+max(0,X2002)
	gen NNRESRE = max(0,X2012)-X2016
	forvalues ii=1703(100)`imax' {
		replace ORESRE = ORESRE+max(X`ibase',X`=`ibase'+4')+inlist(X`ii',`v1list')* ///
			 max(0,X`=`ii'+3')*(X`=`ii'+2'/10000)
		replace NNRESRE = NNRESRE+inlist(X`ii',`v2list')* ///
			(max(0,X`=`ii'+3')-X`=`ii'+12')*(X`=`ii'+2'/10000)
		local ibase = `ibase'+`iskip'
	}
	lab var ORESRE "value of other residential real estate"
	lab var NNRESRE "net equity in nonresidential real estate"
	*	have other residential real estate
	gen byte HORESRE = (ORESRE>0)
	lab val HORESRE YESNO
	lab var HORESRE "Has other residential real estate?"	

	*	remove installment loans for PURPOSE=78 from NNRESRE only
	*	where such property exists--otherwise, if ORESRE exists, include
	*	loan as RESDBT---otherwise, treat as installment loan
	gen byte FLAG781 = NNRESRE~=0
	foreach ii in 2710 2727 2810 2827 2910 2927 {
		replace NNRESRE = NNRESRE-X`=`ii'+13'*(X`ii'==78) if FLAG781
	}
	*	have nonresidential real estate
	gen byte HNNRESRE = (NNRESRE~=0)
	lab val HNNRESRE YESNO
	lab var HNNRESRE "Has nonresidential real estate?"
	
	*	business interests
	local imax 33
	if (`year'>=2010) {
		local imax 32
	}
	gen ACTBUS = max(0,X3335)+FARMBUS
	forvalues ii=31/`imax' {
		replace ACTBUS = ACTBUS+max(0,X`ii'29)+max(0,X`ii'24)-max(0,X`ii'26)*(X`ii'27==5) ///
			+max(0,X`ii'21)*inlist(X`ii'22,1,6)
	}
	lab var ACTBUS "net equity of active business interests"
	local ival 3424
	if (`year'>=2010) {
		local ival 3452
	}
	gen NONACTBUS = 0
	foreach ii in 3408 3412 3416 3420 `ival' 3428  {
		replace NONACTBUS = NONACTBUS+max(0,X`ii')
	}
	lab var NONACTBUS "market value of non-active business interests"
	gen BUS = ACTBUS+NONACTBUS
	lab var BUS "value of business interests"
	*	have business interests
	gen byte HBUS=(X3103==1 | X3401==1)
	lab val HBUS YESNO
	lab var HBUS "Has business interests?"
	notes HBUS: includes businesses with zero equity value
	
	*	other nonfinancial assets
	gen OTHNFIN = X4022+X4026+X4030-OTHFIN+X4018
	lab var OTHNFIN "value of other nonfinancial assets"
	notes OTHNFIN: defined as total value of miscellaneous assets minus other financial assets
	*	have any other nonfinancial assets
	gen byte HOTHNFIN = (OTHNFIN>0)
	lab val HOTHNFIN YESNO
	lab var HOTHNFIN "Has other nonfinancial assets"
	
	*	total nonfinancial assets
	gen NFIN=VEHIC+HOUSES+ORESRE+NNRESRE+BUS+OTHNFIN
	lab var NFIN "total nonfinancial assets"
	*	have any nonfinancial assets
	gen byte HNFIN = NFIN~=0
	lab val HNFIN YESNO
	lab var HNFIN "Has any nonfinancial assets?"
	*	total nonfinancial assets excluding principal residences
	gen NHNFIN=NFIN-HOUSES
	lab var NHNFIN "value of nonfinancial assets excluding principal residences"
	
end

capture: program drop addDebts
program define addDebts

	args year

	*	housing debt
	gen HELOC = 0
	forvalues ii=1103(11)1125 {
		replace HELOC = HELOC+X`=`ii'+5'*(X`ii'==1)
	}
	replace HELOC = HELOC+max(0,X1136)*HELOC/(X1108+X1119+X1130)
	replace HELOC = 0 if X1108+X1119+X1130<1
	lab var HELOC "home equity lines of credit"
	gen NH_MORT = X805+X905+X1005
	replace NH_MORT = NH_MORT+0.5*max(0,X1136)*(HOUSES>0) if X1108+X1119+X1130<1
	lab var NH_MORT "non-HELOC mortgage debt"
	gen MRTHEL = HELOC+NH_MORT
	lab var MRTHEL "housing debt"
	
	*	Home equity equals home value less all home secured debt
	gen HOMEEQ = HOUSES-MRTHEL
	lab var HOMEEQ "home equity"
	
	*	have principal residence debt
	gen byte HMRTHEL = MRTHEL>0
	gen byte HHELOC = HELOC>0
	gen byte HNH_MORT = NH_MORT>0
	lab var HMRTHEL "Has principal residence debt"
	lab var HHELOC "Has principal residence HELOC debt"
	lab var HNH_MORT "Has principal residence mortgage debt"
	
	*	have principal residence debt by type
	gen byte HPRIM_MORT = (X805>0)
	lab var HPRIM_MORT "Has first-lien mortgage?"
	if (`year'>=1995) {
		gen byte PURCH1 = ((X802>0 & X7137==0) | X7137==8)
		gen byte REFIN_EVER = (X7137>0 & X7137~=8)
		gen byte HEXTRACT_EVER = inlist(X7137,2,3,4)
		lab var PURCH1 "Has purchase loan - first mortgage?"
		lab var REFIN_EVER "Refinanced?"
		lab var HEXTRACT_EVER "Extracted equity from refinance?"
		notes REFIN_EVER: recode of X7137
		notes HEXTRACT_EVER: recode of X7137
		notes PURCH1: Only available from 1995 survey forward (X7137)
		notes REFIN_EVER: Only available from 1995 survey forward (X7137)
		notes HEXTRACT_EVER: Only available from 1995 survey forward (X7137)
	}
	gen byte HSEC_MORT = ((X905+X1005)>0)
	lab var HSEC_MORT "Has second/third mortgage?"
	gen byte PURCH2 = (X918==1 | X1018==1)
	lab var PURCH2 "Has purchase loan - second/third mortgage?"
	gen byte HMORT2 = ((X918~=0 & X918~=1) | (X1018~=0 & X1018~=1))
	lab var HMORT2 "Has loan used for other purpose?"
	egen byte HELOC_YN = anymatch(X1103 X1114 X1125), v(1)
	lab var HELOC_YN "Has a HELOC?"
	lab val HMRTHEL-HELOC_YN YESNO
		
	*	other lines of credit
	tempvar o1
	gen `o1' = 0
	gen OTHLOC = 0
	forvalues ii=1108(11)1130 {
		replace `o1'=`o1'+X`ii'
		replace OTHLOC = OTHLOC+X`ii'*(X`=`ii'-5'~=1)
	}
	replace OTHLOC = . if `o1'<1
	replace OTHLOC = OTHLOC+max(0,X1136)*OTHLOC/`o1'
	replace OTHLOC = ((HOUSES<=0)+0.5*(HOUSES>0))*(max(0,X1136)) if mi(OTHLOC)
	lab var OTHLOC "other lines of credit"
	gen byte HOTHLOC = (OTHLOC>0)
	lab var HOTHLOC "Has other lines of credit?"
	lab val HOTHLOC YESNO

	*	debt for other residential property: includes land contracts,
	*	residential property other than the principal residence, misc
	*	vacation, and installment debt reported for cottage/vacation home
	*	code 67)
	local mlist 12,14,21,22,25,40,41,42,43,44,49,50,52,53,999
	local nmort 2
	if (`year'<=2007) {
		local nmort 3
	}
	local iadd 1621
	local ibase 1417
	local iskip 100
	if (`year'>=2013) {
		local iadd 1342
		local ibase 1318
		local iskip 19
	}
	gen RESDBT = X`iadd'+X2006
	forvalues ii=1/`nmort' {
		replace RESDBT = RESDBT+X`ibase'
		local ibase = `ibase'+`iskip'
	}
	forvalues ii=1/3 {
		gen MORT`ii' = 0
	}
	forvalues ii=1/`nmort' {
		local jj = `ii'+6
		replace MORT`ii'= (inlist(X1`jj'03,`mlist'))*X1`jj'15*(X1`jj'05/10000)
		local jj = `ii'+3
		replace RESDBT = RESDBT+MORT`ii'
	}
	*   for parallel treatment, only include PURPOSE=67 where
	*	ORESRE>0--otherwise, treat as installment loan
	gen byte FLAG67 = ORESRE>0
	gen byte FLAG782 = (FLAG781~=1 & ORESRE>0)
	forvalues ii=7/9 {
		replace RESDBT = RESDBT+X2`ii'23*(X2`ii'10==78)+X2`ii'40*(X2`ii'27==78) if FLAG782
		replace RESDBT = RESDBT+X2`ii'23*(X2`ii'10==67)+X2`ii'40*(X2`ii'27==67) if FLAG67
	}
	lab var RESDBT "debt for other residential property"
	notes RESDBT: debt for nonresidential real estate is netted out of the corresponding assets
	gen byte HRESDBT:YESNO = (RESDBT>0)
	lab var HRESDBT "Has other residential real estate debt?"
	
	*	credit card debt
	local cclist 427 413 421
	if (`year'<2016) {
		local cclist `cclist' 430
	}
	if (`year'<2010) {
		local cclist `cclist' 424
	}
	gen CCBAL = 0
	foreach ii of local cclist {
		replace CCBAL = CCBAL+max(0,X`ii')
	}
	gen byte NOCCBAL:YESNO = (CCBAL==0)
	lab var NOCCBAL "Has no credit card debt?"
	notes NOCCBAL: excludes charge accounts at stores
	if (`year'>=1992) {
		replace CCBAL = CCBAL+max(0,X7575)
	}
	lab var CCBAL "credit card debt"
	gen byte HCCBAL:YESNO = (CCBAL>0)
	lab var HCCBAL "Has credit card debt?"
	notes CCBAL: from 1992 forward, specific question addresses revolving debt at stores, and this amount is treated as credit card debt here
	notes NOCCBAL: from 1992 forward, specific question addresses revolving debt at stores, and this amount is treated as credit card debt here
	notes HCCBAL: from 1992 forward, specific question addresses revolving debt at stores, and this amount is treated as credit card debt here
	
	*	installment loans
	local i1list
	local i2list
	local i3list
	if (`year'>=1995) {
		local i1list `i1list' X7169
		local i2list `i2list' X7179
		local i3list `i3list' X7183
	}
	egen VEH_INST = rowtotal(X2218 X2318 X2418 X2424 X2519 X2619 X2625 `i1list')
	if (`year'>=1992) {
		egen EDN_INST = rowtotal(X7824 X7847 X7870 X7924 X7947 X7970 `i2list')
	}
	else {
		gen EDN_INST = 0
	}
	egen INSTALL = rowtotal(X1044 X1215 X1219 `i3list')
	replace INSTALL = INSTALL+VEH_INST+EDN_INST
	forvalues ii=7/9 {
		forvalues jj=23(17)40 {
			local kk = `jj'-13
			replace EDN_INST = EDN_INST+X2`ii'`jj' if X2`ii'`kk'==83
			*   see notes above at definitions of NNRESRE and RESDBT
			replace INSTALL = INSTALL+X2`ii'`jj' if X2`ii'`kk'==78 & FLAG781==0 & FLAG782==0
			replace INSTALL = INSTALL+X2`ii'`jj' if X2`ii'`kk'==67 & FLAG67==0
			replace INSTALL = INSTALL+X2`ii'`jj' if ~inlist(X2`ii'`kk',67,78)
		}
	}
	gen OTH_INST = INSTALL-VEH_INST-EDN_INST
	gen byte HVEH_INST = (VEH_INST>0)
	gen byte HEDN_INST = (EDN_INST>0)
	gen byte HOTH_INST = (OTH_INST>0)
	gen byte HINSTALL = (INSTALL>0)
	lab var VEH_INST "installment loans: vehicle"
	lab var EDN_INST "installment loans: education"
	lab var OTH_INST "installment loans: other"
	lab var INSTALL "installment loans"
	lab var HVEH_INST "Has installment debt: vehicle"
	lab var HEDN_INST "Has installment debt: education"
	lab var HOTH_INST "Has installment debt: other"
	lab var HINSTALL "Has any installment debt?"
	lab val HVEH_INST-HINSTALL YESNO
	
	*	margin loans
	gen OUTMARG = max(0,X3932)
	if (`year'==1995) {
		replace OUTMARG = 0 if X7194~=5
	}
	lab var OUTMARG "margin loans"
	notes OUTMARG: except in 1995, the SCF does not ask whether the margin loan was reported earlier: the instruction explicitly excludes loans reported earlier
	
	*	pension loans not reported earlier
	if (`year'>=2004) {
		forvalues ii=0/5 {
			local jj = `ii'+1
			if (`year'>=2010 & mod(`jj',3)==0) {
				gen OUTPEN`jj' = 0
			}
			else {
				gen OUTPEN`jj' = max(0,X11`ii'27) if X11`ii'70==5
			}
		}
	}
	else {
		local jj = 1
		foreach ii in 42 43 44 48 49 50 {
			gen OUTPEN`jj' = max(0,X`ii'29) if X`ii'30==5
			local ++jj
		}
	}
	egen OUTPEN = rowtotal(OUTPEN1-OUTPEN6)
	gen ODEBT = OUTPEN+OUTMARG
	replace OUTPEN = max(0,OUTPEN)
	lab var OUTPEN "pension loans not reported earlier"
	
	*	other debts (loans against pensions, loans against life insurance,
	*	margin loans, miscellaneous)
	replace ODEBT = ODEBT+max(0,X4010)+max(0,X4032)
	lab var ODEBT "other debts"
	gen byte HODEBT = (ODEBT>0)
	lab var HODEBT "Has any other debts?"
	lab val HODEBT YESNO
	
	*	total debt
	gen DEBT = MRTHEL+RESDBT+OTHLOC+CCBAL+INSTALL+ODEBT
	lab var DEBT "total debt"
	gen byte HDEBT = (DEBT>0)
	lab var HDEBT "Has any debt?"
	lab val HDEBT YESNO

end

capture: program drop addFinances
program define addFinances

	args year
	
	*	financial assets
	di `" - addFinAssets `year'"'
	qui addFinAssets `year'
	
	*	nonfinancial assets
	di `" - addNonFinAssets `year'"'
	qui addNonFinAssets `year'
	
	*	total assets
	gen ASSET = FIN+NFIN
	lab var ASSET "total assets"
	*	have any assets
	gen byte HASSET = (ASSET~=0)
	lab val HASSET YESNO
	lab var HASSET "Has any assets?"
	
	*	debts
	di `" - addDebts `year'"'
	qui addDebts `year'

	*	total net worth
	gen NETWORTH = ASSET-DEBT
	lab var NETWORTH "total net worth"
	
	*	leverage ratio
	gen LEVRATIO = (DEBT>0 & ASSET==0)
	replace LEVRATIO = DEBT/ASSET if (DEBT>0 & ASSET>0)
	lab var LEVRATIO "leverage ratio"
	
	*	debt to income ratio, if no income, assign arbitrary value of 10 to
	*	match how computed in Bulletin article tables
	gen DEBT2INC = 10*(DEBT>0 & INCOME==0)
	replace DEBT2INC = DEBT/INCOME if (DEBT>0 & INCOME>0)
	lab var DEBT2INC "debt to income ratio"
	notes DEBT2INC: set to 10 if no income

end

capture: program drop addCapitalGains
program define addCapitalGains

	args year
	
	*	principal residences
	tempvar sv
	tempvar kgh
	gen `sv' = X627+X631
	egen `kgh' = rowmax(X607 X617 `sv' X635 X717)
	egen KGHOUSE = rowmax(X513 X526 X604 X614 X623 X716)
	replace KGHOUSE = KGHOUSE-`kgh'-X1202
	lab var KGHOUSE "capital gains: principal residences"
	notes KGHOUSE: current value less original purchase price and less improvements
	notes KGHOUSE: adjusted for capital gains on farm businesses (-FARMBUS_KG)

	*	other real estate
	local ni 9
	if (`year'>=2010) {
		local ni 8
	}
	gen KGORE = (X2002-X2003)+(X2012-X2013)
	forvalues ii=7/`ni' {
		replace KGORE = KGORE+(X1`ii'05/10000)*(X1`ii'06-X1`ii'09)
	}
	lab var KGORE "capital gains: other real estate"
	notes KGORE: current value less purchase price adjusted for share owned
	
	*	businesses
	local iis 129 229 408 412 416 420 428
	if (`year'>=2010) {
		local iis `iis' 452
	}
	else {
		local iis `iis' 329 424
	}
	gen KGBUS = 0
	foreach ii of local iis {
		replace KGBUS = KGBUS+(X3`ii'-X3`=`ii'+1')
	}
	lab var KGBUS "capital gains: businesses"
	notes KGBUS: current value less tax basis--active and non-active businesses
	notes KGBUS: adjusted for capital gains on farm businesses (+FARMBUS_KG)
	
	*	adjust for capital gains on farm businesses
	gen FARMBUS_KG = 0
	replace FARMBUS_KG = (X507/10000)*KGHOUSE if X507>0
	notes FARMBUS_KG: based on X507 and unadjusted KGHOUSE
	replace KGHOUSE = KGHOUSE-FARMBUS_KG
	replace KGBUS = KGBUS+FARMBUS_KG
	
	*	stocks and mutual funds
	gen KGSTMF = (X3918-X3920)+(X3833-X3835)
	lab var KGSTMF "capital gains: stocks and mutual funds"
	notes KGSTMF: current value less gains/losses
	notes KGSTMF: [DR: not sure above note is correct... just gains/losses?]
	
	*	total gains/losses
	gen KGTOTAL = KGHOUSE+KGORE+KGBUS+KGSTMF
	lab var KGTOTAL "capital gains: total gains/losses"
	
	*	whether have capital gains
	foreach var of varlist NETWORTH KGTOTAL KGHOUSE KGORE KGBUS KGSTMF {
		gen byte H`var' = (`var'~=0)
		lab var H`var' "Has `:var lab `var''?"
		lab val H`var' YESNO
	}
	
end

capture: program drop addPayments
program define addPayments

	args year

	*	credit card payments
	gen CCPAY = 0.025*CCBAL
	lab var CCPAY "credit card payments"
	notes CCPAY: use HREF assumption of 2.5% per month for credit card payments
	
	*	mortgage payments
	forvalues ii=1/3 {
		local jj = `ii'+7
		addPeriodic PAYMORT`ii' if X`jj'08>0, v(`jj'08) mult(1)
		addPeriodic PAYMORT`ii' if X`jj'08<=0 & X`jj'13>0, v(`jj'13) mult(1)
	}
	tempvar mc
	gen `mc' = 1
	if (`year'>=1992) {
		mconv `mc', f(7567) replace
	}
	gen PAYMORTO = 0
	replace PAYMORTO = X1039*`mc' if X1039>0
	addPeriodic PAYMORTO if X1039<=0 & X1040>0, v(1040) mult(1)

	*	lines of credit
	local pnum 1
	forvalues ii=1109(11)1131  {
		gen PAYLOC`pnum' = 0
		addPeriodic PAYLOC`pnum' if X`ii'>0, v(`ii') mult(1)
		local ++pnum
	}
	
	*	loc mopup
	* 	if 3 LOCs in grid but no amounts outstanding, payment
	*	rate and per for the mopup are set to median values for all
	*	LOCs (median payment rate for 1995 is .0316 7/19/96)
	gen byte HMOP = X1125==1
	gen PTMOP = 0.0316*X1136
	gen byte PPMOP = 4
	gen PAYLOCO = PTMOP
	forvalues ii==1108(11)1130 {
		mconv `mc', f(`=`ii'+2') replace
		replace HMOP = X`=`ii'-5' if X`ii'~=0
		replace PTMOP = (max(0,X`=`ii'+1')/X`ii')*X1136 if X`ii'~=0
		replace PPMOP = X`=`ii'+2' if X`ii'~=0
		replace PAYLOCO = PTMOP*`mc' if X`ii'~=0
	}
	foreach var of varlist HMOP PTMOP PPMOP PAYLOCO {
		replace `var' = 0 if X1136<=0
	}

	*	home improvement loans
	addPeriodic PAYHI1 if X1211>0, v(1211) mult(1)
	if (`year'>=1992) {
		mconv `mc', f(7565) replace
	}
	else {
		replace `mc' = 1
	}
	replace PAYHI1 = X1210*`mc' if X1210>0
	addPeriodic PAYHI2 if X1220>0, v(1220) mult(1)

	*	land contracts
	local nc 2
	if (`year'<2010) {
		local nc 3
	}
	local iadd 1621
	local ibase 1417
	local iskip 100
	if (`year'>=2013) {
		local iadd 1342
		local ibase 1318
		local iskip 19
	}
	forvalues ii=1/`nc' {
		gen PAYLC`ii'= X`ibase'*(exp(ln(1.08)/12)-1)
		local ibase = `ibase'+`iskip'
	}
	gen PAYLCO = X`iadd'*(exp(ln(1.08)/12)-1)
	foreach var of varlist PAYLC1-PAYLCO {
		notes `var': assumed to be interest payments on amount outstanding, at 8 percent APR
	}
	
	*	other residential property
	local vlist 12,14,21,22,25,40,41,42,43,44,49,50,52,999
	local np 1
	local nc 8
	if (`year'<2010) {
		local nc 9
	}
	forvalues ii=7/`nc' {
		tempvar mc`ii'
		addPeriodic PAYORE`np' if X1`ii'23>0 & inlist(X1`ii'03,`vlist'), v(1`ii'23) mult(1)
		addPeriodic `mc`ii'' if inlist(X1`ii'03,`vlist'), v(1`ii'18) mult(1)
		replace PAYORE`np' = `mc`ii'' if X1`ii'18>0
		replace PAYORE`np'= PAYORE`np'*(X1`ii'05/10000)
		local ++np
	}
	addPeriodic PAYOREV if X2007>0, v(2007) mult(1)
	if (`year'>=2010) {
		gen PAYORE3 = 0
	}
	
	*	vehicle loans
	forvalues ii=1/3 {
		local jj = 2`=`ii'+1'14
		addPeriodic PAYVEH`ii' if X`jj'>0, v(`jj') mult(1)
		if (`year'>=1992) {
			mconv `mc', f(753`=8-`ii'') replace
		}
		else {
			replace `mc' = 1
		}
		local --jj
		replace PAYVEH`ii' = X`jj'*`mc' if X`jj'>0
	}
	gen PAYVEH4 = 0
	if (`year'>=1995) {
		addPeriodic PAYVEH4 if X7162>0, v(7162) mult(1)
		addPeriodic PAYVEH4 if X7162<=0 & X7164>0, v(7164) mult(1)
	}
	addPeriodic PAYVEHM if X2425>0, v(2425) mult(1)
	replace `mc' = 1
	forvalues ii=1/2 {
		local jj = `ii'+4
		if (`year'>=1992) {
			mconv `mc', f(753`=2-`ii'') replace
		}
		addPeriodic PAYVEO`ii' if X2`jj'15>0, v(2`jj'15) mult(1)
		replace PAYVEO`ii' = X2`jj'14*`mc' if X2`jj'14>0
	}
	addPeriodic PAYVEOM if X2626>0, v(2626) mult(1)
	
	*	student loans
	forvalues ii=1/7 {
		gen PAYEDU`ii' = 0
	}
	if (`year'>=1992) {
		local nl 1
		forvalues jj=8/9 {
			forvalues ii=15(23)61 {
				local kk = `ii'+2
				addPeriodic PAYEDU`nl' if X7`jj'`ii'>0 & `year'>=1992, v(7`jj'`ii') mult(1)
				if (`year'<2016) {
					addPeriodic PAYEDU`nl' if X7`jj'`ii'<=0 & X7`jj'`kk'>0 & `year'>=1992, v(7`jj'`kk') mult(1)
				}
				local ++nl
			}
		}
		if (`year'>=1995) {
			addPeriodic PAYEDU7 if X7180>0, v(7180) mult(1)
		}
	}
	
	*	installment loans
	local nl 1
	replace `mc' = 1
	forvalues jj=7/9 {
		forvalues ii=18(17)35 {
			local kk = `ii'+1
			if (`year'>=1992) {
				mconv `mc', f(752`=8-`nl'') replace
			}
			addPeriodic PAYILN`nl' if X2`jj'`kk'>0, v(2`jj'`kk') mult(1)
			replace PAYILN`nl' = X2`jj'`ii'*`mc' if X2`jj'`ii'>0
			replace PAYILN`nl' = 0 if X2`jj'`=`ii'-8'==78 & FLAG781~=0
			local ++nl
		}
	}
	gen PAYILN7 = 0
	if (`year'>=1995) {
		addPeriodic PAYILN7 if X7184>0, v(7184) mult(1)	
	}
	
	*	payments on margin loans
	gen PAYMARG = OUTMARG*(exp(ln(1.08)/12)-1)
	notes PAYMARG: assumed to be interest payments on balance outstanding, paid at 8 percent APR
	
	*	loans agains insurance policies
	addPeriodic PAYINS, v(4011) mult(1)
	
	*	payments on other loans
	gen PAYOTH = 0
	notes PAYOTH: set to zero
	
	*	payments on loans against pension plans not previously reported
	local ibase 11070
	local vbase 11028
	local vskip 100
	if (`year'<=2001) {
		local ibase 4230
		local vbase 7211
		local vskip 9
	}
	if (`year'>=1998) {
		forvalues ii=1/6 {
			if (`year'>=2010 & mod(`ii',3)==0) {
				gen PAYPEN`ii' = 0
			}
			else {
				addPeriodic PAYPEN`ii' if X`ibase'==5, v(`vbase') mult(1)
			}
			if (`year'<=2001 & `ii'==3) {
				local ibase 4730
				local vbase 7269
			}
			local ibase = `ibase'+100
			local vbase = `vbase'+`vskip'
		}
	}
	else {
		local nl = 1
		foreach ii in 42 43 44 48 49 50 {
			gen PAYPEN`nl' = (exp(ln(1.065)/12)-1)*max(0,X`ii'29)*(X`ii'30==5)
			notes PAYPEN`nl': assumes 6.5 percent APR
			local ++nl
		}
	}
	forvalues ii=1/6 {
		notes PAYPEN`ii': details available starting in 1998, but still only include loans not previously reported
	}
	
	*	compute total monthly payments
	gen TPAY = 0
	foreach var of varlist CCPAY PAY* {
		replace TPAY = TPAY+max(0,`var')
	}
	gen MORTPAY = 0
	gen REVPAY = CCPAY+PAYLOCO
	foreach var of varlist PAYMORT1-PAYMORT3 PAYORE? PAYLC? {
		replace MORTPAY=MORTPAY+`var'
	}
	
	forvalues ii=1/3 {
		replace MORTPAY=MORTPAY+PAYLOC`ii' if X`=1092+11*`ii''==1
		replace REVPAY=REVPAY+PAYLOC`ii' if inlist(X`=1092+11*`ii'',0,5)
	}
	gen CONSPAY = 0
	foreach var of varlist PAYMORTO PAYVEH? PAYVEO? PAYEDU? PAYILN? PAYMARG PAYINS PAYOTH PAYPEN? PAYHI? {
		replace CONSPAY = CONSPAY+`var'
	}
	
	*	compute ration of monthly payments to monthly income
	scalar CPIADJ89 = CPIADJ*1886/CPIBASE
	gen PIRTOTAL = TPAY/max(INCOME/12,100/CPIADJ89)
	foreach var in MORT CONS REV {
		gen PIR`var' = `var'PAY/max(INCOME/12,100/CPIADJ89)
	}
	gen PIR40:YESNO=(PIRTOTAL>0.4)
	
end

capture: program drop addLoanPurposes
program define addLoanPurposes

	args year
	
	*	for convenience, initialize nonexistent debt questions at zero
	foreach ii in 7169 7179 7183 7824 7847 7870 7924 7947 7970 {
		capture: gen X`ii' = 0
		if (_rc==0) {
			notes X`ii': for convenience, initialized nonexistent debt question at zero
		}
	}
	
	*   assign a purpose code for borrowing where the purposes of the debt
	*	was not asked directly as a part of the individual loan sequence
	
	*	credit card debt assigned to goods and services (11)
	gen PURPCC = (CCBAL>0)*11
	
	*	first mortgages assigned to home purchase (1)
	gen PURPMORT=(X805>0)*1
	notes PURPMORT: in 1995+ surveys collected this info if date of mortgage was not the same as the date of home purchase, but code 1 assumed here for comparability with earlier years

	*   other home purchase loans assigned to home purchase (1)
	gen PURPOP=(X1044>0)*1
	
	*   mop-up line of credit assigned to unclassifiable (-7)
	gen PURPLOC=(X1136>0)*-7
	
	*   home improvement loans assigned to home improvement category 3,
	*	but code as 300 for programming convenience
	gen PURPHI1=(X1215>0)*300
	gen PURPHI2=(X1219>0)*300
	
	*   money still owed on properties for which R holds a land 
	*	contract assigned to debt for residential property (67)
	local np 2
	if (`year'<=2007) {
		local np 3
	}
	local ibase 1417
	local iskip 100
	local iadd 1621
	if (`year'>=2013) {
		local ibase 1318
		local iskip 19
		local iadd 1342
	}
	forvalues ii=1/`np' {
		gen PURPLC`ii'=(X`ibase'>0)*67
		local ibase = `ibase'+`iskip'
	}
	gen PURPLC4=(X`iadd'>0)*67
	
	*   residential property other than principal residence assigned to
	*	debt for residential property (67);
	local vlist 12,14,21,22,25,40,41,42,43,44,49,50,52,999
	local il 8
	if (`year'<2010) {
		local il 9
	}
	local nl 1
	forvalues ii=7/`il' {
		gen PURPORE`nl' = inlist(X1`ii'03,`vlist')*(X1`ii'15>0)*67
		local ++nl
	}
	gen PURPORE4 = (X2006>0)*67

	*   vehicles assigned to vehicle category 10 but code as 100 for
	*	programming convenience
	gen PURPVEH1=(X2218>0)*100
	gen PURPVEH2=(X2318>0)*100
	gen PURPVEH3=(X2418>0)*100
	
	gen PURPVEH4=(X7169>0)*10 if `year'>=1995
	gen PURPVEHM=(X2424>0)*100
	
	gen PURPVEO1=(X2519>0)*100
	gen PURPVEO2=(X2619>0)*100
	gen PURPVEOM=(X2625>0)*100

	*   loans collected directly as student loans assigned to education
	*	category (83)
	forvalues ii=1/7 {
		gen PURPED`ii'= 0
	}
	local np 1
	if (`year'>=1992) {
		foreach ii in 824 847 870 924 947 970 {
			replace PURPED`np' = (X7`ii'>0)*83
			local ++np
		}
		replace PURPED7 = (X7179>0)*83 if `year'>=1995
	}
	
	*   purpose of installment loans (excl loans for nonresidential property,
	*	which are netted out of such assets)
	local np 1
	forvalues ii=27/29 {
		forvalues jj=10(17)27 {
			gen PURPILN`np' = cond(X`ii'`jj'~=78 | FLAG781==0, X`ii'`jj', -9)
			local ++np
		}
	}
	*   other installment loans assigned to unclassifiable (-7)
	gen PURPILN7 = cond(`year'>=1995,-7*(X7183>0),-9)

	* margin loans assigned to investment (71)
	gen PURPMARG = (X3932>0)*71
	
	* insurance loans assigned to unclassifiable (-7)
	gen PURPINS=(X4010>0)*-7
	* misc sect N loans assigned to unclassifiable (-7)
	gen PURPOTH=(X4031>0)*-7

	* pension loans assigned to unclassifiable (-99) for years before 1998
	local ibase 11070
	local vbase 11030
	local vskip 100
	if (`year'<2004) {
		local ibase 4230
		local vbase 6791
		local vskip 1
	}
	if (`year'>=1998) {
		forvalues ii=1/6 {
			if (`year'>=2010 & mod(`ii',3)==0) {
				gen PURPPEN`ii' = 0
			}
			else {
				gen PURPPEN`ii' = cond(inlist(X`ibase',5,0),X`vbase',-9)
			}
			local ibase = `ibase'+100
			if (`ibase'==4530) {
				local ibase 4830
			}
			local vbase = `vbase'+`vskip'
		}
	}
	else {
		local ibase 4230
		forvalues ii=1/6 {
			gen PURPPEN`ii' = cond(inlist(X`ibase',5,0),(X`=`ibase'-1'>0)*(-99)*(X`ibase'==5),-9)
			local ibase = `ibase'+100
			if (`ibase'==4530) {
				local ibase 4830
			}
		}
	}

end

capture: program drop addUnknownLenders
program define addUnknownLenders

	*   credit card debt assigned to store and credit cards
	gen TYPECC=98
	
	*   mopup LOC assigned to unclassified
	gen TYPELOC=97
	
	*   home improvement loans assigned to unclassified
	gen TYPEHI1=97
	gen TYPEHI2=97
	
	*   outstanding loans on land contracts held by HH assigned to unclassified
	forvalues ii=1/4 {
		gen TYPELC`ii'=97
	}
	
	*   loans for vacation homes and recreational properties assigned to unclassified
	gen TYPEORE4=97
	gen TYPEORE5=97
	
	*   loans for remaining passenger vehicles assigned to unclassified
	gen TYPEVEHM=97

	*   loans for remaining other vehicles assigned to unclassified
	gen TYPEVEOM=97
	
	*   other education loans assigned to unclassified
	gen TYPEEDU7=97
	
	*   adjust institution for assignment of loans to NNRESRE
	local ni 1
	forvalues ii=27/29 {
		forvalues jj=10(17)27 {
			gen INSTALL_I`ni'=X`=9106+`ni''*(X`ii'`jj'~=78 | FLAG781==0)
			local ++ni
		}
	}

	*   other installment loans assigned to unclassified;
	gen TYPEILN7=97

	*   margin loans assigned to brokerages
	gen TYPEMARG=16

	*   loans against insurance policies assigned to insurance companies
	gen TYPEINS=17
	
	*   other loans assigned to individual lender NEC
	gen TYPEOTH=27
	
	*   loans against pensions assigned to borrowing against pension plans
	forvalues ii=1/6 {
		gen TYPEPEN`ii'=96
	}

end

capture: program drop addLoanSums
program define addLoanSums

	args year
	
	if (`year'>=2010) {
	
		local PURPOSES PURPCC PURPMORT X918  X1018 PURPOP ///
	  X1106 X1117 X1128 PURPLOC PURPHI1 PURPHI2  ///
	  PURPLC1 PURPLC2 PURPLC4 ///
	  PURPORE1 PURPORE2 PURPORE4 ///
	  PURPVEH1 PURPVEH2 PURPVEH3 PURPVEH4 PURPVEHM ///
	  PURPVEO1 PURPVEO2 PURPVEOM ///
	  PURPED1 PURPED2 PURPED3 PURPED4 PURPED5 PURPED6 PURPED7 ///
	  PURPILN1 PURPILN2 PURPILN3 PURPILN4 PURPILN5 PURPILN6 PURPILN7 ///
	  PURPMARG PURPINS PURPOTH       ///
	  PURPPEN1 PURPPEN2 PURPPEN4  PURPPEN5
	
		local DEBTOUT CCBAL X805 X905  X1005 X1044 ///
	  X1108 X1119 X1130 X1136 X1215 X1219
	  
		if (`year'>=2013) {
			local DEBTOUT `DEBTOUT' X1318 X1337 X1342
		}
		else {
			local DEBTOUT `DEBTOUT' X1417 X1517 X1621
		}

		local DEBTOUT `DEBTOUT' ///
	  MORT1   MORT2   X2006 ///
	  X2218    X2318    X2418    X7169    X2424 ///
	  X2519    X2619    X2625 ///
	  X7824   X7847   X7870   X7924   X7947   X7970   X7179 ///
	  X2723 X2740 X2823 X2840 X2923 X2940 X7183 ///
	  OUTMARG  X4010   X4032 ///
	  OUTPEN1  OUTPEN2  OUTPEN4   OUTPEN5
	  
		local LENTYPE TYPECC X9083    X9084 X9085 X9086 ///
	  X9087 X9088 X9089 TYPELOC X9090   TYPEHI2   ///
	  TYPELC1 TYPELC2 TYPELC4 ///
	  X9099    X9100    TYPEORE4 ///
	  X9102    X9103    X9104    X9215    TYPEVEHM ///
	  X9105    X9106    TYPEVEOM ///
	  X9203   X9204   X9205   X9206   X9207   X9208   TYPEEDU7 ///
	  INSTALL_I1 INSTALL_I2 INSTALL_I3 INSTALL_I4 INSTALL_I5 ///
	  INSTALL_I6 TYPEILN7 TYPEMARG TYPEINS TYPEOTH         ///
	  TYPEPEN1 TYPEPEN2 TYPEPEN4  TYPEPEN5
	  
	}
	else {
	
		local PURPOSES PURPCC PURPMORT X918  X1018 PURPOP ///
	  X1106 X1117 X1128 PURPLOC PURPHI1 PURPHI2   ///
	  PURPLC1 PURPLC2 PURPLC3 PURPLC4 ///
	  PURPORE1 PURPORE2 PURPORE3 PURPORE4 ///
	  PURPVEH1 PURPVEH2 PURPVEH3 PURPVEH4 PURPVEHM ///
	  PURPVEO1 PURPVEO2 PURPVEOM ///
	  PURPED1 PURPED2 PURPED3 PURPED4 PURPED5 PURPED6 PURPED7 ///
	  PURPILN1 PURPILN2 PURPILN3 PURPILN4 PURPILN5 PURPILN6 PURPILN7 ///
	  PURPMARG PURPINS PURPOTH        ///
	  PURPPEN1 PURPPEN2 PURPPEN3 PURPPEN4  PURPPEN5 PURPPEN6
	  
		local DEBTOUT CCBAL X805 X905  X1005 X1044 ///
	  X1108 X1119 X1130 X1136 X1215 X1219  ///
	  X1417 X1517 X1617 X1621 ///
	  MORT1   MORT2   MORT3   X2006 ///
	  X2218    X2318    X2418    X7169    X2424 ///
	  X2519    X2619    X2625 ///
	  X7824   X7847   X7870   X7924   X7947   X7970   X7179 ///
	  X2723 X2740 X2823 X2840 X2923 X2940 X7183 ///
	  OUTMARG  X4010   X4032 ///
	  OUTPEN1  OUTPEN2  OUTPEN3   OUTPEN4   OUTPEN5  OUTPEN6
	  
		local LENTYPE  TYPECC X9083    X9084 X9085 X9086  ///
	  X9087 X9088 X9089 TYPELOC X9090   TYPEHI2   ///
	  TYPELC1 TYPELC2 TYPELC3 TYPELC4 ///
	  X9099    X9100    X9101    TYPEORE4 ///
	  X9102    X9103    X9104    X9215    TYPEVEHM ///
	  X9105    X9106    TYPEVEOM ///
	  X9203   X9204   X9205   X9206   X9207   X9208   TYPEEDU7 ///
	  INSTALL_I1 INSTALL_I2 INSTALL_I3 INSTALL_I4 INSTALL_I5 ///
	  INSTALL_I6 TYPEILN7 TYPEMARG TYPEINS TYPEOTH         ///
	  TYPEPEN1 TYPEPEN2 TYPEPEN3  TYPEPEN4  TYPEPEN5 TYPEPEN6
	  
	}
	local ps: list sizeof PURPOSES
	local ds: list sizeof DEBTOUT
	local ls: list sizeof LENTYPE
	if (`ps'~=`ds' | `ds'~=`ls') {
		di as error "list sizes need to match"
		error(1)
	}
		
	*   aggregate balances by loan purposes:
/*
*   NOTE: beginning with 1998, loan purpose codes were collapsed in
	the public dataset in a way that makes it impossible to recreate
	exactly the same loan purpose categories as those used in the
	1/2000 Bulletin article: for consistency across years, the 1998
	collapsed categories are used in creating loan purpose categories
	here for the public datasets;
*   NOTE: Starting in 2007, "Other unclassifiable loans" includes
	unclassifiable borrowing against pension accounts, which was 
	shown separately in prior years;
*   categories for the public data:
	1=loans for home purchase, cottage, vacation property
	2=home improvement loans
	3=vehicle loans
	4=loan for purchase of goods and services
	5=loans for investments and mortgage loans for other real estate
	6=loans for education and loans for professional expenses
	7=other unclassifiable loans;
*   NOTE: purpose variable for intallment loans set to zero where loan
	has been allocated to NNRESRE;
*/
	
	forvalues ii=1/8 {
		gen PLOAN`ii' = 0
	}
	notes: (Public) Table 16 categories look funny. See notes to PLOAN1-PLOAN8
	notes PLOAN1: (Public) Table 16: Purchase
	notes PLOAN2: (Public) Table 16: Improvement
	notes PLOAN3: (Public) Table 16: Vehicles
	notes PLOAN4: (Public) Table 16: Goods and services
	notes PLOAN5: (Public) Table 16: Investments excluding real estate
	notes PLOAN6: (Public) Table 16: Education
	notes PLOAN7: (Public) Table 16: Other residential property
	notes PLOAN8: (Public) Table 16: Other
	if (`year'>=1998) {
		local pwcode (1 67=1) (2 300=2) (3 6 100=3) (4 5 8 10 11=4) (7 71=5) (9 83=6) (-99 -7=7) (else=.a)
	}
	else {
		local pwcode (1 67=1) (3 300 4=2) (10 100 24 61 63 65=3) ///
			(6 11/18 20 23 25 26 29 31 34/36 49 50 69 80 81 84 85 88/96=4) ///
			(71/76 78 79=5) (82 83=6) (-99 -7=7) (else=.a)
	}
	forvalues ii=1/`ps' {
		local pw: word `ii' of `PURPOSES'
		local dw: word `ii' of `DEBTOUT'
		tempvar `pw'_num
		recode `pw' `pwcode', gen(``pw'_num')
		forvalues jj=1/8 {
			replace PLOAN`jj' = PLOAN`jj'+max(0,`dw') if ``pw'_num'==`jj'
			if (`year'<1998 & `ii'==5) {
				replace PLOAN`jj' = PLOAN`jj'+max(0,`dw') if `pw'==78
			}
		}
	}
	
	*	calculate alternative aggregate balances by loan purpose that, for
    *	2004 forward, splits out purpose for first-lien equity extraction
	forvalues ii=1/8 {
		gen PLOANB`ii' = PLOAN`ii'
	}
	
	*	as check compute total by loan purpose (TPLOAN, TPLOANB) and 
    *	compare with total debt
	foreach var in PLOAN PLOANB {
		gen T`var' = 0
		forvalues ii=1/8 {
			replace T`var' = T`var'+max(0,`var'`ii')
		}
		count if round(DEBT)~=round(T`var')
		if (`r(N)'==0) {
			notes: DEBT check passed (T`var') at TS
		}
		else {
			notes: DEBT check failed (T`var') at TS with `r(N)' discrepancies
		}
	}

*   aggregate total balances by institution type:
/*
    1=commercial bank 
    2=savings and loan 
    3=credit union 
    4=finance, loan or leasing company, inc debt consolidator  
    5=brokerage, broad financial services company and life insurance
    6=real estate lender
    7=individual lender 
    8=other nonfinancial
    9=government
    10=store and credit cards
    11=Loans against pensions
    12=Other unclassifiable (inc foreign)
*/
	forvalues ii=1/12 {
		gen LLOAN`ii' = 0
	}
	local lwcode (11=1) (12=2) (13=3) (14 21 43 56=4) (16 17 92 94 29=5) (18 19 31=6) ///
		(20 26 27 85=7) (15 22/25 30 32 39/41 44/47 57 61 62 80 81 95 99 101=8) ///
		(33/35 42 93=9) (38 50/52 90 98=10) (96=11) (-7 -1 28 37 75 97=12) (else=.)
	forvalues ii=1/`ps' {
		local lw: word `ii' of `LENTYPE'
		local dw: word `ii' of `DEBTOUT'
		tempvar `lw'_num
		capture: recode `lw' `lwcode', gen(``lw'_num')
		if (_rc==0) {
			forvalues jj=1/12 {
				replace LLOAN`jj' = LLOAN`jj'+max(0,`dw') if ``lw'_num'==`jj'
			}
		}
	}
	
	*	as check compute total by loan purpose (TLLOAN) and compare with
    *	total debt
	gen TLLOAN = 0
	forvalues ii=1/12 {
		replace TLLOAN = TLLOAN+max(0,LLOAN`ii')
	}
	count if round(DEBT)~=round(TLLOAN)
	if (`r(N)'==0) {
		notes: DEBT check passed (TLLOAN) at TS
	}
	else {
		notes: DEBT check failed (TLLOAN) at TS with `r(N)' discrepancies
	}
	
end

capture: program drop addLoanInfo
program define addLoanInfo

	args year

	*	payments on a monthly basis
	di `" - addPayments `year'"'
	qui addPayments `year'
	
	*	loan purpose
	di `" - addLoanPurposes `year'"'
	qui addLoanPurposes `year'

	*	assign codes for type of lender where type is not directly known
	di `" - addUnknownLenders"'
	qui addUnknownLenders
	
	*	summarize loan balances by purpose and lender
	di `" - addLoanSums `year'"'
	qui addLoanSums `year'
	
end

capture: program drop verifySCF
program define verifySCF, rclass

	syntax anything(name=year) [, KEEP]

	if ("`keep'"~="keep") {
		preserve
	}
	
	qui svyset
	local su `r(su1)'
	local ovar `=substr("`su'",2,.)'

	tempfile tt
	save `tt'
	addSCFYear `year'
	foreach var of varlist * {
		ren `var' EX_`=upper("`var'")'
	}
	ren EX_`ovar' `ovar'
	merge 1:1 `ovar' using `tt'

	scalar epsilon = 1.0x-18
	local errvars
	local nerrvars 0
	local nepsilon 0
	local epsilon_pass
	local err_max
	foreach var of varlist EX_* {
		qui count if float(`var')~=float(`=substr("`var'",4,.)')
		if (`r(N)'==0) {
			di as text `"`=substr("`var'",4,.)' passed float test"'
		}
		else {
			qui count if ~(abs(`var'-`=substr("`var'",4,.)')<epsilon*max(1,abs(`var')))
			if (`r(N)'==0) {
				di as error `"`=substr("`var'",4,.)' passed epsilon test"'
				local ++nepsilon
				local epsilon_pass `epsilon_pass' `=substr("`var'",4,.)'
			}
			else {
				tempvar te
				gen `te' = abs(`var'-`=substr("`var'",4,.)')/max(1,abs(`var'))
				di as error `"`=substr("`var'",4,.)' failed with `r(N)' errors"'
				local ++nerrvars
				local errvars `errvars' `=substr("`var'",4,.)'
				sum `te', meanonly
				local err_max `err_max' `r(max)'
			}
		}
	}
	
	return local errors `"`err_max'"'
	return local epsilon_passes `"`epsilon_pass'"'
	return local fails `"`errvars'"'
	return local N_epsilon `"`nepsilon'"'
	return local N_fail `"`nerrvars'"'
	return scalar epsilon = epsilon
	
end
