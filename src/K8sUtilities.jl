module K8sUtilities

using ProgressMeter, JSON3, kubectl_jll
using Preferences
using Mustache
using RelocatableFolders
using Compat

const TEMPLATES = @path joinpath(@__DIR__, "..", "templates")

export get_status, last_condition, wait_until_pod_ready, watch_logs, port_forward_and_log,
       get_current_namespace

include("utilities.jl")

export default_ecr, default_service_account
include("preferences.jl")

export setup_tensorboard
include("templates.jl")

end # module
