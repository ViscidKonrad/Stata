{smcl}
{* *! version 0.8  20apr2016}{…}
{title:Title}

{p2colset 5 20 22 2}{...}
{p2col :{cmd: getWEO} {hline 2}}Retrieve data from IMF World Economic Outlook{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd: getWEO} {it:countryvar} {it:datanames} [{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Source}
{synopt :{opt weoy:ear(#)}}WEO database year; default is {cmd:weoyear(2016)}{p_end}
{synopt :{opt weov:ersion(#)}}WEO database number; default is {cmd:weoversion(1)}{p_end}

{synopt :{opt s:tart(#)}}first year of data to retrieve; default is {cmd:start(1980)}{p_end}
{synopt :{opt e:nd(#)}}last year of data to retrieve; default is {cmd:end(2021)}{p_end}

{syntab:Country identification}
{synopt :{it:{help getWEO##countryvar_options:countryvar_options}}}options to help identify the source and type of country variable{p_end}

{syntab:Reporting}
{synopt: {opt clean}}clean data but do not merge with master{p_end}
{synopt: {opt raw}}return data as is{p_end}

{synopt: {opt est:imates}}({opt clean} only) retain WEO variable indicating data point is a forecast{p_end}
{synopt: {opt scale}}({opt clean} only) retain WEO variable indicating scale{p_end}
{synopt: {opt units}}({opt clean} only) retain WEO variable indicating units{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:getWEO} retrieves data from the International Monetary Fund's World Economic Outlook. For every country listed in {it:countryvar}, {cmd:getWEO} reports the IMF data listed in {it:datanames}.

{pstd}
{it:countryvar} is a variable that may contain three-digit numeric codes, two- or three-letter alpha codes, or country names.  These codes may correspond to the official ISO 3166-1 standards, IMF codes, or one of several other data sources. See
{it:{help getWEO##countryvar_options:countryvar_options}} for details.

{pstd}
{it:datanames} is a list of one or more codes for WEO Subject Codes; default is {cmd: NGDP_R}. A partial list of codes include:

{synoptset 20}{...}
{p2col:WEO Subject Code}Subject Descriptor (Units){p_end}
{synoptline}
{synopt :{opt NGDP_R}}Gross domestic product, constant prices (National currency){p_end}
{synopt :{opt NGDP_RPCH}}Gross domestic product, constant prices (Percent change){p_end}
{synopt :{opt LUR}}Unemployment rate (Percent of total labor force){p_end}
{synopt :{opt GGXWDN_NGDP}}General government net debt (Percent of GDP){p_end}
{synoptline}
{pstd}
A full list of the latest variables is available at {browse "http://www.imf.org/external/pubs/ft/weo/2016/01/weodata/index.aspx":World Economic Outlook Database April 2016}

{pstd}
Note that {cmd:getWEO} currently requires the code/name crosswalk (CountryCodes.dta) to translate {it:countryvar} to WEO country codes. See
{helpb buildCodes:buildCodes} for details.

{marker options}{...}
{title:Options}

{dlgtab:Source}

{phang}
{opt weoyear(#)} is the year in which the source WEO database was released.

{phang}
{opt weoversion(#)} is the version of the source WEO database in the release year.  Typically, {cmd:weoversion(1)} is a Spring release and {cmd:weoversion(2)} is a Fall release.

{phang}
{opt start(#)} indicates the first year of data to be retrieved. In its current format, the WEO databases go back to 1980.

{phang}
{opt end(#)} indicates the last year of data to be retrieved. In its most recent incarnations, the WEO databases go forward five years ({it:e.g.,} 2018 for 2013 WEOs.)

{marker countryvar_options}{...}
{dlgtab:Country identification}

{phang}
{it:{opt countryvar_options}} help identify the source and type of country variable. None of these options need be specified, but in some cases may be useful. See {helpb idCodes} {help idCodes##examples:Examples}.

{synoptset 20}{...}
{p2col:{it: countryvar_option}}Description{p_end}
{synoptline}
{synopt :{opt iso}}{it:countryvar} may identify an ISO code or name{p_end}
{synopt :{opt mad}}{it:countryvar} may identify a name from Angus Maddison's database{p_end}
{synopt :{opt mpd}}{it:countryvar} may identify a name from the Maddison Project Database{p_end}
{synopt :{opt oecd}}{it:countryvar} may identify a code or name from the OECD Economic Outlook{p_end}
{synopt :{opt ted}}{it:countryvar} may identify a code or name from the Total Economy Database{p_end}
{synopt :{opt wdi}}{it:countryvar} may identify a code or name from the World Bank's World Development Indicators{p_end}
{synopt :{opt weo}}{it:countryvar} may identify a code or name from the IMF World Economic Outlook{p_end}

{synopt :{opt alpha2}}{it:countryvar} may identify a two-letter country code{p_end}
{synopt :{opt alpha3}}{it:countryvar} may identify a three-letter country code{p_end}
{synopt :{opt c:ountryname}}{it:countryvar} may identify a country name{p_end}
{synopt :{opt n:umeric}}{it:countryvar} may identify a numeric code{p_end}
{synoptline}
{p2colreset}{...}

{marker examples}{...}
{title:Example:}

{pstd}Setup{p_end}
{phang2}{cmd:. buildCodes CountryCodes}{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set obs 2}{p_end}
{phang2}{cmd:. gen Country="USA"}{p_end}
{phang2}{cmd:. replace Country="CAN" in 2}{p_end}

{pstd}Get nominal GDP data for the United States and Canada{p_end}
{phang2}{cmd:. getWEO Country NGDP}{p_end}

{title:Author}

{phang}
David Rosnick, Center for Economic and Policy Research (rosnick@cepr.net)

{title:Also see}

{phang}
{helpb buildCodes} {helpb idCodes}
