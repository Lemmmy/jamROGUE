--[[
The MIT License (MIT)
 
Copyright (c) 2013 Lyqyd
 
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
 
The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.
 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
--]]

function new(_sizeX, _sizeY, _color, _xOffset, _yOffset)
	local redirect = {buffer = {text = {}, textColor = {}, backColor = {}, cursorX = 1, cursorY = 1, cursorBlink = false, curTextColor = "0", curBackColor = "f", sizeX = _sizeX or 51, sizeY = _sizeY or 19, color = _color, xOffset = _xOffset or 0, yOffset = _yOffset or 0}}
	local function doWrite(text, textColor, backColor)
		local pos = redirect.buffer.cursorX
		if redirect.buffer.cursorY > redirect.buffer.sizeY or redirect.buffer.cursorY < 1 then
			redirect.buffer.cursorX = pos + #text
			return
		end
		local writeText, writeTC, writeBC
		if pos + #text <= 1 then
			--skip entirely.
			redirect.buffer.cursorX = pos + #text
			return
		elseif pos < 1 then
			--adjust text to fit on screen starting at one.
			local len = math.abs(redirect.buffer.cursorX) + 2
			writeText = string.sub(text, len)
			writeTC = string.sub(textColor, len)
			writeBC = string.sub(backColor, len)
			redirect.buffer.cursorX = 1
		elseif pos > redirect.buffer.sizeX then
			--if we're off the edge to the right, skip entirely.
			redirect.buffer.cursorX = pos + #text
			return
		else
			writeText = text
			writeTC = textColor
			writeBC = backColor
		end
		local lineText = redirect.buffer.text[redirect.buffer.cursorY]
		local lineColor = redirect.buffer.textColor[redirect.buffer.cursorY]
		local lineBack = redirect.buffer.backColor[redirect.buffer.cursorY]
		local preStop = redirect.buffer.cursorX - 1
		local preStart = math.min(1, preStop)
		local postStart = redirect.buffer.cursorX + string.len(writeText)
		local postStop = redirect.buffer.sizeX
		redirect.buffer.text[redirect.buffer.cursorY] = string.sub(lineText, preStart, preStop)..writeText..string.sub(lineText, postStart, postStop)
		redirect.buffer.textColor[redirect.buffer.cursorY] = string.sub(lineColor, preStart, preStop)..writeTC..string.sub(lineColor, postStart, postStop)
		redirect.buffer.backColor[redirect.buffer.cursorY] = string.sub(lineBack, preStart, preStop)..writeBC..string.sub(lineBack, postStart, postStop)
		redirect.buffer.cursorX = pos + string.len(text)
	end
	redirect.write = function(text)
		local text = tostring(text)
		doWrite(text, string.rep(redirect.buffer.curTextColor, #text), string.rep(redirect.buffer.curBackColor, #text))
	end
	redirect.blit = function(text, textColor, backColor)
		if type(text) ~= "string" or type(textColor) ~= "string" or type(backColor) ~= "string" then
			error("Expected string, string, string", 2)
		end
		if #textColor ~= #text or #backColor ~= #text then
			error("Arguments must be the same length", 2)
		end
		doWrite(text, textColor, backColor)
	end
	redirect.clear = function()
		for i=1, redirect.buffer.sizeY do
			redirect.buffer.text[i] = string.rep(" ", redirect.buffer.sizeX)
			redirect.buffer.textColor[i] = string.rep(redirect.buffer.curTextColor, redirect.buffer.sizeX)
			redirect.buffer.backColor[i] = string.rep(redirect.buffer.curBackColor, redirect.buffer.sizeX)
		end
	end
	redirect.clearLine = function()
		redirect.buffer.text[redirect.buffer.cursorY] = string.rep(" ", redirect.buffer.sizeX)
		redirect.buffer.textColor[redirect.buffer.cursorY] = string.rep(redirect.buffer.curTextColor, redirect.buffer.sizeX)
		redirect.buffer.backColor[redirect.buffer.cursorY] = string.rep(redirect.buffer.curBackColor, redirect.buffer.sizeX)
	end
	redirect.getCursorPos = function()
		return redirect.buffer.cursorX, redirect.buffer.cursorY
	end
	redirect.setCursorPos = function(x, y)
		redirect.buffer.cursorX = math.floor(tonumber(x) or redirect.buffer.cursorX)
		redirect.buffer.cursorY = math.floor(tonumber(y) or redirect.buffer.cursorY)
	end
	redirect.setCursorBlink = function(b)
		redirect.buffer.cursorBlink = b
	end
	redirect.getSize = function()
		return redirect.buffer.sizeX, redirect.buffer.sizeY
	end
	redirect.scroll = function(n)
		n = tonumber(n) or 1
		if n > 0 then
			for i = 1, redirect.buffer.sizeY - n do
				if redirect.buffer.text[i + n] then
					redirect.buffer.text[i] = redirect.buffer.text[i + n]
					redirect.buffer.textColor[i] = redirect.buffer.textColor[i + n]
					redirect.buffer.backColor[i] = redirect.buffer.backColor[i + n]
				end
			end
			for i = redirect.buffer.sizeY, redirect.buffer.sizeY - n + 1, -1 do
				redirect.buffer.text[i] = string.rep(" ", redirect.buffer.sizeX)
				redirect.buffer.textColor[i] = string.rep(redirect.buffer.curTextColor, redirect.buffer.sizeX)
				redirect.buffer.backColor[i] = string.rep(redirect.buffer.curBackColor, redirect.buffer.sizeX)
			end
		elseif n < 0 then
			for i = redirect.buffer.sizeY, math.abs(n) + 1, -1 do
				if redirect.buffer.text[i + n] then
					redirect.buffer.text[i] = redirect.buffer.text[i + n]
					redirect.buffer.textColor[i] = redirect.buffer.textColor[i + n]
					redirect.buffer.backColor[i] = redirect.buffer.backColor[i + n]
				end
			end
			for i = 1, math.abs(n) do
				redirect.buffer.text[i] = string.rep(" ", redirect.buffer.sizeX)
				redirect.buffer.textColor[i] = string.rep(redirect.buffer.curTextColor, redirect.buffer.sizeX)
				redirect.buffer.backColor[i] = string.rep(redirect.buffer.curBackColor, redirect.buffer.sizeX)
			end
		end
	end
	redirect.getTextColor = function()
		return 2 ^ tonumber(redirect.buffer.curTextColor, 16)
	end
	redirect.getTextColour = redirect.getTextColor
	redirect.setTextColor = function(clr)
		if clr and clr <= 32768 and clr >= 1 then
			if redirect.buffer.color then
				redirect.buffer.curTextColor = string.format("%x", math.floor(math.log(clr) / math.log(2)))
			elseif clr == 1 or clr == 32768 then
				redirect.buffer.curTextColor = string.format("%x", math.floor(math.log(clr) / math.log(2)))
			else
				return nil, "Colour not supported"
			end
		end
	end
	redirect.setTextColour = redirect.setTextColor
	redirect.getBackgroundColor = function()
		return 2 ^ tonumber(redirect.buffer.curBackColor, 16)
	end
	redirect.getBackgroundColour = redirect.getBackgroundColor
	redirect.setBackgroundColor = function(clr)
		if clr and clr <= 32768 and clr >= 1 then
			if redirect.buffer.color then
				redirect.buffer.curBackColor = string.format("%x", math.floor(math.log(clr) / math.log(2)))
			elseif clr == 32768 or clr == 1 then
				redirect.buffer.curBackColor = string.format("%x", math.floor(math.log(clr) / math.log(2)))
			else
				return nil, "Colour not supported"
			end
		end
	end
	redirect.setBackgroundColour = redirect.setBackgroundColor
	redirect.isColor = function()
		return redirect.buffer.color == true
	end
	redirect.isColour = redirect.isColor
	redirect.render = function(inputBuffer)
		for i = 1, redirect.buffer.sizeY do
			redirect.buffer.text[i] = inputBuffer.text[i]
			redirect.buffer.textColor[i] = inputBuffer.textColor[i]
			redirect.buffer.backColor[i] = inputBuffer.backColor[i]
		end
	end
	redirect.setBounds = function(x_min, y_min, x_max, y_max)
		redirect.buffer.minX = x_min
		redirect.buffer.maxX = x_max
		redirect.buffer.minY = y_min
		redirect.buffer.maxY = y_max
	end
	redirect.setBounds(1, 1, redirect.buffer.sizeX, redirect.buffer.sizeY)
	redirect.clear()
	return redirect
end

function draw(buffer, current)
	for i = buffer.minY, buffer.maxY do
		term.setCursorPos(buffer.minX + buffer.xOffset, i + buffer.yOffset)
		if (current and (buffer.text[i] ~= current.text[i] or buffer.textColor[i] ~= current.textColor[i] or buffer.backColor[i] ~= current.backColor[i])) or not current then
			if term.blit then
				term.blit(buffer.text[i], buffer.textColor[i], buffer.backColor[i])
			else
				local lineEnd = false
				local offset = buffer.minX
				while not lineEnd do
					local limit = buffer.maxX - offset + 1
					local textColorString = string.match(string.sub(buffer.textColor[i], offset), string.sub(buffer.textColor[i], offset, offset).."*")
					local backColorString = string.match(string.sub(buffer.backColor[i], offset), string.sub(buffer.backColor[i], offset, offset).."*")
					term.setTextColor(2 ^ tonumber(string.sub(textColorString, 1, 1), 16))
					term.setBackgroundColor(2 ^ tonumber(string.sub(backColorString, 1, 1), 16))
					term.write(string.sub(buffer.text[i], offset, offset + math.min(#textColorString, #backColorString, limit) - 1))
					offset = offset + math.min(#textColorString, #backColorString, limit)
					if offset > buffer.maxX then lineEnd = true end
				end
			end
			if current then
				current.text[i] = buffer.text[i]
				current.textColor[i] = buffer.textColor[i]
				current.backColor[i] = buffer.backColor[i]
			end
		end
	end
	term.setCursorPos(buffer.cursorX + buffer.xOffset, buffer.cursorY + buffer.yOffset)
	term.setTextColor(2 ^ tonumber(buffer.curTextColor, 16))
	term.setBackgroundColor(2 ^ tonumber(buffer.curBackColor, 16))
	term.setCursorBlink(buffer.cursorBlink)
	return current
end