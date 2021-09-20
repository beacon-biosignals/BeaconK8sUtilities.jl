#!/bin/bash
# Try to get proper highlighting (as a julia script):
# vim: ts=4:sw=4:et:ft=julia
# -*- mode: julia -*-
# code: language=julia
#
# This can be launched as a bash script-- it will `exec` into a Julia process and run the script.
# It can also just be run or included as a Julia script.
#=
exec julia --color=yes --startup-file=no -q --compile=min -O0 "${BASH_SOURCE[0]}" "$@"
=#

using BeaconK8sUtilities

pod = ARGS[1]

follow(pod; exit_on_interrupt=true, namespace="{{{ namespace }}}")
