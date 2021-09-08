#!/bin/bash
# Try to get proper highlighting (as a julia script):
# vim: ts=4:sw=4:et:ft=julia
# -*- mode: julia -*-
# code: language=julia
#
# This can be launched as a bash script-- it will `exec` into a Julia process and run the script.
# It can also just be run or included as a Julia script.
#=
exec julia --color=yes --startup-file=no -q --compile=min -O0 "${BASH_SOURCE[0]}" "$@"
=#

using K8sUtilities

LOCAL_PORT = {{{local_port}}}
LABELS = `-l app={{{app}}},target=tensorboard`
NAMESPACE = "{{{ namespace }}}"

tensorboard_pods = get_pod_names(LABELS; namespace=NAMESPACE)

go = (pod) -> begin
    wait_until_pod_ready(pod; namespace=NAMESPACE)
    port_forward(pod; remote_port=6006, local_port=LOCAL_PORT, namespace=NAMESPACE)
    println("Following logs on pod...")
    watch_logs(pod; exit_on_interrupt=true, namespace=NAMESPACE)
end

if length(tensorboard_pods) == 1
    pod = "pod/"*tensorboard_pods[1]
    result = Base.prompt("Existing pod $pod found. Port-forward to it?"; default="yes")
    if lowercase(result) in ("yes", "y")
        go(pod)
        exit(0)
    end
end

if !isempty(tensorboard_pods)
    error("""
    One or more tensorboard pods are already running!
    
    $(tensorboard_pods)

    Kill them with
    ```
    kubectl delete pods $(string(LABELS))
    ```
    and see which pods they are with
    ```
    kubectl get pods $(string(LABELS))
    ```

    If you want to setup port-forwarding to an existing pod, run
    ```
    kubectl port-forward POD_NAME $(LOCAL_PORT):6006
    ````
    with `POD_NAME` chosen from the `get pods` command above.

    (You could of course comment out this check to proceed!).
    """)
end

# Use `ENV` variables for `envsubst` later on.
ENV["IMAGE_NAME"] = IMAGE_NAME = "{{{ ecr }}}:{{{ app }}}-tensorboard"
ENV["LOGDIR"] = "{{{ logdir }}}"

println("Building dockerfile...")
run(`docker build $(@__DIR__) --file $(@__DIR__)/tensorboard.dockerfile -t $IMAGE_NAME`)

println("Pushing dockerfile...")
run(`docker push $IMAGE_NAME`)

output = readchomp(pipeline("$(@__DIR__)/tensorboard.yaml", `envsubst`, `$(kubectl()) create -f -`))
println(output)
pod = split(output)[1]

go(pod)
