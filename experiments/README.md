# Threading experiments

1. the [chain experiment](https://github.com/pbayer/ThreadingExperiments.jl/tree/master/experiments/chain) compares lightweight tasks in Julia and Elixir and shows that Julia programs involving tasks and task switching can be sped up by relocating them to threads other than one.
2. [printing from a task](https://discourse.julialang.org/t/printing-from-a-task/43698) shows how to do it correctly 
