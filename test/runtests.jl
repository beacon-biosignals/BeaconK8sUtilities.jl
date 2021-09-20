using BeaconK8sUtilities
using Test

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
end
