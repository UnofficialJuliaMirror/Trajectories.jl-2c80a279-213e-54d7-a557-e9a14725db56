# location, measurements

# elipsis in print_range


import Base: Pair,
    pairs, getindex, length, getproperty, map,
    get, keys, values, keytype, eltype, ==

include("unroll1.jl")


"""
    AbstractPairedArray

Simple data structure pairing two arrays, with the first array holding the `keys`
and the second the corresponding `values`.

For example an array of locations with an array of
corresponding measurements or a vector of times with
a vector of locations.
"""
abstract type  AbstractPairedArray
end

const APA = AbstractPairedArray

#=
struct PairedArray{T,S} <: AbstractPairedArray
    x::S
    x::T
end
=#

"""
    Trajectory{S,T} <: AbstractPairedArray

Pairs a linearly ordered (abstract) vector of `keys` (typically times) with
a vector of `values` (typically locations).
"""
struct Trajectory{S,T} <: AbstractPairedArray
    t::S
    x::T
end

keys(X::Trajectory) = X.t
values(X::Trajectory) = X.x

keytype(X::Trajectory) = eltype(X.t)
eltype(X::Trajectory) = eltype(X.x)


function _find(r::AbstractRange, x)
    n = round(Integer, (x - first(r)) / step(r)) + 1
    if n >= 1 && n <= length(r) && r[n] == x
        return n
    else
        error("index error")
    end
end

function get(X::Trajectory{<:AbstractVector}, key)
    i = searchsorted(keys(X), key)
    isempty(i) && error("key not found")
    first(i) != last(i) && error("key not unique")
    return values(X)[first(i)]
end

trajectory(t, x) = Trajectory(t, x)
function trajectory(itr)
    local t, x
    @unroll1 for (tᵢ, xᵢ) in itr
        if $first
            t = [tᵢ]
            x = [xᵢ]
        else
            push!(t, tᵢ)
            push!(x, xᵢ)
        end
    end
    Trajectory(t, x)
end


# Iteration and indexing spared out, see issue #1
length(X) = length(values(X)) # seems useful enough
#=

iterate(X::Trajectory) = X.t, (X.x, nothing)
iterate(X::Trajectory, state) = state
length(X) = 2

eachindex(X::Trajectory) = eachindex(X.x)
getindex(X::Trajectory{<:AbstractVector}, i) = getindex(X.x, i)
=#

Pair(X::Trajectory) = (X.t, X.x)

pairs(X::Trajectory) = (t => x for (t, x) in zip(X.t, X.x))

X::Trajectory == Y::Trajectory = X.t == Y.t && X.x == Y.x



function map(f, X::Trajectory, Y::Trajectory)
    if X.t === Y.t || X.t == Y.t
        Trajectory(X.t, map(f, X.x, Y.x))
    else
        error("map undefined for Trajectory on different times")
    end
end