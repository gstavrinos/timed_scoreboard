#Pkg.add("Gtk")
using Gtk.GAccessor
using Gtk.ShortNames

struct ListEntry
    name::String
    time::String
end

cancel_button = Button()
start_button = Button()
clear_button = Button()
add_button2 = Button()
add_button = Button()
time_label = Label("")
run_timer = true
grid = Grid()
name_entry = Entry()
popup_glade_file = ""
start_t = DateTime(0)
entries = ListEntry[]
resizable_widgets = []
window = Window(visible=false)
popup_window = Window(visible=false)
timer_curr_size = 32
min_timer_size = 25
max_timer_size = 50
min_rest_size = 10
max_rest_size = 50
rest_curr_size = 10
already_open_popup = false

Base.:(==)(x::ListEntry, y::ListEntry) = x.name == y.name
Base.:(<)(x::ListEntry, y::ListEntry) = x.time < y.time
Base.:(isless)(x::ListEntry, y::ListEntry) = x.time < y.time
Base.:(<=)(x::ListEntry, y::ListEntry) = x.time <= y.time
Base.:(>)(x::ListEntry, y::ListEntry) = x.time > y.time
Base.:(>=)(x::ListEntry, y::ListEntry) = x.time >= y.time

function startStopButton(widget)
    global run_timer, time_label, start_t
    if getproperty(widget, :label, String) == "Start"
        if contains(getproperty(time_label, :label, String), "00:00.000")
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
            l = Base.length(formatted_final_t)

            if l == 7
                formatted_final_t *= "00"
            elseif l == 8
                formatted_final_t *= "0"
            end

            #setproperty!(time_label, :label, formatted_final_t)
            mu = "<span font_desc=\"Sans "*string(timer_curr_size)*"\">"*formatted_final_t*"</span>"
            GAccessor.markup(time_label, mu)
            prev = curr
            sleep(0.001)
        end
    else
        run_timer = false
        setproperty!(widget, :label, "Start")
    end
    return true
end

function clearButton(widget)
    global start_button, time_label, run_timer, timer_curr_size
    run_timer = false
    if getproperty(start_button, :label, String) == "Stop"
        setproperty!(start_button, :label, "Start")
    end
    #setproperty!(time_label, :label, "00:00.000")
    mu = "<span font_desc=\"Sans "*string(timer_curr_size)*"\">00:00.000</span>"
    GAccessor.markup(time_label, mu)
end

function addButton(widget)
    global time_label, popup_glade_file, popup_window, name_entry, add_button2, cancel_button, already_open_popup
    if ! already_open_popup
        builder2 = Builder(filename=popup_glade_file)
        popup_window = builder2["window1"]
        already_open_popup = true
        setproperty!(popup_window, :title, "Add new entry! :)")
        add_button2 = builder2["button1"]
        cancel_button = builder2["button2"]
        name_entry = builder2["entry1"]
        signal_connect(popupKeySwitch, popup_window, "key-press-event")
        signal_connect(addNewName, add_button2, "clicked")
        signal_connect(killPopup, cancel_button, "clicked")
        showall(popup_window)
    end
end

function increaseFont(widget)
    global time_label, grid, rest_curr_size, timer_curr_size, max_rest_size, max_timer_size
    timer_curr_size += 1
    if ! (timer_curr_size > max_timer_size)
        mu = "<span font_desc=\"Sans "*string(timer_curr_size)*"\">"*getproperty(time_label, :label, String)[27:end-7]*"</span>"
        GAccessor.markup(time_label, mu)
    else
        timer_curr_size = max_timer_size
    end
    rest_curr_size += 1
    if ! (rest_curr_size > max_rest_size)
        for i in grid
            if ! (typeof(i) <: Button)
                mu = "<span font_desc=\"Sans "*string(rest_curr_size)*"\">"*getproperty(i, :label, String)[27:end-7]*"</span>"
                println(mu)
                GAccessor.markup(i, mu)
            end
        end
    else
        rest_curr_size = max_rest_size
    end
end

function decreaseFont(widget)
    global time_label, grid, rest_curr_size, timer_curr_size, min_rest_size, min_timer_size
    timer_curr_size -= 1
    if ! (timer_curr_size < min_timer_size)
        mu = "<span font_desc=\"Sans "*string(timer_curr_size)*"\">"*getproperty(time_label, :label, String)[27:end-7]*"</span>"
        GAccessor.markup(time_label, mu)
    else
        timer_curr_size = min_timer_size
    end
    rest_curr_size -= 1
    if ! (rest_curr_size < min_rest_size)
        for i in grid
            if ! (typeof(i) <: Button)
                mu = "<span font_desc=\"Sans "*string(rest_curr_size)*"\">"*getproperty(i, :label, String)[27:end-7]*"</span>"
                println(mu)
                GAccessor.markup(i, mu)
            end
        end
    else
        rest_curr_size = min_rest_size
    end
