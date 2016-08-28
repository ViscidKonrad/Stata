{smcl}
{* *! version 1.0  22oct2015}{...}
{title:Title}

{p2colset 5 20 22 2}{...}
{p2col :{cmd: buildCodes} {hline 2}}Construct country identifier crosswalk{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd: buildCodes} {it:filename} [{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt replace}}overwrite {it:filename} if it exists{p_end}
{synopt :{opt local}}re-download any locally-stored data sources (implies
{bf:replace}){p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:buildCodes} generates a crosswalk of country identifiers across several international data sets.  These identifiers include ISO 3166-1 numeric, alpha-2, alpha-3 codes and English short country names.

{marker examples}{...}
{title:Examples:}

{pstd}Build crosswalk{p_end}
{phang2}{cmd:. buildCodes CountryCodes}{p_end}

{pstd}Use crosswalk{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set obs 2}{p_end}
{phang2}{cmd:. gen ISOAlpha3="USA"}{p_end}
{phang2}{cmd:. replace ISOAlpha3="CAN" in 2}{p_end}
{phang2}{cmd:. merge 1:1 ISOAlpha3 using CountryCodes, nogen}{p_end}
{phang2}{cmd:. keep ISOAlpha3 WEO*}{p_end}
{phang2}{cmd:. li}{p_end}

{marker references}{...}
{title:References}

{phang}
{it:Wikipedia} {browse "http://en.wikipedia.org/wiki/ISO_3166-1":ISO 3166-1}

{phang}
Feenstra, Robert C., Robert Inklaar and Marcel P. Timmer (2015), "The Next Generation of the Penn World Table" forthcoming American Economic Review, available for download at {browse "http://www.rug.nl/research/ggdc/data/pwt/v81/the_next_generation_of_the_penn_world_table.pdf":www.ggdc.net/pwt}

{phang}
Organisation for Economic Co-operation and Development {browse "http://stats.oecd.org/Index.aspx?DataSetCode=EO93_INTERNET":Economic Outlook No 93}

{phang}
The Conference Board {bf: Total Economy Database (TM)}, January 2013, {browse "http://www.conference-board.org/data/economydatabase/"}

{phang}
The World Bank {browse "http://data.worldbank.org/data-catalog/world-development-indicators":World Development Indicators}

{phang}
International Monetary Fund {browse "http://www.imf.org/external/pubs/ft/weo/2013/02/weodata/index.aspx":World Economic Outlook Database October 2013}

{title:Author}

{phang}
David Rosnick, Center for Economic and Policy Research (rosnick@cepr.net)

{title:Also see}

{phang}
{helpb wbopendata}
