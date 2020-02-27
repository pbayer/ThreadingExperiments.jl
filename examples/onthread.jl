#
# This file is part of ThreadingExperiments.jl
#
# Paul Bayer, 2020
# license: MIT
#
using ThreadingExperiments, .Threads

onthread(threadid, 1)
onthread(threadid, 2)

onthread(3) do
    threadid()
end

onthread(2) do # Machin-like series
    qpi = 0.0
    for i in 1:10_000
        qpi += (-1)^(i+1)/(2i-1)
    end
    qpi*4
end
