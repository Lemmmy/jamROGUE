local w, h = term.getSize()
local buffer = window.create(term.current(), 1, 1, w, h)

buffer.setVisible(true)

return buffer