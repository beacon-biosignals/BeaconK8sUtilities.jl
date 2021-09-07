# https://github.com/invenia/PkgTemplates.jl/blob/4302ecb0a8f3304ca519796bae70c196794692c9/src/plugin.jl#L306-L316
"""
    gen_file(file, text::AbstractString)

Create a new file containing some given text.
Trailing whitespace is removed, and the file will end with a newline.
"""
function gen_file(file, text::AbstractString)
    mkpath(dirname(file))
    text = strip(join(map(rstrip, split(text, "\n")), "\n")) * "\n"
    return write(file, text)
end


function setup_tensorboard(destination::AbstractString; app::AbstractString,
    logdir::AbstractString,
    ecr::AbstractString = default_ecr(),
    service_account::AbstractString = default_service_account(),
    local_port::Int=6006, overwrite=false)

    isfile(destination) && throw(ArgumentError("""
            Destination $destination exists and is a file.
            Must be a directory (or nonexistent in which case a directory will be created).
        """))

    variables = Dict("app" => app, "logdir" => logdir, "ecr" => ecr, "service_account" => service_account, "local_port" => local_port)

    template_dir = joinpath(TEMPLATES, "tensorboard")

    for name in readdir(template_dir)
        text = render(read(joinpath(template_dir, name), String), variables)
        path = joinpath(destination, name)
        if !overwrite && isfile(path)
            error("$path already exists; set `overwrite=true` to overwrite existing files.")
        end
        @info("Writing $(path)")
        gen_file(path, text)
    end

    @info tensorboard_instructions()

    return nothing
end

tensorboard_instructions() = """
After calling `setup_tensorboard(destination; kwargs...)` to setup the configuration scripts in a destination directory:

1. Run `chmod +x destination/tensorboard.sh` to make the script executable.
2. Run `K8sUtilities.configure_pkg_environment()` to setup a shared `@K8sUtilities` environment to use from the script.

Then running `destination/tensorboard.sh` in a shell should launch a tensorboard pod,
or give you the option to connect to an existing one.

Note:

* You can edit these files freely; running `setup_tensorboard` with `overwrite=true` will replace them with the latest defaults.
* We suggest you set your syntax highlighting for `tensorboard.sh` to `julia`, as it is a Julia script disguised as a shell script.
"""

"""
    configure_pkg_environment(; io=devnull) -> Nothing

Sets up the shared `@K8sUtilities` environment to use from scripts
like `tensorboard.sh`.
"""
function configure_pkg_environment(; io=devnull)
    current_project = Base.active_project()
    try
        # `io=devnull` here suppresses the `Activating environment at...` message.
        Pkg.activate("K8sUtilities"; io, shared=true)
        Pkg.add(; path=joinpath(@__DIR__, ".."), io)
    finally # make sure we switch back
        Pkg.activate(current_project; io)
    end
    return nothing
end

function package_version()
    return TOML.parse(read(joinpath(@__DIR__, "..", "Project.toml"), String))["version"]
end
