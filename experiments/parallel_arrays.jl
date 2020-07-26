using .Threads

function copyVerts!(b, sub, start)
    for i in 1:length(sub)
        b[start + i - 1] = sub[i]
    end
end

s1 = 1:nthreads()
s2 = s1 .+ 1
c1 = cumsum(s1)
c2 = cumsum(s2)
sa = [c1[i]:c2[i] for i in s1]
b = zeros(Int,maximum(c2))

@sync for i = 1:nthreads()
    Threads.@spawn copyVerts!(b, sa[i], c1[i])
end
