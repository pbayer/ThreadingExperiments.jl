#
# In printing from a task, you have to compose the string before passing it to print
#
# see: https://discourse.julialang.org/t/printing-from-a-task/43698
# 
using Printf

struct Msg
    a
    b
end

function tpr(ch::Channel)
    while true
        msg = take!(ch)
        if msg isa Msg
            # println(msg.a, " ", msg.b)              # this doesn't work
            print(@sprintf("%s %s\n", msg.a, msg.b))  # this works
        else
            break
        end
    end
end

ch = Channel(tpr)

put!(ch, Msg("first", "second"))

put!(ch, Msg("first", "second"))
