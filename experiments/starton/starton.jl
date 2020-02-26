
function machin_series(n::Int)
    qpi = 0.0
    for i in 1:n
        qpi += (-1)^(i+1)/(2i-1)
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