end

function deleteButton(widget)
    global grid, entries, window
    maxi = Base.length(entries)
    for i in Base.range(1, maxi)
        if getproperty(grid[4,i+1], :name, String) == getproperty(widget, :name, String)
            le = ListEntry(getproperty(grid[2,i+1], :label, String), getproperty(grid[3,i+1], :label, String))
            deleteat!(entries, i)
            break
        end
    end
    showall(window)
    updateEntries(true)
end

function killPopup(widget)
    global popup_window, already_open_popup
    already_open_popup = false
    destroy(popup_window)
end

function addNewName(widget)
    global name_entry, entries, time_label
    n = getproperty(name_entry, :text, String)
    if Base.length(n) > 0
        le = ListEntry(n, getproperty(time_label, :label, String)[27:end-7])
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

function updateEntries(fromDelete=false)
    global grid, entries, window, rest_curr_size
    i = 2
    maxi = Base.length(entries)
    if fromDelete
        maxi += 2
    else
        sort!(entries)
    end
    for ii in Base.range(1, maxi-1)
        delete!(grid, grid[1,ii+1])
        delete!(grid, grid[2,ii+1])
        delete!(grid, grid[3,ii+1])
        delete!(grid, grid[4,ii+1])
    end
    for e in entries
        l1 = Label("")
        mu = "<span font_desc=\"Sans "*string(rest_curr_size)*"\">"*string(i-1)*"</span>"
        GAccessor.markup(l1, mu)
        grid[1,i] = l1
        l2 = Label("")
        mu = "<span font_desc=\"Sans "*string(rest_curr_size)*"\">"*e.name*"</span>"
        GAccessor.markup(l2, mu)
        grid[2,i] = l2
        l3 = Label("")
        mu = "<span font_desc=\"Sans "*string(rest_curr_size)*"\">"*e.time*"</span>"
        GAccessor.markup(l3, mu)
        grid[3,i] = l3
        xb = Button("X")
        setproperty!(xb, :name, i)
        signal_connect(deleteButton, xb, "clicked")
        grid[4,i] = xb
        i += 1
    end
    showall(window)
end

function keySwitch(widget, event)
    global start_button, add_button, clear_button
    if event.keyval == 115 #s
        startStopButton(start_button)
    elseif event.keyval == 97 #a
        addButton(widget)
    elseif event.keyval == 99 #c
        clearButton(clear_button)
    elseif event.keyval == 43 #+
        increaseFont(widget)
    elseif event.keyval == 95 #-
        decreaseFont(widget)
    end
end

function popupKeySwitch(widget, event)
    global add_button2, cancel_button
    if event.keyval == 65293 #enter
        addNewName(add_button2)
    elseif event.keyval == 65307 #esc
        killPopup(cancel_button)
    end
end

function main()
    global start_button, add_button, clear_button, time_label, popup_glade_file, grid, window, timer_curr_size
    popup_glade_file = rsplit(@__FILE__,"/",limit=3)[1] * "/glade_files/name_popup.glade"
    glade_file = rsplit(@__FILE__,"/",limit=3)[1] * "/glade_files/main_window.glade"
    builder = Builder(filename=glade_file)
    window = builder["applicationwindow1"]
    setproperty!(window, :title, "Timed Scoreboard :)")
    showall(window)

    start_button = builder["button1"]
    clear_button = builder["button2"]
    add_button = builder["button4"]
    plus_button = builder["button3"]
    minus_button = builder["button5"]
    grid = builder["grid1"]
    signal_connect(startStopButton, start_button, "clicked")
    signal_connect(clearButton, clear_button, "clicked")
    signal_connect(addButton, add_button, "clicked")
    signal_connect(increaseFont, plus_button, "clicked")
    signal_connect(decreaseFont, minus_button, "clicked")
    signal_connect(keySwitch, window, "key-press-event")

    time_label = builder["label1"]

    mu = "<span font_desc=\"Sans "*string(timer_curr_size)*"\">"*getproperty(time_label, :label, String)*"</span>"
    GAccessor.markup(time_label, mu)
    mu = "<span font_desc=\"Sans "*string(rest_curr_size)*"\">"*getproperty(grid[3,1], :label, String)*"</span>"
    GAccessor.markup(grid[3,1], mu)
    mu = "<span font_desc=\"Sans "*string(rest_curr_size)*"\">"*getproperty(grid[2,1], :label, String)*"</span>"
    GAccessor.markup(grid[2,1], mu)
    mu = "<span font_desc=\"Sans "*string(rest_curr_size)*"\">"*getproperty(grid[1,1], :label, String)*"</span>"
    GAccessor.markup(grid[1,1], mu)

    if !isinteractive()
        c = Condition()
        signal_connect(window, :destroy) do widget
            notify(c)
        end
        wait(c)
    end
end

# TODO
# fix widgets pushing each other on very large fonts
main()
