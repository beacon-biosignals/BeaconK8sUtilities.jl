
get_status(pod) = readchomp(`$(kubectl()) get $pod --template=\{\{.status.phase\}\}`)
last_condition(pod) = JSON3.read(readchomp(`$(kubectl()) get $pod -o jsonpath=\{.status.conditions\[-1:\]\}`))

function get_pod_names(labels = ``)
    pods = JSON3.read(readchomp(`$(kubectl()) get pods $labels -o jsonpath="{.items}"`))
    return [ pod.metadata.name for pod in pods]
end

function wait_until_pod_ready(pod)
    # We don't want to have to wait to the `kubectl` request to finish in order to display
    # values below the progress bar, or else it will flash annoyingly.
    # So instead we do the `last_condition` calling async from the rest.

    # stores the result
    condition_channel = Channel(1) do c
        while true
            # Put a new value as soon as we can
            put!(c, last_condition(pod))
        end
    end

    # Show the last condition of the pod dynamically under the ProgressMeter display
    showvalues = () -> begin
        # take the latest, waiting if we need to to get it
        c = take!(condition_channel)
        return pairs(c)
    end

    prog = ProgressUnknown("Starting up $(pod):", spinner=true)
    while get_status(pod) == "Pending"
        ProgressMeter.next!(prog; showvalues)
        sleep(2)
    end

    st = get_status(pod)

    if st == "Succeeded" || st == "Running"
        ProgressMeter.finish!(prog)
    else
        ProgressMeter.finish!(prog; spinner='✗')
        error("""
        Pod did not start up successfully. Got status $(st) and last condition status:
        
        $(JSON3.pretty(last_condition(pod)))
        
        """)
    end

    return nothing
end

function watch_logs(pod; exit_on_interrupt=false)
    local task
    try
        Base.exit_on_sigint(false)
        # Fewer segfaults when you ctrl-c this way...
        task = run(pipeline(`$(kubectl()) logs -f $pod`; stdout, stderr); wait=false)
        wait(task)
    catch e
        if e isa InterruptException
            kill(task)
            if exit_on_interrupt
                println("Interrupt while following $pod logs; exiting...") 
                exit(0)
            end
        end
        rethrow()
    finally
        Base.exit_on_sigint(true)
    end
end

function port_forward_and_log(pod; remote_port::Int, local_port::Int=remote_port)
    wait_until_pod_ready(pod)

    # Launch port forwarding in a separate process group (`detach=true`) so it can outlive this session
    pfd_task = run(Cmd(`$(kubectl()) port-forward $pod $(local_port):$(remote_port)`, detach=true); wait=false)

    println("Fowarding port $(remote_port) of $pod to your local port `$(local_port)`.")
    println("Go to `http://localhost:$(local_port)/` to see the results.")

    println("Following logs on pod...")
    watch_logs(pod; exit_on_interrupt=true)
end
