# Lightweight tasks, Julia vs Elixir

**note:** there is a thread on this on [Julia Discourse](https://discourse.julialang.org/t/lightweight-tasks-julia-vs-elixir-otp/35082) as well.

I wanted to know if Julia copes well with lots of very lightweight tasks. Therefore I took [an example](https://media.pragprog.com/titles/elixir16/code/spawn/chain.exs) from [Programming Elixir 1.6](https://pragprog.com/book/elixir16/programming-elixir-1-6) and implemented it in Julia:

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

const start = Channel{Int}()
```
This sets up a chain of `counter` tasks listening to their channel `ch` and sending an invremented token to the `next` task. We start the chain by sending zero to the last created task and receive the result from the channel we started with. Then …

```julia
julia> using BenchmarkTools

julia> @btime create_processes(start, 1000, spawn=true)
  1.912 ms (33328 allocations: 1.78 MiB)
1000
```
Those were 1000 established channels and `counter` tasks and 1000 `take!` and `put!`-operations. It is a strictly sequential chain process over multiple threads. The results were as follows:

![results](chain.png)

Julia scales better than Elixir probably since no start time is involved.

## Thread 1 much slower than 2-4

In playing around I noticed that the chain takes much longer if I set `spawn=false` and execute the whole chain on thread 1:

```julia
julia> @btime create_processes(start, 1000)
  31.191 ms (32980 allocations: 1.77 MiB)
1000
```

I investigated the thing further by writing a function allowing me to start the chain on specific threads.

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

This gave the following results:

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

The chain takes much longer on thread 1 than on threads 2 - 4. My machine is a MacBook Pro 2013, 4 cores, 16 GB memory, L2-Cache (per core):	256 KB

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

The problem persists even after system shutdown and termination of all other user apps.

The problem may have some implications on how to implement and carry out multithreading on affected machines. It seems that such unbalanced threads  require load balancing to make things effective. Relocating single-threaded applications to threads other than 1 maybe effective as well.

I opened an [issue on JuliaLang](https://github.com/JuliaLang/julia/issues/34875).

## A minimal working Example

As the following example shows, the problem has to do with yielding to other tasks operating on thread 1 outside my application:

```julia
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
```
The results were as follows:
```julia
julia> @btime startonthread(1, ()->machin_series(10_000))
  491.870 μs (43 allocations: 4.20 KiB)
3.1414926535900345

julia> @btime startonthread(2, ()->machin_series(10_000))
  511.001 μs (45 allocations: 4.23 KiB)
3.1414926535900345

julia> @btime startonthread(1, ()->machin_series(10_000, handover=true))
  147.722 ms (10044 allocations: 160.47 KiB)    ## !!!!!!!
3.1414926535900345

julia> @btime startonthread(2, ()->machin_series(10_000, handover=true))
  2.477 ms (10045 allocations: 160.48 KiB)
3.1414926535900345

julia> @btime startonthread(3, ()->machin_series(10_000, handover=true))
  2.499 ms (10045 allocations: 160.48 KiB)
3.1414926535900345
...
```
and likewise ...
```julia
➜  chain (master) julia --startup-file=no do_benchmark.jl                   ✭ ✱
Benchmark results on thread 1-4 without yielding:
  430.705 μs (43 allocations: 4.20 KiB)
  447.144 μs (45 allocations: 4.23 KiB)
  459.419 μs (45 allocations: 4.23 KiB)
  452.955 μs (43 allocations: 4.20 KiB)
Benchmark results on thread 1-4 with yielding:
  154.465 ms (10044 allocations: 160.47 KiB)
  2.385 ms (10045 allocations: 160.48 KiB)
  2.369 ms (10045 allocations: 160.48 KiB)
  2.369 ms (10045 allocations: 160.48 KiB)
```
If we yield, things take much longer on thread 1 than on other ones.

Paul Bayer, 2020-02-26
