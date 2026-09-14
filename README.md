# Household Expenditure Inequality in the CEX

## Goals

Building household-level expenditure to produce expenditure inequality statistics
across three historical waves of the U.S. Consumer Expenditure Survey.

## Data

Not distributed here, but publicly available from ICPSR:

- 1935–36: ICPSR 08908 (datasets part 3 and part 4)
- 1960–61: ICPSR 09035 (text file)
- 2009–2011: ICPSR 32483 (FMLI files)

To run everything, place each of these in a subfolder of `data`, named `1935`,
`1960` and `2010` respectively. The Meyer–Sullivan consumption file
`all_cons_data_for_stata_80_17.dta` goes directly in `data`, not in any
subfolder:

```
data/
├── all_cons_data_for_stata_80_17.dta
├── 1935/
├── 1960/
└── 2010/
```

## Structure of the repo

The `1935` and `1960` folders contain the code that produces the output in
`old output`.

The `2010` folder instead contains an `_oldmain` that feeds `old output`, and a
`p0`, `p1`, `p2` structure that feeds `new output` and `check output`, in which
we check for different ways of aggregating and weighting the 2010, 2009 and 2011
data.

Finally, in the `final code` folder you'll find what we opted for in the final
work, containing only the 1960 and 2010 waves and a `main`. The output is in
`final output`.
