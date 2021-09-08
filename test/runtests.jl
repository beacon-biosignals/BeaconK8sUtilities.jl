using K8sUtilities
using Test

@testset "K8sUtilities.jl" begin
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
end
