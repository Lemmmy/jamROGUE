local buffer = require("src/buffer.lua")

return function(main)
    local timerp = os.startTimer(0.05)
    local timercent = os.startTimer(0.15)

    while not main.exiting do
        local event, p1, p2, p3 = os.pullEvent()

        if event == "timer" and p1 == timerp then
            main.stateTime = os.clock() - main.stateStartTime

            if main.states[main.state] then
                if main.states[main.state].update then
                    main.states[main.state].update()
                end

                if main.states[main.state].draw then
                    buffer.clear()

                    main.states[main.state].draw()
                end

                framebuffer.draw(buffer.buffer)
            end

            timerp = os.startTimer(0.05)
        elseif event == "timer" and p1 == timercent then
            if main.states[main.state] then
                if main.states[main.state].updateCent then
                    main.states[main.state].updateCent()
                end
            end

            timercent = os.startTimer(0.1)
        elseif event == "key_up" then
            if not main.stateTime and main.stateTime <= 0.25 then return end

            if main.states[main.state] and main.states[main.state].keyUp then
                main.states[main.state].keyUp(keys.getName(p1), p1)
            end
        elseif event == "key" then
            if main.states[main.state] and main.states[main.state].key then
                main.states[main.state].key(keys.getName(p1), p1, p2)
            end
        elseif event == "mouse_click" then
            if main.states[main.state] and main.states[main.state].mouseClick then
                main.states[main.state].mouseClick(p1, p2, p3)
            end
        elseif event == "paste" then
            if main.states[main.state] and main.states[main.state].paste then
                main.states[main.state].paste(p1)
            end
        elseif event == "char" then
            if main.states[main.state] and main.states[main.state].char then
                main.states[main.state].char(p1)
            end
        elseif event == "http_success" then
            if main.states[main.state] and main.states[main.state].httpSuccess then
                main.states[main.state].httpSuccess(p1, p2)
            end
        elseif event == "http_failure" then
            if main.states[main.state] and main.states[main.state].httpFailure then
                main.states[main.state].httpFailure(p1)
            end
        end
    end

    term.setCursorPos(1, 1)
    term.clear()
end