# K8sUtilities

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://beacon-biosignals.github.io/K8sUtilities.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://beacon-biosignals.github.io/K8sUtilities.jl/dev)
[![Build Status](https://github.com/beacon-biosignals/K8sUtilities.jl/workflows/CI/badge.svg)](https://github.com/beacon-biosignals/K8sUtilities.jl/actions)


## Example

We can easily setup a simple script to follow as a pod launches:
```julia
julia> using K8sUtilities

julia> setup_follow("scripts")

```

Then we can run `./scripts/follow.sh pod_name` from our shell and get
a progress bar as we wait for the pod to startup, and then the logs streamed
once it is ready. (This is just like `kubectl logs -f pod_name` except that
we don't have to wait for the pod to be ready first).

This could be adapted into a whole "launch script" including building a docker image,
pushing it to an ECR, launching a pod, and then following along.
Such a script can be facilitated by the Julia-side utilities and preferences
provided in K8sUtilites.jl; see the [documentation](https://beacon-biosignals.github.io/K8sUtilities.jl/dev) for more.
