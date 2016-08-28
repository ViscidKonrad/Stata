{smcl}
{* *! version 0.3  09sep2014}{...}
{title:Title}

{p2colset 5 20 22 2}{...}
{p2col :{cmd: addSCFQuantiles} {hline 2}}Create quantiles in the manner of the FRB Survey of Consumer Finances{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd: addSCFQuantiles} {newvar} {cmd:=} {varname} {cmd:,} {it:options}

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt at(numlist)}}quantiles at which to cut{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}You must {cmd:svyset} your data before using {cmd:addSCFQuintiles}; see
{helpb svyset:[SVY] svyset}. {cmd: addSCFQuintiles} allows {helpb by}.

{marker description}{...}
{title:Description}

{pstd}
{cmd:addSCFQuantiles} creates quantile categories as defined by the Survey of Consumer Finances produced by the Federal Reserve.

{pstd}
{newvar} is the name of a new variable containing the quintile categories.

{pstd}
{varname} is the name of the variable upon which the quintiles are to be based.

{marker options}{...}
{title:Options}

{phang}
{opt at(numlist)} contains the internal quantile breaks. 0 and 100 are implied and should not be included.

{marker examples}{...}
{title:Example:}

{phang2}{cmd:. buildChartBookData 2010, adjinc}{p_end}
{phang2}{cmd:. addSCFQuantiles INC2=INCOME, at(10(10)90 95 99)}{p_end}

{marker references}{...}
{title:References}

{phang}
Board of Governors of the Federal Reserve System {browse "http://www.federalreserve.gov/econresdata/scf/scfindex.htm":Survey of Consumer Finances}

{title:Author}

{phang}
David Rosnick, Center for Economic and Policy Research (rosnick@cepr.net)

{title:Also see}

{phang}
{helpb buildChartBookData}
