using ThreadingExperiments, .Threads
using Test

@testset "ThreadingExperiments.jl" begin
    for i in 1:nthreads()
        @test onthread(threadid, i) == i
    end
    @test_throws AssertionError onthread(threadid, 0815)
end
