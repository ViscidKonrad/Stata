{smcl}
{* *! version 0.2  22oct2015}{...}
{title:Title}

{p2colset 5 20 22 2}{...}
{p2col :{cmd: idCodes} {hline 2}}Determine form of country identifier{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd: idCodes} {it:countryvar} [{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Source}
{synopt :{opt iso}}{it:countryvar} may identify an official ISO code or name{p_end}
{synopt :{opt oecd}}{it:countryvar} may identify a code or name from the OECD Economic Outlook{p_end}
{synopt :{opt pwt}}{it:countryvar} may identify a name from the Penn World Tables{p_end}
{synopt :{opt ted}}{it:countryvar} may identify a code or name from the Total Economy Database{p_end}
{synopt :{opt wdi}}{it:countryvar} may identify a code or name from the World Bank's World Development Indicators{p_end}
{synopt :{opt weo}}{it:countryvar} may identify a code or name from the IMF World Economic Outlook{p_end}

{syntab:Format}
{synopt :{opt alpha2}}{it:countryvar} may identify a two-letter country code{p_end}
{synopt :{opt alpha3}}{it:countryvar} may identify a three-letter country code{p_end}
{synopt :{opt c:ountryname}}{it:countryvar} may identify a country name{p_end}
{synopt :{opt n:umeric}}{it:countryvar} may identify a numeric code{p_end}
{synoptline}
{pstd}Any number of options are allowed

{marker description}{...}
{title:Description}

{pstd}
{cmd:idCodes} returns a country identifier's possible canonical variable names-- that is, those variable names in the identifier crosswalk which may correspond. See {helpb buildCodes}.

{pstd}
{it:countryvar} is the name of the country identifier of undetermined source and/or format.


{marker options}{...}
{title:Options}

{dlgtab:Source}

{phang}
Source options limit the search for possible data sources to any of those explicitly specified. By default, all sources are possible.

{dlgtab:Format}

{phang}
Format options limit the search for possible identifier formats to any of those explicitly specified. By default, all formats are possible.

{marker examples}{...}
{title:Examples:}

{pstd}Setup{p_end}
{phang2}{cmd:. buildCodes CountryCodes}{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set obs 2}{p_end}
{phang2}{cmd:. gen Country="USA"}{p_end}
{phang2}{cmd:. replace Country="CAN" in 2}{p_end}

{pstd}Identify canonical name for {bf:Country}{p_end}
{phang2}{cmd:. idCodes Country, iso}{p_end}

{pstd}Canonical name may be indeterminate if insufficiently specified{p_end}
{phang2}{cmd:. idCodes Country}{p_end}

{pstd}Identify an alternative canonical name for {bf:Country}{p_end}
{phang2}{cmd:. idCodes Country, weo}{p_end}

{pstd}Identification failure-- {bf:Country} is not numeric{p_end}
{phang2}{cmd:. idCodes Country, numeric}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:idCodes} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(codeVar)}}canonical name (on success){p_end}
{synopt:{cmd:r(codeVars)}}possible canonical names (if insufficiently identified){p_end}

{title:Author}

{phang}
David Rosnick, Center for Economic and Policy Research (rosnick@cepr.net)

{title:Also see}

{phang}
{helpb buildCodes}
