"""
    prefix_pod(name) -> AbstractString

Prepends the prexfix `pod/` to `name` if it does not
already have it.
"""
function prefix_pod(name)
    if !startswith(name, "pod/")
        name = "pod/" * name
    end
    return name
end

"""
    get_status(pod; namespace=nothing) -> String

Get the status of a pod.
"""
function get_status(pod; namespace=nothing)
    pod = prefix_pod(pod)
    ns = isnothing(namespace) ? `` : `--namespace=$namespace`
    return readchomp(`$(kubectl()) get $pod $ns --template=\{\{.status.phase\}\}`)
end

"""
    last_condition(pod; namespace=nothing) -> String

Get the latest "condition" of a pod.
"""
function last_condition(pod; namespace=nothing)
    pod = prefix_pod(pod)
    ns = isnothing(namespace) ? `` : `--namespace=$namespace`
    return JSON3.read(readchomp(`$(kubectl()) get $pod $ns -o jsonpath=\{.status.conditions\[-1:\]\}`))
end

"""
    get_pod_names(labels = ``; namespace=nothing) -> Vector{String}

Get the names of pods in the current namespace (or pass a namespace to specify
a different one). Pass `labels` as e.g. `-l app=myapp` to restrict to specific labels.
"""
function get_pod_names(labels=``; namespace=nothing)
    ns = isnothing(namespace) ? `` : `--namespace=$namespace`
    pods = JSON3.read(readchomp(`$(kubectl()) get pods $ns $labels -o jsonpath="{.items}"`))
    return [pod.metadata.name for pod in pods]
end

"""
    get_current_namespace() -> String

Get the current active Kubernetes namespace.
"""
function get_current_namespace()
    return readchomp(`$(kubectl()) config view --minify --output 'jsonpath={..namespace}'`)
end

"""
    wait_until_pod_ready(pod; namespace=nothing)

Display a progress bar while waiting for `pod` to become `Running`.
"""
function wait_until_pod_ready(pod; namespace=nothing, exit_on_interrupt=false)
    pod = prefix_pod(pod)
    runner(; interrupt_msg="while waiting for $pod to start up", exit_on_interrupt) do
        # We don't want to have to wait to the `kubectl` request to finish in order to display
        # values below the progress bar, or else it will flash annoyingly.
        # So instead we do the `last_condition` calling async from the rest.

        # stores the result
        condition_channel = Channel(1) do c
            while true
                # Put a new value as soon as we can
                put!(c, last_condition(pod; namespace))
            end
        end

        # Show the last condition of the pod dynamically under the ProgressMeter display
        showvalues = () -> begin
            # take the latest, waiting if we need to to get it
            c = take!(condition_channel)
            return pairs(c)
        end

        prog = ProgressUnknown("Starting up $(pod):"; spinner=true)
        while get_status(pod; namespace) == "Pending"
            ProgressMeter.next!(prog; showvalues)
            sleep(2)
        end

        st = get_status(pod; namespace)

        if st == "Succeeded" || st == "Running"
            ProgressMeter.finish!(prog)
        else
            ProgressMeter.finish!(prog; spinner='✗')
            error("""
            Pod did not start up successfully. Got status $(st) and last condition status:

            $(JSON3.pretty(last_condition(pod; namespace)))

            """)
        end
    end
    return nothing
end

"""
    watch_logs(pod; exit_on_interrupt=false, namespace=nothing)

Follows logs from `pod`. If `exit_on_interrupt=true`, exits the Julia session
upon `ctrl-c`. Otherwise throws an error as usual upon interruption.
"""
function watch_logs(pod; exit_on_interrupt=false, namespace=nothing)
    pod = prefix_pod(pod)
    ns = isnothing(namespace) ? `` : `--namespace=$namespace`
    cmd_runner(`$(kubectl()) logs $ns -f $pod`; exit_on_interrupt,
               interrupt_msg="while following the logs of $pod")
    return nothing
end

struct Interrupted <: Exception
    msg::String
end
Base.showerror(io::IO, e::Interrupted) = print(io, "Interrupted ", e.msg)

function cmd_runner(cmd::Cmd; exit_on_interrupt=false, interrupt_msg="Interrupted")
    # We use `wait=false` and `wait_kill_result=true`
    # So that if we ctrl-c we don't get
    # a LoadError (failed process) but rather
    # a usual InterruptException that we can handle.
    runner(() -> run(pipeline(cmd; stdout, stderr); wait=false); exit_on_interrupt,
           interrupt_msg, wait_kill_result=true)
    return nothing
end

function runner(f; exit_on_interrupt=false, interrupt_msg="Interrupted",
                wait_kill_result=false)
    local task
    try
        # Makes interrupts catchable like in the REPL, even if run from a script.
        Base.exit_on_sigint(false)
        task = f()
        wait_kill_result && wait(task)
    catch e
        wait_kill_result && kill(task)
        if e isa InterruptException
            if exit_on_interrupt
                # No need for a stacktrace
                println("Interrupted $(interrupt_msg); exiting...")
                exit(0)
            else
                rethrow(Interrupted(interrupt_msg))
            end
        end
        rethrow()
    finally
        # In non-interative sessions, this defaults to `true`.
        # We should restore that.
        if !Base.isinteractive()
            Base.exit_on_sigint(true)
        end
    end
    return nothing
end

"""
    follow(pod; exit_on_interrupt=false, namespace=nothing)

A simpler helper to follow a `pod` by first waiting until it's
ready ([`wait_until_pod_ready`](@ref)) and then wathing its logs
([`watch_logs`](@ref)).
"""
function follow(pod; exit_on_interrupt=false, namespace=nothing)
    wait_until_pod_ready(pod; exit_on_interrupt, namespace)
    watch_logs(pod; exit_on_interrupt, namespace)
    return nothing
end

"""
    port_forward(pod; remote_port::Int, local_port::Int=remote_port, namespace=nothing) -> Task

Forwards a port from `remote_port` on `pod` to `local_port`. Runs in a detached process,
and so will outlive the current Julia session. Returns the task running this process.
"""
function port_forward(pod; remote_port::Int, local_port::Int=remote_port, namespace=nothing)
    pod = prefix_pod(pod)
    ns = isnothing(namespace) ? `` : `--namespace=$namespace`

    # Launch port forwarding in a separate process group (`detach=true`) so it can outlive this session
    pfd_task = run(Cmd(`$(kubectl()) port-forward $pod $ns $(local_port):$(remote_port)`;
                       detach=true); wait=false)

    println("Fowarding port $(remote_port) of $pod to your local port `$(local_port)`.")
    println("Go to `http://localhost:$(local_port)/` to see the results.")
    return pfd_task
end
