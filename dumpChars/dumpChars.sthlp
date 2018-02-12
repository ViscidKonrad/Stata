{smcl}
{* *! version 0.1  13nov2017}{...}
{title:Title}

{p2colset 5 20 22 2}{...}
{p2col :{cmd: dumpChars} {hline 2}}Display character set{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd: dumpChars}

{marker description}{...}
{title:Description}

{pstd}
{cmd:dumpChars} simply displays the current character set. With the transition to Unicode, not especially useful as of Stata 14.

{marker examples}{...}
{title:Examples:}

{phang2}{cmd:. dumpChars}{p_end}

{title:Author}

{phang}
David Rosnick, Center for Economic and Policy Research (rosnick@cepr.net)

{title:Also see}

{phang}
{helpb hexdump}
