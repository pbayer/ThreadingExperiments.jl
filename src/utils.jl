#
# This file is part of ThreadingExperiments.jl
#
# Paul Bayer, 2020
# license: MIT
#
"""
    onthread(f::F, id::Int) where {F<:Function}

Execute a function f on thread id.

# Examples, usage

```julia
julia> using ThreadingExperiments, .Threads

julia> onthread(threadid, 2)
2

julia> onthread(3) do; threadid(); end
3

julia> onthread(4) do
           threadid()
       end
4
```
"""
function onthread(f::F, id::Int) where {F<:Function}
    t = Task(nothing)
    @assert id in 1:nthreads() "thread $id not available!"
    @threads for i in 1:nthreads()
        if i == id
            t = @async f()
        end
    end
    fetch(t)
end
