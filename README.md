# BeaconK8sUtilities

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://beacon-biosignals.github.io/BeaconK8sUtilities.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://beacon-biosignals.github.io/BeaconK8sUtilities.jl/dev)
[![Build Status](https://github.com/beacon-biosignals/BeaconK8sUtilities.jl/workflows/CI/badge.svg)](https://github.com/beacon-biosignals/BeaconK8sUtilities.jl/actions)

BeaconK8sUtilities currently provides two types of functionality:

* [utilities](https://beacon-biosignals.github.io/BeaconK8sUtilities.jl/dev/utilities/): simple Julia functions to call `kubectl`
  (provided by `kubectl_jll`) and parse the results, e.g. [`get_status(pod)`](https://beacon-biosignals.github.io/BeaconK8sUtilities.jl/dev/utilities/#BeaconK8sUtilities.get_status-Tuple{Any}).
* [templates](https://beacon-biosignals.github.io/BeaconK8sUtilities.jl/dev/templates/): templates to set up shell scripts and YAML files
  to perform tasks, launch pods, etc.

This utilities are intended to be general-purpose, but they are probably fairly specific to Beacon's kubernetes setup currently. For that reason, BeaconK8sUtilities is only registered in Beacon's private package registry at this point.

## Utility example

```julia
julia> using BeaconK8sUtilities

julia> get_pod_names()
2-element Vector{String}:
 "my-example-pod-1"
 "my-example-pod-2"
 
julia> get_status("my-example-pod-1")
"Running"

julia> last_condition("my-example-pod-1")
JSON3.Object{Base.CodeUnits{UInt8, SubString{String}}, Vector{UInt64}} with 4 entries:
  :lastProbeTime      => nothing
  :lastTransitionTime => "2021-09-10T22:51:37Z"
  :status             => "True"
  :type               => "PodScheduled"
 
```

## Template example

We can easily setup a simple script to follow as a pod launches:
```julia
julia> using BeaconK8sUtilities

julia> setup_follow("scripts")

```

Then we can run `./scripts/follow.sh pod_name` from our shell and get
a progress bar as we wait for the pod to startup, and then the logs streamed
once it is ready. (This is just like
`kubectl wait --for=condition=Ready $pod_name && kubectl logs -f $pod_name`
except that there's progress information printed as the pod gets ready).

This could be adapted into a whole "launch script" including building a docker image,
pushing it to an ECR, launching a pod, and then following along.
Such a script can be facilitated by the Julia-side utilities and preferences
provided in K8sUtilites.jl; see the [documentation](https://beacon-biosignals.github.io/BeaconK8sUtilities.jl/dev) for more.

See in particular [`setup_tensorboard`](https://beacon-biosignals.github.io/BeaconK8sUtilities.jl/dev/templates/#BeaconK8sUtilities.setup_tensorboard-Tuple{AbstractString})
for a more involved example.
