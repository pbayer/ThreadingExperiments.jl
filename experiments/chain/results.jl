using Plots

function plot_results()
    x = map(x->10^x,1:6)
    elixir=[3.355,3.571,7.871,50.252,506.419,4764.373]
    julia=[0.025,0.190,1.954,22.580,254.876,5176]
    plot(x,elixir,xlabel="processes",ylabel="time [ms]",xscale=:log10,yscale=:log10,lab="elixir",lw=2)
    plot!(x,julia,lab="julia",lw=2)
    title!("Lightweight processes, Julia vs. Elixir", legend=:bottomright)
end
