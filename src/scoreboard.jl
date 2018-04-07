#Pkg.add("Gtk")
using Gtk.ShortNames

struct ListEntry
    name::String
    time::String
end

start_button = Button()
time_label = Label("")
run_timer = true
start_t = DateTime(0)
popup_glade_file = ""
popup_window = Window(visible=false)
name_entry = Entry()
entries = ListEntry[]
grid = Grid()
window = Window(visible=false)

Base.:(==)(x::ListEntry, y::ListEntry) = x.name == y.name
Base.:(<)(x::ListEntry, y::ListEntry) = x.time < y.time
Base.:(isless)(x::ListEntry, y::ListEntry) = x.time < y.time
Base.:(<=)(x::ListEntry, y::ListEntry) = x.time <= y.time
Base.:(>)(x::ListEntry, y::ListEntry) = x.time > y.time
Base.:(>=)(x::ListEntry, y::ListEntry) = x.time >= y.time

function startStopButton(widget)
    global run_timer, time_label, start_t
    if getproperty(widget, :label, String) == "Start"
        if getproperty(time_label, :label, String) == "00:00.000"
            start_t = DateTime(0)
        end
        run_timer = true
        setproperty!(widget, :label, "Stop")
        prev = now()
        @async while run_timer
            curr = now()
            t = curr - prev
            start_t += t
            final_t = Dates.Time(start_t + t)
            formatted_final_t = Dates.format(final_t, "MM:SS.s")
            l = length(formatted_final_t)

            if l == 7
                formatted_final_t *= "00"
            elseif l == 8
                formatted_final_t *= "0"
            end

            setproperty!(time_label, :label, formatted_final_t)
            prev = curr
            sleep(0.001)
        end
    else
        run_timer = false
        setproperty!(widget, :label, "Start")
    end
end

function clearButton(widget)
    global start_button, time_label, run_timer
    run_timer = false
    if getproperty(start_button, :label, String) == "Stop"
        setproperty!(start_button, :label, "Start")
    end
    setproperty!(time_label, :label, "00:00.000")
end

function addButton(widget)
    global time_label, popup_glade_file, popup_window, name_entry
    builder2 = Builder(filename=popup_glade_file)
    popup_window = builder2["window1"]
    setproperty!(popup_window, :title, "Add new entry! :)")
    add_button = builder2["button1"]
    cancel_button = builder2["button2"]
    name_entry = builder2["entry1"]
    signal_connect(addNewName, add_button, "clicked")
    signal_connect(killPopup, cancel_button, "clicked")
    showall(popup_window)
end

function killPopup(widget)
    global popup_window
    destroy(popup_window)
end

function addNewName(widget)
    global name_entry, entries, time_label
    n = getproperty(name_entry, :text, String)
    if length(n) > 0
        le = ListEntry(n, getproperty(time_label, :label, String))
        if !(le in entries)
            push!(entries, le)
            updateEntries()
            killPopup(widget)
        else
            warn_dialog("This name already exists on the list!")
        end
    else
        warn_dialog("The name cannot be empty!")
    end
end

function updateEntries()
    global grid, entries, window
    sort!(entries)
    i = 2
    maxi = length(entries)
    for e in entries
        if i < maxi
            setproperty!(grid[1,i], :label, string(i-1))
            setproperty!(grid[2,i], :label, e.name)
            setproperty!(grid[3,i], :label, e.time)
        else
            grid[1,i] = Label(string(i-1))
            grid[2,i] = Label(e.name)
            grid[3,i] = Label(e.time)
        end
        i += 1
    end
    showall(window)
end

function main()
    global start_button, time_label, popup_glade_file, grid, window
    glade_file = rsplit(@__FILE__,"/",limit=3)[1] * "/glade_files/main_window.glade"
    popup_glade_file = rsplit(@__FILE__,"/",limit=3)[1] * "/glade_files/name_popup.glade"
    builder = Builder(filename=glade_file)
    window = builder["applicationwindow1"]
    setproperty!(window, :title, "Timed Scoreboard :)")
    showall(window)

    start_button = builder["button1"]
    clear_button = builder["button2"]
    add_button = builder["button4"]
    grid = builder["grid1"]
    signal_connect(startStopButton, start_button, "clicked")
    signal_connect(clearButton, clear_button, "clicked")
    signal_connect(addButton, add_button, "clicked")

    time_label = builder["label1"]

    if !isinteractive()
        c = Condition()
        signal_connect(window, :destroy) do widget
            notify(c)
        end
        wait(c)
    end
end

main()
