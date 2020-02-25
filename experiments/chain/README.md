# Lightweight tasks, Julia vs Elixir

**note:** there is a thread on this on [Julia Discourse](https://discourse.julialang.org/t/lightweight-tasks-julia-vs-elixir-otp/35082) as well.

I wanted to know if Julia copes well with very lightweight tasks. Therefore I took [an example](https://media.pragprog.com/titles/elixir16/code/spawn/chain.exs) from [Programming Elixir 1.6](https://pragprog.com/book/elixir16/programming-elixir-1-6) and implemented it in Julia:

```julia
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
```
This is a strictly sequential operation over multiple threads.

then

```julia
julia> using BenchmarkTools

julia> @btime create_processes(start, 1000, spawn=true)
  1.912 ms (33328 allocations: 1.78 MiB)
1000
```

The result were as follows:

![results](chain.png)

Julia scales better than Elixir probably since no start time is involved.

## Thread 1 much slower than 2-4

In playing around I noticed that the chain takes much longer if I set `spawn=false` and execute the whole chain on thread 1:

```julia
julia> @btime create_processes(start, 1000)
  31.191 ms (32980 allocations: 1.77 MiB)
1000
```

I investigated the thing further by writing a function, which allows me to start the chain on specific threads.

```julia
function startonthread(id::Int, start::Channel{Int}, n::Int; spawn=false)
    t = Task(nothing)
    @threads for i in 1:nthreads()
        if i == id
            t = @async create_processes(start, n, spawn=spawn)
        end
    end
    fetch(t)
end
```

The results were as follows:

```julia
julia> @btime startonthread(1, start, 1000)
  33.660 ms (33025 allocations: 1.77 MiB)
1000

julia> @btime startonthread(2, start, 1000)
  2.564 ms (33026 allocations: 1.77 MiB)
1000

julia> @btime startonthread(3, start, 1000)
  2.558 ms (33026 allocations: 1.77 MiB)
1000

julia> @btime startonthread(4, start, 1000)
  2.585 ms (33026 allocations: 1.77 MiB)
1000
```

The chain takes much longer on thread 1 than on thread 2 - 4. My machine is a MacBook Pro 2013, 4 cores, 16 GB memory, L2-Cache (per core):	256 KB

```julia
julia> versioninfo()
Julia Version 1.3.1
Commit 2d5741174c (2019-12-30 21:36 UTC)
Platform Info:
  OS: macOS (x86_64-apple-darwin18.6.0)
  CPU: Intel(R) Core(TM) i7-4850HQ CPU @ 2.30GHz
  WORD_SIZE: 64
  LIBM: libopenlibm
  LLVM: libLLVM-6.0.1 (ORCJIT, haswell)
Environment:
  JULIA_NUM_THREADS = 4
  JULIA_EDITOR = atom  -a
```

The problem persists even after system shutdown and termination of all other user apps. Therefore I guess, that the OS is using part of the L2-cache on thread 1. This slows down memory intensive operations on thread 1. Other users on Discourse reported slowdowns on thread 1 of their machines, albeit not so dramatic ones than on mine.

The problem may have some implications on how to implement and carry out multithreading on affected machines. It seems that such unbalanced threads  require load balancing to make things effective. Relocating single-threaded applications to threads other than 1 maybe effective as well.

I opened an [issue on JuliaLang](https://github.com/JuliaLang/julia/issues/34875).

Paul Bayer, 2020-02-25
