function info_for_logger()
    return (; timestamp=Dates.format(now(), dateformat"yyyy-mm-dd HH:MM:SS"),
            worker_id=myid())
end

"""
    jsonable(obj::Any) = obj

Add methods to `BeaconK8sUtilities.jsonable` in order to specify how `json_logger` should
serialize types that themselves do not already have a `StructTypes.StructType` defined.
"""
jsonable(obj::Any) = obj

function maxlog_logger(logger)
    counts = Dict{Symbol, Int}()
    return ActiveFilteredLogger(logger) do log
        haskey(log.kwargs, :maxlog) || return true
        if !haskey(counts, log.id) || (counts[log.id] < log.kwargs[:maxlog])
             # then we will log it, and update the corresponding count
             counts[log.id] = get(counts, log.id, 0) + 1
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
* transforms `exception` keys to render backtraces to strings before logging them

Set the positional argument to the minimum-enabled logging level, and `io` to the IO handle where the logs should be emitted.
"""
function json_logger(level=Logging.Info; info_for_logger=info_for_logger, io=stderr)
    t = TransformerLogger(FormatLogger(LoggingFormats.JSON(; recursive=true), io)) do log
        transformed_kwargs = map(jsonable, NamedTuple(log.kwargs))
        return merge(log, (; kwargs=merge(info_for_logger(), transformed_kwargs)))
    end
    return MinLevelLogger(maxlog_logger(t), level)
end
