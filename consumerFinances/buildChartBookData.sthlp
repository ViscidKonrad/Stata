{smcl}
{* *! version 0.3  09sep2014}{...}
{title:Title}

{p2colset 5 20 22 2}{...}
{p2col :{cmd: buildChartBookData} {hline 2}}Compile Survey of Consumer Finances data for FRB Chartbook{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd: buildChartBookData} {it:year} [{cmd:,} {it: options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt real}}inflate data to speficied base{p_end}
{synopt :{opt adjinc}}inflate previous year's income data to survey year{p_end}
{synopt :{opt cpi:base(real)}}base CPI value{p_end}
{synopt :{opt verify}}verify results with FRB data{p_end}
{synopt :{opt keep}}keep FRB variables used in verification{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd: buildChartBookData} creates single survey-year variables necessary to recreate the Federal Reserve's Survey of Consumer Finances "Tables Based on the Public Data." This is a Stata port of a SAS program used by the Federal Reserve.
A version for users of {browse "https://github.com/ajdamico/usgsd/tree/master/Survey%20of%20Consumer%20Finances":R is also available}. The variables created here are also available directly from the FRB as a data extract.

{pstd}
{it:year} is the survey year for the data. The SCF is deployed every three years, with results and public data typically made available in February of the second year following. The 2013 data was made available on 04sep2014.

{marker options}{...}
{title:Options}

{phang}
{opt real} indicates that data should be inflated to the base specified in {opt cpibase}.

{phang}
{opt adjinc} indicates that the income data (for the year prior to the survey) should be adjusted for inflation to the survey base year dollars. This adjustment takes place before any re-base indicated by {opt real}.

{phang}
{opt cpi:base(real)} specifies the base value of the CPI-U-RS for any adjustment. The default is that of September of the survey year.
Note that in the FRB's Survey of Consumer Finances program, CPI values are multiplied by a factor of ten. That is, default for the 2013 survey is 3438, not 343.8.

{phang}
{opt verify} indicates that the results should be checked against the FRB's extract data set. The produced data will be merged with the FRB extract (FRB variables will be prefixed by "EX_") and checked to see that the chartbook data was properly computed from the public data.
Currently, the data does not always match to float. In such cases, verification passes as long as the absolute relative error is less than 1.0X-18 or about 6E-8. (Or, if the absolute value of the data is less than 1.0, verification passes as long as the absolute error is less than 1.0X-18.)

{phang}
{opt keep} holds in memory the verification data as well as the chart book data.


{marker examples}{...}
{title:Example:}

{phang2}{cmd:. buildChartBookData 2013, adjinc}{p_end}
{phang2}{cmd:. buildChartBookData 2007, real adjinc cpibase(3438)}{p_end}

{marker references}{...}
{title:References}

{phang}
Board of Governors of the Federal Reserve System {browse "http://www.federalreserve.gov/econresdata/scf/scfindex.htm":Survey of Consumer Finances}

{phang}
Board of Governors of the Federal Reserve System {browse "http://www.federalreserve.gov/econresdata/scf/scf_2013.htm":2013 Survey of Consumer Finances: Summary Results}

{phang}
Board of Governors of the Federal Reserve System {browse "http://www.federalreserve.gov/econresdata/scf/files/bulletin.macro.txt":SAS program for variable creation}

{phang}
Bureau of Labor Statistics {browse "http://www.bls.gov/cpi/cpiursai1978_2013.pdf":Updated CPI-U-RS, All items, 1978-2013}

{title:Author}

{phang}
David Rosnick, Center for Economic and Policy Research (rosnick@cepr.net)
