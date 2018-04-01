#Pkg.add("Gtk")
using Gtk.ShortNames

function main()
    window = Window("Scoreboard", 640, 480, true, true)

    # Put your GUI code here

    if !isinteractive()
        c = Condition()
        signal_connect(window, :destroy) do widget
            notify(c)
        end
        wait(c)
    end
end

main()
