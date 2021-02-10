# LicenseCheck

[![Build Status](https://github.com/ericphanson/LicenseCheck.jl/workflows/CI/badge.svg)](https://github.com/ericphanson/LicenseCheck.jl/actions)
[![Coverage](https://codecov.io/gh/ericphanson/LicenseCheck.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/ericphanson/LicenseCheck.jl)

Exports a single Julia function `licensecheck` which wraps some of the functionality of the Go library [licensecheck](https://github.com/google/licensecheck) which takes a single string argument `text` and returns a vector of the names of licenses (in fact, the "license ID"s) matched in `text` and the percent of the text covered by these matches. See the docstring of `licensecheck` for more details.

Note that the licensecheck library is available under a BSD-3-Clause license (<https://github.com/google/licensecheck/blob/v0.3.1/LICENSE>), while the wrapping code here is MIT licensed.

## Example

```julia
julia> using LicenseCheck

julia> text = read(joinpath(pkgdir(LicenseCheck), "LICENSE"), String);

julia> licensecheck(text)
(licenses = ["MIT"], percent_covered = 98.82352941176471)
```
