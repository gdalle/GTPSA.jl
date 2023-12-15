# GTPSA.jl
[![Build Status](https://github.com/bmad-sim/GTPSA.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/bmad-sim/GTPSA.jl/actions/workflows/CI.yml?query=branch%3Amain)

This package provides a full-featured Julia interface to the [Generalised Truncated Power Series Algebra (GTPSA) library](https://github.com/MethodicalAcceleratorDesign/MAD-NG), which computes Taylor expansions of real and complex multivariable functions to arbitrary orders in each of the variables and function parameters individually, chosen by the user. GTPSA also allows distinction between variables $x_i$ and parameters $k_j$ in the function such that $\partial x_i/\partial k_j \neq 0$ but $\partial k_j/\partial x_i = 0$. We refer advanced users to [this paper](https://inspirehep.net/files/286f2ab60e1e7c372cec485337ab5eb6) written by the developers of the GTPSA library for more details.

These generalizations, paired with an efficient monomial indexing function, make GTPSA very fast and memory efficient. See the `benchmark/fodo.jl` example for comparison of GTPSA.jl with ForwardDiff.jl in computing a Taylor map 2nd order in 4 variables and 2 parameters.

## Installation
To use GTPSA.jl, in the Julia REPL simply run

```
] add https://github.com/bmad-sim/GTPSA.jl.git
```

For developers,

```
] dev https://github.com/bmad-sim/GTPSA.jl.git
```

## Basic Usage
First, a `Descriptor` must be created specifying the number of variables, number of parameters, the orders of each variable, and the orders of each parameter for the TPSA(s). A `TPSA` or `ComplexTPSA` can then be created based on the descriptor. TPSAs can be manipulated using all of the elementary math operators (`+`,`-`,`*`,`/`,`^`) and basic math functions (e.g. `abs`, `sqrt`, `sin`, `coth`, etc.). For example, to compute the power series of a function $f$ to 12th order in 2 variables,

```
# Define the TPSAs
d = Descriptor(2, 12)
x1 = TPSA(d)
x2 = TPSA(d)

# Set the TPSAs so they correspond to the variables x1 and x2 
x1[1] = 1
x2[2] = 1

f = sin(x1)*cos(x2)
```

`f` itself is a TPSA. Running `print(f)` then gives the output

```
         :  R, NV =   2, MO = 12
 *******************************************************
     I   COEFFICIENT             ORDER   EXPONENTS
     1   1.0000000000000000E+00    1     1 0
     2   0.0000000000000000E+00    1     0 1
     3  -1.6666666666666666E-01    3     3 0
     4   0.0000000000000000E+00    3     2 1
     5  -5.0000000000000000E-01    3     1 2
     6   0.0000000000000000E+00    3     0 3
     7   8.3333333333333332E-03    5     5 0
     8   0.0000000000000000E+00    5     4 1
     9   8.3333333333333329E-02    5     3 2

                  ...
```
This print function will be rewritten.

The monomials can be accessed with three methods:

1. **Index:** The monomial at index `i` (sorted by order) in the TPSA `t`can be accessed with `t[i]`. WARNING: this is not the number printed under `I` in the `print` output;.
2. **String:** The first monomial in `t` with order `o` can be accessed with `t["o"]`, where the order is written as a string. 
3. **Sparse monomial:*** (in progress)


