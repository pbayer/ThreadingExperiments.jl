#
# this example is an adoption of the chain example
# in Programming Elixir ch. 15
# see https://media.pragprog.com/titles/elixir16/code/spawn/chain.exs
#
using .Threads

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
