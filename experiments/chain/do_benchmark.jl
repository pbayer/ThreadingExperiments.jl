using .Threads, BenchmarkTools

function counter(next::Channel{Int})
    return ch -> put!(next, take!(ch)+1)
end

function create_processes(start::Channel{Int}, n::Int; spawn=false)
    next = start
    for i in 1:n
        next = Channel{Int}(counter(next), spawn=spawn)
    end

    put!(next, 0)

    take!(start)
end

function startonthread(id::Int, start::Channel{Int}, n::Int; spawn=false)
    t = Task(nothing)
    @threads for i in 1:nthreads()
        if i == id
            t = @async create_processes(start, n, spawn=spawn)
        end
    end
    fetch(t)
end

const start = Channel{Int}()

@btime startonthread(1, start, 1000)

@btime startonthread(2, start, 1000)

@btime startonthread(3, start, 1000)

@btime startonthread(4, start, 1000)
