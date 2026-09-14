// globalpaths.do

if "`c(username)'" == "matte" {
    global root "C:\Users\matte\OneDrive\SciencesPo\Axelle\CEX\1960-expenditures"
}
else {
    display as error "globalpaths.do: username '`c(username)'' not recognised. Add your entry."
    exit 1
}


* All data live under one folder:
*   $data       -> all_cons_data_for_stata_80_17.dta (shared MS file)
*   $data1935   -> 1935 subfolder: ICPSR 08908 pt3 and pt4 datasets
*   $data1960   -> 1960 subfolder: ICPSR 09035 text data
*   $data2010   -> 2010 subfolder: CEX FMLY datasets
global data      "$root/data"
global data1935  "$data/1935" 
*global data1935p3 "$data1935/08908-0003-Data.dta"   
*global data1935p4 "$data1935/08908-0004-Data.dta" 
global data1960 "$data/1960"
global data2010 "$data/2010"
global oldoutput "$root/old output"
global newoutput "$root/new output"
global cleanoutput "$root/clean output"
global check    "$root/check"
