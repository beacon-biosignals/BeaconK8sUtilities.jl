using K8sUtilities
using Documenter

DocMeta.setdocmeta!(K8sUtilities, :DocTestSetup, :(using K8sUtilities); recursive=true)

makedocs(;
    modules=[K8sUtilities],
    authors="Eric Hanson <5846501+ericphanson@users.noreply.github.com> and contributors",
    repo="https://github.com/ericphanson/K8sUtilities.jl/blob/{commit}{path}#{line}",
    sitename="K8sUtilities.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://ericphanson.github.io/K8sUtilities.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/ericphanson/K8sUtilities.jl",
)
