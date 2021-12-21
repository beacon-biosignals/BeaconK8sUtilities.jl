function info_for_logger()
    return (; timestamp=Dates.format(now(), dateformat"yyyy-mm-dd HH:MM:SS"),
            worker_id=myid())
end

"""
    jsonable(obj::Any) = obj

Add methods to `BeaconK8sUtilities.jsonable` in order to specify how [`json_logger`](@ref) should
serialize types that themselves do not already have a `StructTypes.StructType` defined.

## Example

For example, if we want to log `TimerOutput`s from TimerOutputs.jl, we can define the
following.

```julia
using TimerOutputs

BeaconK8sUtilities.jsonable(to::TimerOutput) = TimerOutputs.todict(to)
```

This pirates `BeaconK8sUtilities.jsonable` but since it is only used for the logger,
it is better than pirating `StructTypes.StructType` which could be used more widely.
"""
jsonable(obj::Any) = obj

# https://github.com/JuliaLogging/LoggingExtras.jl/pull/59/
function make_maxlog_logger(logger)
    counts = Dict{Any,Int}()
    return ActiveFilteredLogger(logger) do log
        maxlog = get(log.kwargs, :maxlog, nothing)
        maxlog === nothing && return true # no limit
        c = get(counts, log.id, 0)
        if c < maxlog
            # log this message and update the count
            counts[log.id] = c + 1
            return true
        else
            return false
        end
    end
end

"""
    json_logger(level=Logging.Info; info_for_logger=BeaconK8sUtilities.info_for_logger, io=stderr)

Provides a logger which:

* Emits logs as JSON (via `LoggingFormats.JSON(; recursive=true)`)
* Adds extra information to every log message via `info_for_logger()`, which can be any function that evaluates
to a `NamedTuple`. The default provides a timestamp and the current worker id (`Distributed.myid()`).
* the respects `maxlog` convention (see <https://docs.julialang.org/en/v1/stdlib/Logging/#Logging.@logmsg>)

Set the positional argument to the minimum-enabled logging level, and `io` to the IO handle where the logs should be emitted.

See also [`BeaconK8sUtilities.jsonable`](@ref) for how to customize how objects are converted to JSON.
"""
function json_logger(level=Logging.Info; info_for_logger=info_for_logger, io=stderr)
    t = TransformerLogger(FormatLogger(LoggingFormats.JSON(; recursive=true), io)) do log
        transformed_kwargs = map(jsonable, NamedTuple(log.kwargs))
        return merge(log, (; kwargs=merge(info_for_logger(), transformed_kwargs)))
    end
    return MinLevelLogger(make_maxlog_logger(t), level)
end
