{smcl}
{* *! version 0.1  09sep2014}{...}
{title:Title}

{p2colset 5 20 22 2}{...}
{p2col :{cmd: addSCFYear} {hline 2}}Load FRB's Survey of Consumer Finances extract data{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd: addSCFYear} {it: year}

{marker description}{...}
{title:Description}

{pstd}
{cmd: addSCFYear} simply loads up the Survey of Consumer Finances extract data produced by the Federal Reserve. If necessary, it downloads the data, creating a Data subdirectory in the current working directory.

{pstd}
{it: year} is the year of the survey, available every three years back to 1989. Default is 2013.

{marker examples}{...}
{title:Example:}

{phang2}{cmd:. addSCFYear 2013}{p_end}

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
