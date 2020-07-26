using .Threads

const N = nthreads()
const t1 = zeros(Int, N)
const s1 = zeros(Int, N)

@threads for i in 1:N
    t1[i] = threadid()
end

@sync for i in 1:N
    Threads.@spawn s1[i] = threadid()
end

for j in 1:5
    @threads for i in 1:N
        t1[i] = threadid()
    end
    println(t1, " - ", Set(t1))
end

for j in 1:5
    @sync for i in 1:N
        Threads.@spawn s1[i] = threadid()
    end
    println(s1, " - ", Set(s1))
    s1[:] .= 0
end
