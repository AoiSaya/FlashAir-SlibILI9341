-----------------------------------------------
-- Sample of SlibILI9341.lua for W4.00.03
-- Copyright (c) 2019, Saya
-- All rights reserved.
-- 2019/06/01 rev.0.02
-----------------------------------------------
function chkBreak(n)
	sleep(n or 0)
		if fa.sharedmemory("read", 0x00, 0x01, "") == "!" then
		error("Break!",2)
	end
end
fa.sharedmemory("write", 0x00, 0x01, "-")

function script_path()
	local  str = debug.getinfo(2, "S").source:sub(2)
	return str:match("(.*/)")
end

local to64K = function(dat)
	local bx = bit32.extract
	local r = bx(dat,19,5)
	local g = bx(dat,10,6)
	local b = bx(dat, 3,5)
	return b*2048 + g*32 + r
end

-- main
local myDir  = script_path()
local libDir = myDir.."lib/"
local imgDir = myDir.."img/"
local fontDir= myDir.."font/"
local lcd = require(libDir .. "SlibILI9341")
local bmp = require(libDir .. "SlibBMP")
local font74 = require(fontDir .. "font74")
local x1,y1,x2,y2,c
local mx,my,rOfs,dOfs,gm

--color bar
local cbar={
0xC0C0C0,
0xC0C000,
0x00C0C0,
0x00C000,
0xC000C0,
0xC00000,
0x0000C0,

0x0000C0,
0x131313,
0xC000C0,
0x131313,
0x00C0C0,
0x131313,
0xC0C0C0,

0x00214C,
0xFFFFFF,
0x31006B,
0x131313,
0x090909,
0x131313,
0x1D1D1D,
0x131313,
}

local COL_K = to64K(0x000000) -- kuro
local COL_B = to64K(0x0000FF) -- blue
local COL_R = to64K(0xFF0000) -- red
local COL_M = to64K(0xFF00FF) -- magenta
local COL_G = to64K(0x00FF00) -- green
local COL_C = to64K(0x00FFFF) -- cyan
local COL_Y = to64K(0xFFFF00) -- yellow
local COL_W = to64K(0xFFFFFF) -- white

for rot = 0,3 do
	if rot==0 or rot==2 then
		mx,my,rOfs,dOfs,gm = 240,320,0,0,0
	else
		mx,my,rOfs,dOfs,gm = 320,240,0,0,0
	end

	lcd:init(1, rot, mx, my, rOfs, dOfs, gm)
	lcd:dspOn()

---[[
-- color bar
	for i=0,7 do
		lcd:boxFill(i*mx/7,0,(i+1)*mx/7-1,my*8/12-1,to64K(cbar[i+1]))
	end
	for i=0,7 do
		lcd:boxFill(i*mx/7,my*8/12,(i+1)*mx/7-1,my*9/12-1,to64K(cbar[i+8]))
	end
	for i=0,2 do
		lcd:boxFill(i*mx/6,my*9/12,(i+1)*mx/6,my-1,to64K(cbar[i+15]))
	end
	lcd:boxFill(3*mx/6,my*9/12,5*mx/7,my-1,to64K(cbar[18]))
	for i=0,2 do
		lcd:boxFill(5*mx/7+i*mx/21,my*9/12,5*mx/7+(i+1)*mx/21,my-1,to64K(cbar[i+19]))
	end
	lcd:boxFill(6*mx/7,my*9/12,mx-1,my-1,to64K(cbar[22]))
--]]
---[[
	lcd:box(0,0,mx-1,my-1,COL_W) -- for offset check
	chkBreak()
	sleep(1000)
	local rnd = math.random
	lcd:cls()
	collectgarbage()
--pset demo
	for i=1,3000 do
		x1,y1,c = rnd(0,mx-1),rnd(0,my-1),rnd(0,0xFFFF)
		lcd:pset(x1,y1,c)
	end

--line demo
	for i=1,50 do
		x1,y1,x2,y2,c = rnd(0,mx-1),rnd(0,my-1),rnd(0,mx-1),rnd(0,my-1),rnd(0,0xFFFF)
		lcd:line(x1,y1,x2,y2,c)
	end

--box demo
	for i=1,30 do
		x1,y1,x2,y2,c = rnd(0,mx-1),rnd(0,my-1),rnd(20,mx-1),rnd(20,my-1),rnd(0,0xFFFF)
		lcd:box(x1,y1,x2,y2,c)
	end

--boxfill demo
	for i=1,20 do
		x1,y1,x2,y2,c = rnd(0,mx-1),rnd(0,my-1),rnd(20,mx-1),rnd(20,my-1),rnd(0,0xFFFF)
		lcd:boxFill(x1,y1,x2,y2,c)
end

--circle demo
	for i=1,10 do
		x1,y1,xr,yr,c = rnd(0,mx-1),rnd(0,my-1),rnd(20,mx/2-1),rnd(20,my/2-1),rnd(0,0xFFFF)
		lcd:circle(x1,y1,xr,yr,c)
	end

--circlefill demo
	for i=1,20 do
		x1,y1,xr,yr,c = rnd(0,mx-1),rnd(0,my-1),rnd(20,mx/2-1),rnd(20,my/2-1),rnd(0,0xFFFF)
		lcd:circleFill(x1,y1,xr,yr,c)
	end

--]]
---[[
--locate and print demo
	n = 0x20
	for i=0,21,7 do
		chkBreak()
		lcd:setFont(font74)
		lcd:locate(0,i,1)
		for j=0, mx-1, 4 do
			lcd:color(to64K(cbar[(i/7+j)%7+1]))
			lcd:print(string.char(n))
			n = n>=0x7E and 0x20 or n+1
		end
	end

--locate and println demo
	lcd:locate(0,28)
	for i=1,7 do
		lcd:locate(nil,nil,i)
		lcd:color(to64K(cbar[i]))
		lcd:println(string.sub("01234567890ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqr",1,mx/4/i-0.1))
	end

--]]
---[[
--put, put2 demo
	local balloonBmp = bmp:loadFile(imgDir .. "balloon01.bmp",1)
	local balloonImg = bmp:conv64K(balloonBmp)
	lcd:put(0,0,balloonImg)
	lcd:put2(64,64,balloonImg)

	local balloonImg = bmp:conv64K(imgDir .. "balloon02.bmp",0,0,mx,my,0x0000)
	collectgarbage()
	lcd:put(0,0,balloonImg)

	sleep(1000)
	balloonBmp=nil
	balloonImg=nil
	collectgarbage()
--]]
end
