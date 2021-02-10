using LicenseCheck
using Documenter

makedocs(;
    modules=[LicenseCheck],
    authors="Eric P. Hanson",
    repo="https://github.com/ericphanson/LicenseCheck.jl/blob/{commit}{path}#L{line}",
    sitename="LicenseCheck.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://ericphanson.github.io/LicenseCheck.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/ericphanson/LicenseCheck.jl",
)
