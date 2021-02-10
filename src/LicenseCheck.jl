module LicenseCheck

using licensecheck_jll: licensecheck_jll

export licensecheck

"""
    licensecheck(text::String) -> @NamedTuple{licenses::Vector{String}, percent_covered::Float64}

Returns a vector of the names of licenses (in fact, the "license ID"s) matched in `text` and the percent of the text covered by these matches.

The full list of license IDs is located at <https://github.com/google/licensecheck/blob/v0.3.1/licenses/README.md>, and includes the SDPX 3.10 licenses, <https://github.com/spdx/license-list-data/tree/v3.10/text>.

This provides some of the functionality of `licensecheck.Scan` in the original Go library (<https://github.com/google/licensecheck>).

## Example

```julia
julia> using LicenseCheck

julia> text = read(joinpath(pkgdir(LicenseCheck), "LICENSE"), String);

julia> licensecheck(text)
(licenses = ["MIT"], percent_covered = 98.82352941176471)
```
"""
function licensecheck(text::String)
    arr, dims, percent_covered = ccall((:License, licensecheck_jll.licensecheck),
                                       Tuple{Ptr{Ptr{UInt8}},Cint,Float64}, (Cstring,),
                                       text)
    return (; licenses=unsafe_string.(unsafe_wrap(Array, arr, dims; own=true)),
            percent_covered=percent_covered)
end

end
