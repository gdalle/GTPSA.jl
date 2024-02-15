# [`vars`, `params`](@id varsparams)
*Creates a vector of TPSs corresponding to each variable/parameter in the GTPSA*
## Syntax
```
x  = vars([use=(descriptor|tps|complextps)])
xc = complexvars([use=(descriptor|tps|complextps)])

k  = params([use=(descriptor|tps|complextps)])
kc = complexparams([use=(descriptor|tps|complextps)])
```

## Description
`x = vars()` creates a vector of `TPS`s corresponding to each of the variables in the GTPSA defined by the `Descriptor` in `GTPSA.desc_current`

`x = complexvars()` creates a vector of `ComplexTPS`s corresponding to each of the variables in the GTPSA defined by the `Descriptor` in `GTPSA.desc_current`

------

`k = params()` creates a vector of `TPS`s corresponding to each of the parameters in the GTPSA defined by the `Descriptor` in `GTPSA.desc_current`

`k = complexparams()` creates a vector of `ComplexTPS`s corresponding to each of the parameters in the GTPSA defined by the `Descriptor` in `GTPSA.desc_current`

### Optional Keyword Argument

`use=descriptor` creates a vector of `TPS`/`ComplexTPS`s corresponding to each of the variables/parameters in the GTPSA defined by the passed `Descriptor`

`use=(tps|complextps)` creates a vector of `TPS`/`ComplexTPS`s corresponding to each of the variables/parameters in the GTPSA defined by the `Descriptor` of the passed `TPS` or `ComplexTPS`


## Examples
```@repl desc
using GTPSA; GTPSA.show_sparse = false;   GTPSA.show_header=false;#hide
d1 = Descriptor(3, 5, 2, 5); # 3 vars, 2 params, all to order 5
x1 = vars()
k1 = params()
d2 = Descriptor(2, 5, 1, 5); # 2 vars, 1 param, all to order 5
x2 = vars()
k2 = params()
k1 = params(use=d1)
```

## Documentation
```@docs
vars
complexvars
params
complexparams
```