using .Threads, BenchmarkTools

function machin_series(n::Int; handover=false)
    qpi = 0.0
    for i in 1:n
        qpi += (-1)^(i+1)/(2i-1)
        handover && yield()  # we yield here !!!!
    end
    qpi*4
end

function startonthread(id::Int, f::F) where {F<:Function}
    t = Task(nothing)
    @threads for i in 1:nthreads()
        if i == id
            t = @async f()
        end
    end
    fetch(t)
end

println("Benchmark results on thread 1-4 without yielding:")
@btime startonthread(1, ()->machin_series(10_000))
@btime startonthread(2, ()->machin_series(10_000))
@btime startonthread(3, ()->machin_series(10_000))
@btime startonthread(4, ()->machin_series(10_000))

println("Benchmark results on thread 1-4 with yielding:")
@btime startonthread(1, ()->machin_series(10_000, handover=true))
@btime startonthread(2, ()->machin_series(10_000, handover=true))
@btime startonthread(3, ()->machin_series(10_000, handover=true))
@btime startonthread(4, ()->machin_series(10_000, handover=true))
