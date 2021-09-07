#!/bin/bash
# This can be launched as a bash script-- it will `exec` into a Julia process and run the script.
# It can also just be run or included as a Julia script.
#=
exec julia --color=yes --project=@K8sUtilities --startup-file=no -q --compile=min -O0 "${BASH_SOURCE[0]}" "$@"
=#

using Preferences, K8sUtilities

LOCAL_PORT = {{local_port}}
LABELS = `-l app={{app}},target=tensorboard`

tensorboard_pods = get_pod_names(LABELS)

if length(tensorboard_pods) == 1
    pod = "pod/"*tensorboard_pods[1]
    result = Base.prompt("Existing pod $pod found. Port-forward to it?"; default="yes")
    if lowercase(result) in ("yes", "y")
        port_forward_and_log(pod; remote_port=6006, local_port=LOCAL_PORT)
        exit(0)
    end
end

if !isempty(tensorboard_pods)
    error("""
    One or more tensorboard pods are already running!
    
    $(tensorboard_pods)

    Kill them with
    ```
    kubectl delete pods $(LABELS)
    ```
    and see which pods they are with
    ```
    kubectl get pods $(LABELS)
    ```

    If you want to setup port-forwarding to an existing pod, run
    ```
    kubectl port-forward POD_NAME $(LOCAL_PORT):6006
    ````
    with `POD_NAME` chosen from the `get pods` command above.

    (You could of course comment out this check to proceed!).
    """)
end

ENV["IMAGE_NAME"] = IMAGE_NAME = "{{ ecr }}:{{ app }}-tensorboard"
ENV["LOGDIR"]= "{{ logdir }} "

println("Building dockerfile...")
run(`docker build . --file tensorboard.dockerfile -t $IMAGE_NAME`)

println("Pushing dockerfile...")
run(`docker push $IMAGE_NAME`)

output = readchomp(pipeline("cluster-tensorboard.yaml", `envsubst`, `kubectl create -f -`))
println(output)
pod = split(output)[1]

port_forward_and_log(pod; remote_port=6006, local_port=LOCAL_PORT)
