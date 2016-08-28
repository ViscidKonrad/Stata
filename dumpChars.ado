*! version 0.1	30oct2013	David Rosnick
program define dumpChars

	if (c(os)=="MacOSX") {
		di as text "`c(os)' `c(charset)' Character Set"
	}
	else {
		di as text "`c(os)' Character Set"
	}
	forvalues cl=32(8)255 {
		local cdump
		forvalues cc=`cl'/`=`cl'+7' {
			if (`cc'~=96) {
				local cchar = char(`cc')
				local cdump `"`cdump' as text "	`cc': " as result `"`cchar'"'"'
			}
			else {
				local cdump `"`cdump' as text "	`cc': " as result "`=char(96)'""'
			}
		}
		di `cdump'
	}


end
