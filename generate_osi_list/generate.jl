using JSON3, HTTP

url = "https://raw.githubusercontent.com/spdx/license-list-data/v3.10/json/licenses.json"
r = HTTP.request("GET", url)
spdx = JSON3.read(String(r.body))

@assert spdx.licenseListVersion == "3.10"

osi_licenses = sort!([lic.licenseId for lic in spdx.licenses if lic.isOsiApproved])

open(joinpath(@__DIR__, "..", "src", "OSI_LICENSES.jl"); write=true) do io
    header = """
            # THIS FILE IS MACHINE-GENERATED
            # See `../generate_osi_list` for more information."""
    start = "const OSI_LICENSES = Set(["
    spaces = " "^textwidth(start)
    println(io, header)
    println(io, start, "\"", osi_licenses[1], "\",")
    for id in osi_licenses[2:(end - 1)]
        println(io, spaces, "\"", id, "\",")
    end
    return println(io, spaces, "\"", osi_licenses[end], "\"])")
end
