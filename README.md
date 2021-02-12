# LicenseCheck

[![Build Status](https://github.com/ericphanson/LicenseCheck.jl/workflows/CI/badge.svg)](https://github.com/ericphanson/LicenseCheck.jl/actions)
[![Coverage](https://codecov.io/gh/ericphanson/LicenseCheck.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/ericphanson/LicenseCheck.jl)

This package exposes some simple license-checking capabilities in Julia.

* Exports a Julia function `licensecheck` which wraps some of the functionality of the Go library [licensecheck](https://github.com/google/licensecheck). This function takes a single string argument `text` and returns a vector of the names of licenses (in fact, the SPDX identifiers of the licenses) matched in `text` and the percent of the text covered by these matches.
* Exports `is_osi_approved`, which given an [SDPX 3.10 identifier](https://spdx.dev/ids/), checks if the corresponding license is [OSI approved](https://opensource.org/licenses).
* Exports `find_license(dir)` which attempts to find the most likely license file in a directory `dir`, as well as `find_licenses`, `find_licenses_by_bruteforce`, `find_licenses_by_list_intersection`, and `find_licenses_by_list` which offer various methods for doing so, each returning a table of possible results.

See the docstrings for more details.

Note that the licensecheck library is available under a BSD-3-Clause license (<https://github.com/google/licensecheck/blob/v0.3.1/LICENSE>), while the wrapping code here is MIT licensed.

## Example

```julia
julia> using LicenseCheck

julia> text = read(joinpath(pkgdir(LicenseCheck), "LICENSE"), String);

julia> result = licensecheck(text)
(licenses_found = ["MIT"], license_file_percent_covered = 98.82352941176471)

julia> all(is_osi_approved, result.licenses_found)
true

julia> is_osi_approved(result) # convenience method for the above
true

julia> find_license(pkgdir(LicenseCheck))
(license_filename = "LICENSE", licenses_found = ["MIT"], license_file_percent_covered = 98.82352941176471)

julia> is_osi_approved(find_license(pkgdir(LicenseCheck)))
true

```
