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

if !isempty(tensorboard_pods)
    # `pagesize` is the number of items to be displayed at a time.
    #  The UI will scroll if the number of options is greater
    #   than the `pagesize`
    menu = RadioMenu(tensorboard_pods, pagesize=4)

    # `request` displays the menu and returns the index after the
    #   user has selected a choice
    choice = request("Port-foward to existing pod?", menu)

    if choice != -1
        go(tensorboard_pods[choice])
        exit(0)
    else
        println("Proceeding to launch new pod.")
    end
end

# Use `ENV` variables for `envsubst` later on.
ENV["IMAGE_NAME"] = IMAGE_NAME = "{{{ ecr }}}:{{{ app }}}-tensorboard"

# set the `LOGDIR` env variable if the user has not
get!(ENV, "LOGDIR", "{{{ logdir }}}")

println("Building dockerfile...")
run(`docker build $(@__DIR__) --file $(@__DIR__)/tensorboard.dockerfile -t $IMAGE_NAME`)

println("Pushing dockerfile...")
run(`docker push $IMAGE_NAME`)

output = readchomp(pipeline("$(@__DIR__)/tensorboard.yaml", `envsubst`, `$(kubectl()) create -f -`))
println(output)
pod = split(output)[1]

go(pod)
