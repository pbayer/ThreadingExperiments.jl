#
# This file is part of ThreadingExperiments.jl
#
# Paul Bayer, 2020
# license: MIT
#
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
