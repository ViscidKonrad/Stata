{smcl}
{* *! version 0.1  14may2014}{...}
{title:Title}

{p2colset 5 20 22 2}{...}
{p2col :{cmd: chain} {hline 2}}Create chained-currency estimates from component price/quantity data{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd: chain} {varlist} {cmd:,} {opt b:ase(date)} {opt g:enerate(namelist)} [{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt :{opt b:ase(date)}}target base period for the index{p_end}
{synopt :{opt g:enerate(namelist)}}list of variable names for the chained-currency estimates{p_end}
{p2coldent :* {opt pq(varlist)}}list of nominal component values{p_end}
{p2coldent :* {opt p(varlist)}}list of component price indices{p_end}
{p2coldent :* {opt q(varlist)}}list of component quantity indices{p_end}

{syntab:Index Type}
{synopt :{opt fisher}}compute Fisher indices (default){p_end}
{synopt :{opt laspeyres}}compute Laspeyres indices{p_end}
{synopt :{opt paasche}}compute Paasche indices{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}* At least two of {opt pq(varlist)}, {opt p(varlist)}, and {opt q(varlist)} are required.{p_end}
{p 4 6 2}You must {cmd:tsset} your data before using {cmd:tsappend}; see
{helpb tsset:[TS] tsset}.

{marker description}{...}
{title:Description}

{pstd}
{cmd:chain} creates aggregate chained-currency estimates from data on expenditure components. Multiple panels are permitted.

{pstd}
{varlist} is a list of the nominal aggregate expenditures for which chained-currency estimates are sought. Each aggregate must be a linear combination of the nominal component values specified in {cmd: pq}, {cmd: p}, and/or {cmd: q}.

{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{opt b:ase(date)} is the base period for the index.  The period may span several time steps, so {cmd: base(2008)} is valid for quarterly data as well as {cmd: base(2008m1)}.  In the latter case, the chained-dollar index for 2008q1 will equal the nominal aggregate in 2008q1, and in the former the chained-dollar average over the four quarters of 2008 will equal the average of the nominal aggregate over the same four quarters.

{phang}
{opt g:enerate(namelist)} supplies the names for the chained-currency estimates.  There must be one name supplied per aggregate in {varlist}.

{phang}
{opt pq(varlist)}, {opt p(varlist)}, and {opt q(varlist)} list the variables which may contain component data (respectively: nominal expenditure, price, and/or quantity) which make up the aggregates in {varlist}. The component order does not matter, but must be consistent from one option to the next.  (For example, the fifth variable in {cmd: p} is the price of the component with quantity specified by the fifth variable in {cmd: q}.) At least two of the three must be specified. If the third is not specified, it will be computed from the other two.  (If {cmd: p} and {cmd: q} are specified, then {cmd: pq} will be the product of {cmd: p} and {cmd: q}.)

{dlgtab:Index Type}

{phang}
Any of {cmd: fisher}, {cmd: laspeyres}, or {cmd: paasche} may be specified.  If none are specified, then the chained index will be of type Fisher.  If multiple types are specified, then the type will be selected alphabetically.  (That is, if {cmd: laspeyres} and {cmd: paasche} are both specified but {cmd: fisher} is not, then the index will be Laspeyres.)

{marker examples}{...}
{title:Example:}

{phang2}{cmd:. gen DD = PC*C + PI*I + PG*G}{p_end}
{phang2}{cmd:. gen GDP = DD + PX*X - PM*M}{p_end}
{phang2}{cmd:. chain GDP DD, base(2008) generate(realGDP realDD) p(PC PI PG PX PM) q(C I G X M)}{p_end}

{title:Author}

{phang}
David Rosnick, Center for Economic and Policy Research (rosnick@cepr.net)

