using BeaconK8sUtilities
using Test, Logging, JSON3, Dates

function capture_logs(f)
    io = IOBuffer()
    Logging.with_logger(f, json_logger(; io))
    return JSON3.read(take!(io), Dict)
end

struct TestObj1
    f::Any
end

struct TestObj2
    f::Any
end

BeaconK8sUtilities.jsonable(obj::TestObj1) = (; obj.f)

@testset "BeaconK8sUtilities.jl" begin
    @testset "setup_tensorboard" begin
        testdir = mktempdir()
        test_args = (; app="test-app", logdir="test-logdir", ecr="test-ecr",
                     service_account="test-service-account", namespace="test-namespace")
        @test setup_tensorboard(testdir; test_args...) === nothing

        # Check we at least get the right files
        @test Set(readdir(testdir)) ==
              Set(["tensorboard.dockerfile", "tensorboard.sh", "tensorboard.yaml"])

        # No `overwrite=true`
        @test_throws ErrorException setup_tensorboard(testdir; test_args...)

        # Works with `overwrite=true`
        @test setup_tensorboard(testdir; test_args..., overwrite=true) === nothing
        @test Set(readdir(testdir)) ==
              Set(["tensorboard.dockerfile", "tensorboard.sh", "tensorboard.yaml"])
    end

    @testset "setup_follow" begin
        testdir = mktempdir()
        test_args = (; namespace="test-namespace")
        @test setup_follow(testdir; test_args...) === nothing

        # Check we at least get the right files
        @test readdir(testdir) == ["follow.sh"]

        # No `overwrite=true`
        @test_throws ErrorException setup_follow(testdir; test_args...)

        # Works with `overwrite=true`
        @test setup_follow(testdir; test_args..., overwrite=true) === nothing
        @test readdir(testdir) == ["follow.sh"]
    end

    @testset "json_logger" begin
        logs = capture_logs() do
            @info "Hi" x = Dict("a" => Dict("b" => 2))
        end
        @test logs["msg"] == "Hi"
        @test logs["kwargs"]["x"] == Dict("a" => Dict("b" => 2))
        @test logs["kwargs"]["worker_id"] == 1
        @test parse(DateTime, logs["kwargs"]["timestamp"],
                    dateformat"yyyy-mm-dd HH:MM:SS") isa DateTime

        logs = capture_logs() do
            try
                error("no")
            catch e
                @error "Oh no" exception = e
            end
        end
        @test logs["msg"] == "Oh no"
        @test logs["kwargs"]["exception"] == "ErrorException(\"no\")"

        logs = capture_logs() do
            try
                error("no")
            catch e
                @error "Oh no" exception = (e, catch_backtrace())
            end
        end
        @test logs["msg"] == "Oh no"

        @test logs["kwargs"]["exception"][1] == "ErrorException(\"no\")"
        # Make sure we get a stacktrace out:
        @test contains(logs["kwargs"]["exception"][2],
                       "Stacktrace:\n  [1] error(s::String)\n")

        logs = capture_logs() do
            @info "Hi" x = TestObj1("a")
        end
        @test logs["kwargs"]["x"] == Dict("f" => "a")

        logs = capture_logs() do
            @info "Hi" x = TestObj2("a")
        end
        @test logs["kwargs"]["x"] == "TestObj2(\"a\")"
        @test logs["kwargs"]["LoggingFormats.FormatError"] ==
              "ArgumentError: TestObj2 doesn't have a defined `StructTypes.StructType`"
    end
end
