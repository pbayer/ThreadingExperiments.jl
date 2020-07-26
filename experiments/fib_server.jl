#
# fibonacci server
#

using ThreadingExperiments

function do_fib(cache, n)
    haskey(cache, n) || (cache[n] = BigInt(do_fib(cache, n-1) + do_fib(cache, n-2)))
    return cache[n]
end

const cch = Dict(0=>big"0", 1=>big"1")

function reset!(cache)
    empty!(cache)
    cache[0] = big"0"
    cache[1] = big"1"
end
