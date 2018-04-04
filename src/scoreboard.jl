#Pkg.add("Gtk")
using Gtk.ShortNames

start_button = Button()
time_label = Label("")

function startStopButton(widget)
    if getproperty(widget, :label, String) == "Start"
        setproperty!(widget, :label, "Stop")
    else
        setproperty!(widget, :label, "Start")
    end
end

function clearButton(widget)
    global start_button
    if getproperty(start_button, :label, String) == "Stop"
        setproperty!(start_button, :label, "Start")
    end
    println("Clear button! yay!")
end

function addButton(widget)
    println("Add button! yay!")
end

function main()
    global start_button, time_label
    glade_file = rsplit(@__FILE__,"/",limit=3)[1] * "/glade_files/main_window.glade"
    builder = Builder(filename=glade_file)
    window = builder["applicationwindow1"]
    setproperty!(window, :title, "Timed Scoreboard :)")
    showall(window)

    start_button = builder["button1"]
    clear_button = builder["button2"]
    add_button = builder["button4"]
    signal_connect(startStopButton, start_button, "clicked")
    signal_connect(clearButton, clear_button, "clicked")
    signal_connect(addButton, add_button, "clicked")

    time_label = builder["label1"]



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
