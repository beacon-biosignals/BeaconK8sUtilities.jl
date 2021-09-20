using BeaconK8sUtilities
using Documenter

DocMeta.setdocmeta!(BeaconK8sUtilities, :DocTestSetup, :(using BeaconK8sUtilities);
                    recursive=true)

makedocs(; modules=[BeaconK8sUtilities],
         repo="https://github.com/beacon-biosignals/BeaconK8sUtilities.jl/blob/{commit}{path}#{line}",
         sitename="BeaconK8sUtilities.jl",
         format=Documenter.HTML(; prettyurls=get(ENV, "CI", "false") == "true",
                                canonical="https://beacon-biosignals.github.io/BeaconK8sUtilities.jl",
                                assets=String[], ansicolor=true),
         pages=["Home" => "index.md", "Utilities" => "utilities.md",
                "Templates" => "templates.md", "Preferences" => "preferences.md"])

deploydocs(; repo="github.com/beacon-biosignals/BeaconK8sUtilities.jl", push_preview=true,
           devbranch="main")
