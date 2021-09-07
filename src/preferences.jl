"""
    default_ecr() -> `ecr`
    default_ecr(ecr::AbstractString) -> `ecr`

Uses Preferences.jl to set or retrieve the default ECR.
"""
default_ecr

default_ecr() = @something(@load_preference("ecr"), throw(ArgumentError("No `ecr` specified and no default has been set (see `default_ecr`)")))

function default_ecr(ecr::AbstractString)
    ecr = convert(String, ecr)
    @set_preferences!("ecr" => ecr)
    @info("New default `ecr` set!")
    return ecr
end

"""
    default_service_account() -> `service_account`
    default_service_account(service_account::AbstractString) -> `service_account`

Uses Preferences.jl to set or retrieve the default service account.
"""
default_service_account

default_service_account() = @something(@load_preference("service_account"), throw(ArgumentError("No `service_account` specified and no default has been set (see `default_service_account`)")))

function default_service_account(service_account::AbstractString)
    service_account = convert(String, service_account)
    @set_preferences!("service_account" => service_account)
    @info("New default `service_account` set!")
    return service_account
end
