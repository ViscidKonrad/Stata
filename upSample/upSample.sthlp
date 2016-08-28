{smcl}
{* *! version 1.0 02mar2016}{...}
{cmd:help upSample}
{hline}

{title:Title}

{phang}
{bf:upSample -- Resample time-series data at a higher frequency}


{title:Syntax}

{p 8 17 2}
{cmdab:upSample}
{varlist}
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt fm(#)}}impute {it:#} observations for every source observation{p_end}
{synopt:{opt s:uffix(string)}}suffix to attach to new variables; default is {bf:_x} where {bf:x} is the unit of the new time variable ({it:e.g.}, {bf:_q} or {bf:_m}){p_end}
{synopt:{opt local}}polynomial interpolation; default is to minimize average curvature{p_end}

{syntab:Local}
{synopt:{opt o:rder(#)}}order of interpolation; default is {cmd:order(2)}{p_end}
{synoptline}
{p2colreset}{...}

{p 4 6 2}


{title:Description}

{pstd}
{cmd:upSample} takes low-frequency source data which represents multi-period averages and produces plausible high-frequency data consistent with the known average.
For example, from annual GDP data {cmd:upSample} may estimate quarterly GDP at annual rates.


{title:Options}

{dlgtab:Main}

{phang}
{opt fm(#)} imputes {it:#} observations for every source observation ({it:e.g.}, {cmd:fm(4)} produces quarterly data from annual); default varies by source frequency

{phang}
{opt s:uffix(string)} suffix to attach to new variables; default is {bf:_x} where {bf:x} is the unit of the new time variable ({it:e.g.}, {bf:_q} or {bf:_m})

{phang}
{opt local} uses low-order polynomials to create the high-frequency data; by default, {cmd:upSample} interpolates by finding the set of points which minimize average curvature while still reproducing the low-frequency data

{dlgtab:Local}

{phang}
{opt o:rder(#)} order of polynomial interpolation; default is {cmd:order(2)} (quadratic)

{title:Remarks}

{pstd}
Data must be {cmd:tsset}; see {manhelp tsset TS} as {cmd:upSample} obtains a default frequency multiple based on the unit of the current time variable.
Specifically, {cmd:upSample} estimates quarterly data from yearly, monthly from halfyearly or quarterly, daily from weekly and otherwise produces three (generic) data points per observation.{p_end}

{pstd}
{cmd:upSample} minimizes (by default) the average curvature of the interior points, subject to the constraints that the high-frequency points in each low-frequency period average the low-frequency data. Alternatively, {cmd:upSample} works by determining a special set of nodes by which local polynomial interpolation yields high-frequency data.  The values at each node are computed so that the interpolated values have mean equal to that of the original data.

{pstd}
If {cmd:local} is specified, {cmd:upSample} will handle missing data either at the beginning or end of the time series by extrapolating to these points, but {cmd:upSample}will never handle correctly gaps in the data.

{title:Example}

{phang}{stata "webuse m1gdp, clear":. webuse m1gdp, clear}{p_end}
{phang}{stata "gen GDP = exp(ln_gdp)":. gen GDP = exp(ln_gdp)}{p_end}
{phang}{stata "upSample GDP, order(10)":. upSample GDP}{p_end}
{phang}{stata "tsline GDP GDP_m if tin(1975m1,1984m12), connect(J)":. tsline GDP GDP_m if tin(1980m1,1989m12), connect(J)}{p_end}


{title:Author}

{pstd}
David Rosnick, {browse "http://cepr.net":Center for Economic and Policy Research}{p_end}
{pstd}
rosnick@cepr.net{p_end}


{title:References}

{pstd}
Szeg{c o:}, G. Orthogonal Polynomials, 4th ed. Providence, RI: Amer. Math. Soc., pp. 329 and 332, 1975.{p_end}


{title:Also see}

{psee}Manual: {manhelp tsset TS}{p_end}
{psee}Online: {browse "http://mathworld.wolfram.com/LagrangeInterpolatingPolynomial.html":Wolfram MathWorld}{p_end}

