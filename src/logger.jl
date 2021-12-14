info_for_logger() = (; timestamp=Dates.format(now(), dateformat"yyyy-mm-dd HH:MM:SS"), worker_id=myid())

"""
    jsonable(obj::Any) = obj

Add methods to `BeaconK8sUtilities.jsonable` in order to specify how `json_logger` should
serialize types that themselves do not already have a `StructTypes.StructType` defined.
"""
jsonable(obj::Any) = obj

function handle_log_exception(key, v)
    key == :exception || return v
    if v isa Tuple && length(v) == 2
        e, bt = v
        msg = sprint(showerror, e, stacktrace(bt))
        return (string(e), msg)
    end
    return string(v)
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
        kwarg_nt = (; (k => handle_log_exception(k, v) for (k, v) in log.kwargs)...)
        transformed_kwargs = map(jsonable, kwarg_nt)
        return merge(log, (; kwargs = merge(info_for_logger(), transformed_kwargs)))
    end
    return MinLevelLogger(t, level)
end
