using K8sUtilities
using Documenter

DocMeta.setdocmeta!(K8sUtilities, :DocTestSetup, :(using K8sUtilities); recursive=true)

makedocs(;
    modules=[K8sUtilities],
    repo="https://github.com/beacon-biosignals/K8sUtilities.jl/blob/{commit}{path}#{line}",
    sitename="K8sUtilities.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://beacon-biosignals.github.io/K8sUtilities.jl",
        assets=String[],
        ansicolor=true,
    ),
    pages=[
        "Home" => "index.md",
        "Utilities" => "utilities.md",
        "Templates" => "templates.md",
        "Preferences" => "preferences.md"
    ],
)

deploydocs(;
    repo="github.com/beacon-biosignals/K8sUtilities.jl",
    push_preview=true,
    devbranch = "main",
)
