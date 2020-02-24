#
# this example is an adoption of the chain example
# in Programming Elixir ch. 15
# see https://media.pragprog.com/titles/elixir16/code/spawn/chain.exs
#
using Plots

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

function plot_results()
    x = map(x->10^x,1:6)
    elixir=[3.355,3.571,7.871,50.252,506.419,4764.373]
    julia=[0.025,0.190,1.954,22.580,254.876,5176]
    plot(x,elixir,xlabel="processes",ylabel="time [ms]",xscale=:log10,yscale=:log10,lab="elixir",lw=2)
    plot!(x,julia,lab="julia",lw=2)
    title!("Lightweight processes, Julia vs. Elixir", legend=:bottomright)
end
