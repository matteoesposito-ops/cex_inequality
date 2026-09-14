*======================================================================
* master.do  —  run the CEX cleaning in the REQUIRED order.
* 2010 MUST run before 1960: 2010 writes ratio_2010.do, 1960 reads it.
* Run this from the CEX folder (so ../globalpaths.do resolves).
*======================================================================
clear all
set more off

do "2010_clean.do"      // computes rfg_c, writes $cleanoutput/ratio_2010.do
do "1960_clean.do"      // reads that ratio via `do`

di as result "CEX cleaning complete: 2010 then 1960 (ratio fresh)."
