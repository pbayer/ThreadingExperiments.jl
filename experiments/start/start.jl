using .Threads

abstract type Message end
struct Query <: Message end
struct Stop  <: Message end

function actor(ch::Channel)
    put!(ch, threadid())
    while true
        token = take!(ch)
        if token isa Query
            put!(ch, threadid())
        elseif token isa Stop
            break
        else
        end
    end
end

function startup()
    @threads for i in 1:nthreads()
        @async actor(CH[threadid()])
    end
end


const CH = Vector{Channel}(undef, nthreads())
const cnt = zeros(Int, nthreads())

function init_all()
    for i in eachindex(CH)
        CH[i] = Channel()
        cnt[i] = 0
    end
end

function results()
    for i in eachindex(CH)
        if isready(CH[i])
            cnt[i] += take!(CH[i]) ÷ i
        end
    end
end

function test_thrd(n::Int)
    init_all()
    for i in 1:n
        startup()
        results()
        foreach(c->put!(c,Stop()), CH)
    end
    cnt
end
