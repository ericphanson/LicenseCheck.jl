# the largest license in `https://github.com/spdx/license-list-data/blob/v3.10/text`
# is the `APL-1.0` license which is 45 KB.
# We take a factor of 10 larger, to allow for
# compound licenses.
const MAX_LICENSE_SIZE_IN_BYTES = 45958*10

# Based on
# https://github.com/ericphanson/LicenseCheck.jl/issues/2#issue-805995984
const LICENSE_NAMES = let
    names = ("LICENSE", "LICENCE", "COPYING", "NOTICE", "COPYRIGHT") ∪ OSI_LICENSES
    name_cases = (uppercase, uppercasefirst, lowercase)
    ext_cases = (uppercase, lowercase)
    extensions = (".md", ".txt", "", ".rst")
    Set(string(case(name), extcase(ext)) for name in names, case in name_cases, ext in extensions, extcase in ext_cases)
end

# only ~500 items this way
const LOWERCASE_LICENSE_NAMES = Set(lowercase(lic) for lic in LICENSE_NAMES)

const LICENSE_TABLE_TYPE = Vector{@NamedTuple{path::String, licenses::Vector{String}, percent_covered::Float64}}
const LICENSE_TABLE_TYPE_STRING = "Vector{@NamedTuple{path::String, licenses::Vector{String}, percent_covered::Float64}}"

# like `readdir`, but returns only files
readfiles(dir) = filter!(f -> isfile(joinpath(dir, f)), readdir(dir))

# constructs a table of `licensecheck` results
function license_table(dir, names; validate_strings = true, validate_paths = true)
    table = LICENSE_TABLE_TYPE()
    for lic in names
        path = joinpath(dir, lic)
        validate_paths && (isfile(path) || continue)
        text = read(path, String)
        validate_strings && (isvalid(String, text) || continue)
        lc = licensecheck(text)
        if lc.percent_covered > 0
            push!(table, (; path, lc...))
        end
    end
    sort!(table; by = x -> x.percent_covered, rev=true)
    return table
end

"""
    find_licenses_by_list_intersection(dir) -> $(LICENSE_TABLE_TYPE_STRING)

Checks to see if any license name in `LicenseCheck.LICENSE_NAMES` exists
in `dir`, and if so, calls [`licensecheck`](@ref) on it. Returns the results
of all existing licenses and their `licensecheck` values, sorted from highest
`percent_covered` to lowest.

Operates by filtering the results of `readdir`, which should be efficient
for small and moderately sized directories. See [`find_licenses_by_list`](@ref)
for an alternate approach for very large directories.
"""
function find_licenses_by_list_intersection(dir; files = readfiles(dir))
    names = filter!(lic -> lowercase(lic) ∈ LOWERCASE_LICENSE_NAMES, files)
    return license_table(dir, names; validate_paths = false)
end

"""
    find_licenses_by_list(dir) -> $(LICENSE_TABLE_TYPE_STRING)

Checks to see if any license name in `LicenseCheck.LICENSE_NAMES` exists
in `dir`, and if so, calls [`licensecheck`](@ref) on it. Returns the results
of all existing licenses and their `licensecheck` values, sorted from highest
`percent_covered` to lowest.

This function does not ever call `readdir(dir)` and instead just checks if each
of the $(length(LICENSE_NAMES)) names in `LicenseCheck.LICENSE_NAMES` exists,
so it can work on extremely large directories.

On case-insensitive filesystems, this can return multiple results for the same file,
with different cases.
"""
find_licenses_by_list(dir) = license_table(dir, LICENSE_NAMES)

"""
    find_licenses_by_bruteforce(dir; max_bytes = LicenseCheck.MAX_LICENSE_SIZE_IN_BYTES) -> $(LICENSE_TABLE_TYPE_STRING)

Calls [`licensecheck`](@ref) on every plaintext file in `dir` whose size is less than `max_bytes`,
returning the results as a table. The parameter `max_bytes` defaults to $(MAX_LICENSE_SIZE_IN_BYTES ÷ 1000) KiB.
"""
function find_licenses_by_bruteforce(dir; max_bytes = MAX_LICENSE_SIZE_IN_BYTES, files = readfiles(dir))
    names = filter!(file -> stat(joinpath(dir, file)).size < max_bytes, files)
    return license_table(dir, names; validate_paths = false)
end

const CUTOFF = 100

"""
    find_licenses(dir; max_bytes = MAX_LICENSE_SIZE_IN_BYTES) -> $(LICENSE_TABLE_TYPE_STRING)

Compiles a table of possible licenses at the top-level of a directory `dir` with their path and the results of [`licensecheck`](@ref), sorted by `percent_covered`. Uses [`find_licenses_by_bruteforce`](@ref) for directories
with size less than $CUTOFF and [`find_licenses_by_list_intersection`](@ref) for larger directories.

## Example

```julia
julia> find_licenses(".")
5-element Vector{NamedTuple{(:path, :licenses, :percent_covered), Tuple{String, Vector{String}, Float64}}}:
 (path = "./LICENSE", licenses = ["MIT"], percent_covered = 98.82352941176471)
 (path = "./.gitignore", licenses = [], percent_covered = 0.0)
 (path = "./Manifest.toml", licenses = [], percent_covered = 0.0)
 (path = "./Project.toml", licenses = [], percent_covered = 0.0)
 (path = "./README.md", licenses = [], percent_covered = 0.0)
```
"""
function find_licenses(dir; max_bytes = MAX_LICENSE_SIZE_IN_BYTES)
    files = readfiles(dir)
    if length(files) < CUTOFF
        return find_licenses_by_bruteforce(dir; files, max_bytes)
    else
        return find_licenses_by_list_intersection(dir; files)
    end
end

"""
    find_license(dir; max_bytes = MAX_LICENSE_SIZE_IN_BYTES) -> Union{Nothing, @NamedTuple{path::String, licenses::Vector{String}, percent_covered::Float64}}

Returns the license with the highest `percent_covered` from [`find_licenses`](@ref). If file
is found with any license content, returns `nothing`.
"""
function find_license(dir; kwargs...)
    table = find_licenses(dir; kwargs...)
    return isempty(table) ? nothing : table[1]
end
