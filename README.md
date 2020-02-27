# ThreadingExperiments

Experiments with Julia threads

[![Build Status](https://travis-ci.com/pbayer/ThreadingExperiments.jl.svg?branch=master)](https://travis-ci.com/pbayer/ThreadingExperiments.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/pbayer/ThreadingExperiments.jl?svg=true)](https://ci.appveyor.com/project/pbayer/ThreadingExperiments-jl)
[![Codecov](https://codecov.io/gh/pbayer/ThreadingExperiments.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/pbayer/ThreadingExperiments.jl)
[![Coveralls](https://coveralls.io/repos/github/pbayer/ThreadingExperiments.jl/badge.svg?branch=master)](https://coveralls.io/github/pbayer/ThreadingExperiments.jl?branch=master)

My experiments are in the directory of the same name.

Now the module provides only one function: `onthread`. The [chain experiment](https://github.com/pbayer/ThreadingExperiments.jl/tree/master/experiments/chain) shows that Julia programs involving tasks and task switching can be sped up by relocating them to threads other than one.

```julia
using ThreadingExperiments, .Threads, BenchmarkTools

onthread(threadid, 1)
onthread(threadid, 2)

onthread(3) do
    threadid()
end

function machin_series(n::Int; handover=false)
    qpi = 0.0
    for i in 1:n
        qpi += (-1)^(i+1)/(2i-1)
        handover && yield()  # we yield here !!!!
    end
    qpi*4
end

julia> @btime onthread(1) do
           machin_series(10_000, handover=true)
       end
  153.428 ms (10045 allocations: 160.48 KiB)
3.1414926535900345

julia> @btime onthread(2) do
           machin_series(10_000, handover=true)
       end
  2.467 ms (10045 allocations: 160.48 KiB)
3.1414926535900345
```
