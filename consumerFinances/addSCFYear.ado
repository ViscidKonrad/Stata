*! version 0.5	29may2019	David Rosnick
program define addSCFYear

	args year
	
	if ("`year'"=="") {
		local year 2016
	}
	if (mod(`year'-1989,3)~=0 | `year'<1989) {
		di as error "year must be selected from every third year starting in 1989."
		exit(1)
	}

	capture: mkdir Data
	capture: confirm file Data/rscfp`year'.dta
	if (_rc~=0) {
		capture: confirm file Data/scfp`year's.zip
		if (_rc~=0) {
			copy https://www.federalreserve.gov/econres/files/scfp`year's.zip Data/scfp`year's.zip
		}
		cd Data
		unzipfile scfp`year's.zip
		cd ..
	}
	use Data/rscfp`year', clear

end
