-----------------------------------------------
-- SoraMame library of ILI9341@65K for W4.00.03
-- Copyright (c) 2019, Saya
-- All rights reserved.
-- 2019/03/20 rev.0.01
-----------------------------------------------
--[[
Pin assign
	PIN PIO	 SPI	TYPE1	TYPE2	TYPE3	TYPE4	TYPE21	TYPE22	TYPE23
CLK  5
CMD  2	0x01 DO 	SDI 	SDI		SDI		SDI/DO	SDI		SDI		SDI
D0	 7	0x02 CLK	SCK 	SCK		SCK		SCK/CLK	SCK		SCK		SCK
D1	 8	0x04 CS 	DC		DC		DC		DC/--	DC		DC		DC
D2	 9	0x08 DI 	CS		CS		CS		CS/DI	CS		(CS)	CS
D3	 1	0x10 RSV	RESET 	PIO		LED		-- /CS2	(CS2)	CS2	CS2
VCC  4
VSS1 3
VSS2 6
--]]

local ILI9341 = {}

--[Low layer functions]--

function ILI9341:writeString(cmd,str,...)
	local spi = fa.spi
	spi("cs",0)
	spi("write",cmd)
	spi("cs",1)
	spi("write",str,...)
end

function ILI9341:writeByte(cmd,...)
	local spi = fa.spi
	spi("cs",0)
	spi("write",cmd)
	spi("cs",1)
	spi("write",...)
end

function ILI9341:writeWord(cmd,...)
	local spi = fa.spi
	spi("cs",0)
	spi("write",cmd)
	spi("cs",1)
	spi("bit",16)
	spi("write",...)
	spi("bit",8)
end

function ILI9341:writeCmd(cmd)
	local spi = fa.spi
	spi("cs",0)
	spi("write", cmd)
	spi("cs",1)
end

function ILI9341:pinCfg(cs2,cs,dc,ck,dt)
	local	pinIo = self.pinIo
	local	pinDt = self.pinDt
	local	ba	  = bit32.band
	local	data, mask
	for i,d in ipairs({cs2,cs,dc,ck,dt}) do
		if d<4 then
			data =2^(5-i)
			mask =-data-1
			pinIo=ba(pinIo,mask)
			pinDt=ba(pinDt,mask)
			if d<2	then pinIo=pinIo+data end
			if d==1 then pinDt=pinDt+data end
		end
	end

	self.pinIo = pinIo
	self.pinDt = pinDt

	return pinIo,pinDt
end

function ILI9341:pinSet(cs2,cs,rs,ck,dt)
	local pinIo,pinDt = self:pinCfg(cs2,cs,dc,ck,dt)
	s,dt = fa.pio(pinIo,pinDt)

	return s,dt
end

---[[
function ILI9341:readData(cmd, num, bit)
	local i, s, dt, val, tbl
	local bx  = bit32.extract
	local bb  = bit32.band

	bit = bit or 8

	self:writeStart()
	for i=7,0,-1 do
		dt = bx(cmd,i,1)
		self.pinSet(4,4,0,0,dt)
		self.pinSet(4,4,0,1,dt)
	end
	self.pinSet(4,4,1,0,2)
	if bit~=8 then
		self.pinSet(4,4,1,1,2)
		self.pinSet(4,4,1,0,2)
	end

	tbl = {}
	for i=1,num do
		val = 0
		for j=1,bit do
			self.pinSet(4,4,1,0,2)
			s,dt = self.pinSet(4,4,1,1,2)
			val = val*2+bb(dt,0x01)
		end
		self.pinSet(4,4,1,0,2)
		tbl[i] = val
	end
	self.pinSet(4,4,1,1,2)
	self.pinSet(4,4,1,0,2)

	self:writeStart()
	return tbl
end
--]]

function ILI9341:writeRam(h,v,str,...)
	local h2,v2=self.h2,self.v2
	if self.mv==1 then h,v,h2,v2=v,h,v2,h2 end
	self:writeWord(0x2A,{h,h2})
	self:writeWord(0x2B,{v,v2})
	self:writeString(0x2C,str,...)
end

function ILI9341:writeRamWord(h,v,data)
	if self.mv==1 then h,v=v,h end
	self:writeWord(0x2A,h)
	self:writeWord(0x2B,v)
	self:writeWord(0x2C,data)
end

function ILI9341:writeRamCmd(h1,v1,h2,v2)
	if self.mv==1 then h1,v1,h2,v2=v1,h1,v2,h2 end
	self:writeWord(0x2A,{h1,h2})
	self:writeWord(0x2B,{v1,v2})
	self:writeCmd(0x2C)
end

function ILI9341:writeRamData(str,...)
	fa.spi("write",str,...)
end

function ILI9341:setRamMode(BGR,MDT,DRC)
-- BGR 0:BGR order,1:RGB order
-- MDT 0:16bit,3:24bit
-- DRC 0:incliment to up,1:incliment to right
--
-- RGB 1:BGR order, 0:RGB order
-- IFPF 3:12bit 5:16bit, 6:18bit
-- MYXV 2:
-- set GRAM writeWord direction and [7]MY,[6]MX,[5]MV,[4]ML,[3]RGB,[2]MH

	local en,i2,i2,val

	en = self.enable
	i1,i2 = en,en
	if en==3 then i1,i2 = 1,2 end

	local MV	= (self.mvDef+DRC)%2
	self.mv = MV
	local ML	= 0
	local RGB	= BGR
	local MH	= 0
	local DPI	= 0x00
	local DBI	= 0x05

	for i=i1,i2 do
		local MY	= self.my
		local MX	= self.mx
		if i==1 then
			MY = (MY+self.yFlip1)%2
			MX = (MX+self.xFlip1)%2
		else
			MY = (MY+self.yFlip2)%2
			MX = (MX+self.xFlip2)%2
		end
		val = MY * 0x80
			+ MX * 0x40
			+ MV * 0x20
			+ ML * 0x10
			+ RGB* 0x08
			+ MH * 0x04
		self:writeStart(i)
		self:writeByte(0x36, val)
	end
	self:writeStart(en)

	-- Interface Pixel Format [2:0]IFPF
	val = DPI * 0x10
		+ DBI
	self:writeByte(0x3A, val)
end

function ILI9341:setWindow(h1,v1,h2,v2)
	if h1>h2 then h1,h2=h2,h1 end
	if v1>v2 then v1,v2=v2,v1 end
	self:writeRamCmd(h1,v1,h2,v2)
end

function ILI9341:resetWindow()
	local h1,h2 = self.rOfs, self.rOfs+self.hSize-1
	local v1,v2 = self.dOfs, self.dOfs+self.vSize-1
	self:writeRamCmd(h1,v1,h2,v2)
end

function ILI9341:pTrans(x,y)
	if self.swp then x,y = y,x end
	return self.hDrc*x+self.hOfs, self.vDrc*y+self.vOfs
end

function ILI9341:bTrans(x1,y1,x2,y2)
	local hD,vD,hO,vO = self.hDrc, self.vDrc, self.hOfs, self.vOfs
	if self.swp then x1,y1,x2,y2 = y1,x1,y2,x2 end
	return hD*x1+hO, vD*y1+vO, hD*x2+hO, vD*y2+vO
end

function ILI9341:clip(x1,y1,x2,y2)
	local xMax = self.xMax
	local yMax = self.yMax
	local a1,ret
	local xd,yd,x0,y0,xm,ym

	xd = x2-x1
	yd = y2-y1
	a1 = y1*x2-y2*x1
	y0 = (xd==0) and y1 or a1/xd
	ym = (xd==0) and y2 or xMax*yd/xd+y0
	x0 = (yd==0) and x1 or -a1/yd
	xm = (yd==0) and x2 or yMax*xd/yd+x0

	if x1>x2 then x1,y1,x2,y2=x2,y2,x1,y1 end
	if x1<0 then x1,y1=0,y0 end
	if x2>xMax then x2,y2=xMax,ym end

	if y1>y2 then x1,y1,x2,y2=x2,y2,x1,y1 end
	if y1<0 then x1,y1=x0,0 end
	if y2>yMax then x2,y2=xm,yMax end

	ret = x1<0 or y1<0 or x2>xMax or y2>yMax or x2<0 or y2<0 or x1>xMax or y1>yMax

	return ret,x1,y1,x2,y2
end

function ILI9341:setup()
	self:writeStart()

	self:writeByte(0xCB,{0x39,0x2C,0x00,0x34,0x02})
	self:writeByte(0xCF,{0x00,0XC1,0X30})
	self:writeByte(0xE8,{0x85,0x00,0x78})
	self:writeByte(0xEA,{0x00,0x00})
	self:writeByte(0xED,{0x64,0x03,0X12,0X81})
	self:writeByte(0xF7, 0x20)
	self:writeByte(0xC0, 0x23)
	self:writeByte(0xC1, 0x10)
	self:writeByte(0xC5,{0x3e,0x28})
 	self:writeByte(0xC7, 0x86)
	self:writeByte(0xB1,{0x00,0x18})
 	self:writeByte(0xB6,{0x08,0x82,0x27})
	self:writeCmd(0x11)
	sleep(120)
	self:writeCmd(0x29)
	self:writeCmd(0x2c)

	self:setRamMode(0,0,0)
	self:resetWindow()
	self:writeEnd()
end

function ILI9341:spiSub(func,data,num)
	local en = self.enable
	local cs = self.spiCstype
	local spi=fa.spi
	local res

	if self.type~=4 then
		return nil
	end
	self:writeEnd()
	self:pinSet(cs,4,4,4,4)
	spi("mode",self.spiMode)
	spi("init",self.spiPeriod)
	spi("bit",self.spiBit)
	if func==0 then
		res = spi("write",data,num)
	else
		res = spi("read",data,num)
	end
	cs = (cs==2) and 2 or 1-cs
	self:pinSet(cs,4,4,4,4)
	if en>0 then
		self:writeStart(en)
	end

	return	res
end

--[For user functions]--

function ILI9341:init(type,rotate,xSize,ySize,rOffset,dOffset,gm)
	local mv,mx,my,swp,hDrc,vDrc,hSize,vSize

	self.type = type
	self.csmd = 0
	self.pinIo= 0x00
	self.pinDt= 0x00
	self:pinCfg(1,1,1,0,0)

	if type==4 or type==21 or type==22 or type==23 then
		self.csmd = 1
		self:pinCfg(1,2,1,0,0)
	end
	if type==2	then
		self.csmd = 0
		self:pinCfg(2,1,1,0,0)
	end

	self:ledOff()

	if rotate==0 then mv,mx,my,swp,hDrc,vDrc = 0,1,1,false, 1,-1 end
	if rotate==1 then mv,mx,my,swp,hDrc,vDrc = 1,1,0,true, -1, 1 end
	if rotate==2 then mv,mx,my,swp,hDrc,vDrc = 0,0,0,false, 1,-1 end
	if rotate==3 then mv,mx,my,swp,hDrc,vDrc = 1,0,1,true, -1, 1 end
--[[
	if gm==3 then
		dOffset = (my>0) and 240-ySize-dOffset or dOffset
	else
		dOffset = (my>0) and 320-ySize-dOffset or dOffset
	end
--]]
    hSize = swp and ySize or xSize
	vSize = swp and xSize or ySize

	self.mvDef= mv
	self.mx	  = mx
	self.my	  = my

	self.swp  = swp
	self.hSize= hSize
	self.vSize= vSize
	self.hDrc = hDrc
	self.vDrc = vDrc
	self.hOfs = (hDrc>0) and rOffset or rOffset+hSize-1
	self.vOfs = (vDrc>0) and dOffset or dOffset+vSize-1
	self.mRot = mRot
	self.xMax = xSize-1
	self.yMax = ySize-1
	self.rOfs = rOffset
	self.dOfs = dOffset
	self.h2   = hSize-1+rOffset
	self.v2   = vSize-1+dOffset
	self.xFlip1= 0
	self.yFlip1= 0
	self.xFlip2= 0
	self.yFlip2= 0

	self.x	  = 0
	self.y	  = 0
	self.x0	  = 0
	self.fc	  = "\255\255"
	self.bc	  = "\000\000"
	self.font = {}
	self.mag  = 1
	self.enable= 0
	self.spiPeriod = 1000
	self.spiMode   = 0
	self.spiBit    = 8

-- reset sequence
	if type==1 then
		self:pinSet(1,0,0,0,0)
		sleep(1)
		self:pinSet(0,0,0,0,0)
		sleep(10)
		self:pinSet(1,0,0,0,0)
		sleep(5)
		self:pinSet(1,1,1,0,0)
	end
	self:writeStart()
	self:writeByte(0x01,0x01) -- Software reset
	self:writeEnd()
	sleep(120)
	self:setup()

	self:writeStart()
	self:cls()
	collectgarbage()
end

function ILI9341:duplicate()
	local new = {}
	for k,v in pairs(self) do
		new[k] = v
	end
	collectgarbage()

	return new
end

function ILI9341:writeStart(enable)
	local en = self.enable
	local type = self.type
	local cs, cs2

	cs = (en==1 or en==3) and ((self.csmd==1) and 2 or 1) or 4
	cs2= (en==2 or en==3) and 1 or 4
	self:pinSet(cs2,cs,4,4,4)

	fa.spi("mode",0)
	fa.spi("init",1)
	fa.spi("bit",8)
	en = (type==22) and 2 or ((type==23) and (enable or 3) or 1)
	cs = (en==1 or en==3) and 0 or 4
	cs2= (en==2 or en==3) and 0 or 4
	self:pinSet(cs2,cs,4,4,4)

	self.enable = en
end

function ILI9341:writeEnd()
	local en = self.enable
	local cs,cs2

	if en>0 then
		self:writeCmd(0x00) -- NOP
		cs = (en==1 or en==3) and ((self.csmd==1) and 2 or 1) or 4
		cs2= (en==2 or en==3) and 1 or 4
		self:pinSet(cs2,cs,4,4,4)

		self.enable = 0
	end
end

function ILI9341:cls()
	self:resetWindow()
	self:writeRamData("",self.hSize*self.vSize*2)
	collectgarbage()
end

function ILI9341:dspOn()
	self:writeCmd(0x29)
	sleep(120)
end

function ILI9341:dspOff()
	self:writeCmd(0x28)
end

function ILI9341:flip(rFlip,dFlip)
	local en = self.enable
	rFlip= rFlip or 0
	dFlip= dFlip or 0

	if en==1 or en==3 then
		self.xFlip1,self.yFlip1=rFlip,dFlip
	end
	if en==2 or en==3 then
		self.xFlip2,self.yFlip2=rFlip,dFlip
	end
	self:setRamMode(0,0,0)
end

function ILI9341:pset(x,y,color)
	if (x<0 or x>self.xMax) then return end
	if (y<0 or y>self.yMax) then return end
	local h,v = self:pTrans(x,y)
	self:writeRamWord(h,v,color)
end

function ILI9341:line(x1,y1,x2,y2,color)
	local swap
	local h1,h2,hn,ha,hb,hd,hv,hr,hs,h
	local v1,v2,vn,vd,v
	local xMax = self.xMax
	local yMax = self.yMax
	local bx = bit32.extract
	local mf = math.floor
	local col = string.char(bx(color,8,8),bx(color,0,8))
	local dat, ret

	if	x1<0 or y1<0 or x2>xMax or y2>yMax or x2<0 or y2<0 or x1>xMax or y1>yMax then
		if self.clip then ret,x1,y1,x2,y2 = self:clip(x1,y1,x2,y2) else ret = true end
		if ret then return end
	end

	x1 = mf(x1+0.5)
	x2 = mf(x2+0.5)
	y1 = mf(y1+0.5)
	y2 = mf(y2+0.5)
	h1,v1,h2,v2 = self:bTrans(x1,y1,x2,y2)
	hn = math.abs(h2-h1)+1
	vn = math.abs(v2-v1)+1
	if hn>vn then
		swap = false
		if self.swp then self:setRamMode(0,0,1) end
		dat = string.rep(col,self.hSize)
	else
		swap = true
		if not self.swp then self:setRamMode(0,0,1) end
		dat = string.rep(col,self.vSize)
		h1,v1,h2,v2 = v1,h1,v2,h2
		hn,vn = vn,hn
	end
--	hd = (self.mx==0) and -1 or 1
	hd = 1
	if h1*hd>h2*hd then h1,v1,h2,v2 = h2,v2,h1,v1 end
	vd = (v1<v2) and 1 or -1
	hv = hd*vd*hn/vn
	ha = h1
	hr = h1+0.5
	hs = hd*2
	for i=v1,v2,vd do
		hb = mf((i-v1+vd)*hv+hr)
		h = swap and i or ha
		v = swap and ha or i
		self:writeRam(h,v,dat,(hb-ha)*hs)
		ha = hb
	end
	  self:setRamMode(0,0,0)
	dat = nil
	collectgarbage()
end

function ILI9341:box(x1,y1,x2,y2,color)
	self:line(x1,y1,x2,y1,color)
	self:line(x2,y1,x2,y2,color)
	self:line(x2,y2,x1,y2,color)
	self:line(x1,y2,x1,y1,color)
end

function ILI9341:boxFill(x1,y1,x2,y2,color)
	local xMax = self.xMax
	local yMax = self.yMax
	local bx = bit32.extract
	local mf = math.floor
	local len,dat,col,vd,hd

	if x1>x2 then x1,x2 = x2,x1 end
	if y1>y2 then y1,y2 = y2,y1 end
	if x2<0 or y2<0 or x1>xMax or y1>yMax then return end
	if x1<0 then x1=0 end
	if y1<0 then y1=0 end
	if x2>xMax then x2=xMax end
	if y2>yMax then y2=yMax end

	col = string.char(bx(color,8,8),bx(color,0,8))
	x1 = mf(x1+0.5)
	x2 = mf(x2+0.5)
	y1 = mf(y1+0.5)
	y2 = mf(y2+0.5)
	h1,v1,h2,v2 = self:bTrans(x1,y1,x2,y2)
	hn = math.abs(h2-h1)+1
	vn = math.abs(v2-v1)+1
	if hn>vn then
		if self.swp then self:setRamMode(0,0,1);h1=h2 end
		dat = string.rep(col,hn)
		vd = (v1>v2) and -1 or 1
		for i=v1,v2,vd do
			self:writeRam(h1,i,dat)
		end
	else
		if not self.swp then self:setRamMode(0,0,1);v1=v2 end
		dat = string.rep(col,vn)
		hd = (h1>h2) and -1 or 1
		for i=h1,h2,hd do
			self:writeRam(i,v1,dat)
		end
	end

	self:setRamMode(0,0,0)
	dat = nil
	collectgarbage()
end

function ILI9341:circle(x,y,xr,yr,color)
	local c
	local x1,y1,x2,y2
	local sin = math.sin
	local cos = math.cos
	local pi  = math.pi

	x1 = x + xr
	y1 = y
	for i=1,64 do
		c = 2*pi*i/64
		x2 = x + xr*cos(c)
		y2 = y + yr*sin(c)
		self:line(x1,y1,x2,y2,color)
		x1 = x2
		y1 = y2
	end
	collectgarbage()
end

function ILI9341:circleFill(x,y,xr,yr,color)
	local h1,v1,h2,v2
	local x1,x2,y1,y2,xs,r2,xn
	local xMax = self.xMax
	local yMax = self.yMax
	local bx  = bit32.extract
	local mf  = math.floor
	local sqrt= math.sqrt
	local col = string.char(bx(color,8,8),bx(color,0,8))
	local dat = string.rep(col,(xMax+1))

	x = mf(x+0.5)
	y = mf(y+0.5)
	r2 = yr*yr

	if y>=0 and y<=yMax then
		xs = mf(xr)
		x1 = x-xs
		x2 = x+xs
		if x1<0 then x1=0 end
		if x2>xMax then x2=xMax end
		xn= (x2-x1+1)*2
		h1,v1 = self:pTrans(x1,y)
		self:writeRam(h1,v1,dat,xn)
	end

	for i=1,yr do
		xs = mf(sqrt(r2-i*i)*xr/yr)
		x1 = x-xs
		x2 = x+xs
		y1 = y-i
		y2 = y+i
		if x1<0 then x1=0 end
		if x2>xMax then x2=xMax end
		xn= (x2-x1+1)*2
		h1,v1,h2,v2 = self:bTrans(x1,y1,x2,y2)
		if y1>=0 then self:writeRam(h1,v1,dat,xn) end
		if self.swp then v2=v1 else h2=h1 end
		if y2<=yMax then self:writeRam(h2,v2,dat,xn) end
	end

	dat = nil
	collectgarbage()
end

function ILI9341:put(x,y,bitmap)
	local bx,by= 0,0
	local xMax = self.xMax
	local yMax = self.yMax
	local bw   = bitmap.width
	local bh   = bitmap.height
	local bb   = bitmap.bit/8
	local flat = bitmap.flat
	local br   = bw*bb
	local bi,bn
	local h1,v2,hs,vs

	if( x>xMax or y>yMax or x+bw<0 or y+bh<0 ) then return end
	if( x<0 ) then x,bw,bx=0,bw+x,-x end
	if( y<0 ) then y,bh=0,bh+y end
	if( x+bw>xMax+1 ) then bw=xMax+1-x end
	if( y+bh>yMax+1 ) then bh,by=yMax+1-y,y+bh-yMax-1 end
	h1,v2 = self:pTrans(x,y+bh-1)
--	hs = (self.mx==0) and 1 or -1
	hs = -1
	vs = hs
	if self.swp then vs=0 else hs=0 end

	if bx==0 then
		if( flat==0 )then
			bn = bw*bb
			for i=0,bh-1 do
				self:writeRam(h1-i*hs,v2-i*vs,bitmap.data[by+i+1],bn)
			end
		else
			for i=0,bh-1 do
				bs = (by+i)*br+1
				bn = bs+bw*bb-1
				self:writeRam(h1-i*hs,v2-i*vs,bitmap.data:sub(bs,bn))
			end
		end
	else
		bs = bx*bb+1
		bn = (bx+bw)*bb
		if( flat==0 )then
			for i=0,bh-1 do
				self:writeRam(h1-i*hs,v2-i*vs,bitmap.data[by+i+1]:sub(bs,bn))
				collectgarbage()
			end
		else
			bs = bs+by*br
			bn = bn+by*br
			for i=0,bh-1 do
				self:writeRam(h1-i*hs,v2-i*vs,bitmap.data:sub(bs,bn))
				bs = bs+br
				bn = bn+br
				collectgarbage()
			end
		end
	end
	collectgarbage()
end

function ILI9341:put2(x,y,bitmap)
	local x2 = x+bitmap.width-1
	local y2 = y+bitmap.height-1
	local h1,v1,h2,v2 = self:bTrans(x,y,x2,y2)
	self:setWindow(h1,v1,h2,v2)
	self:writeRamData(bitmap.data)
	self:resetWindow()
	collectgarbage()
end

function ILI9341:locate(x,y,mag,color,bgcolor,font)
	local bx = bit32.extract
	local mf = math.floor

	if x then
		self.x	= mf(x+0.5)
		self.x0 = self.x
	end
	if y then
		self.y	= mf(y+0.5)
	end
	if mag then
		self.mag= mf(mag)
	end
	if color then
		self.fc = string.char(bx(color,8,8),bx(color,0,8))
	end
	if bgcolor then
		self.bc = string.char(bx(bgcolor,8,8),bx(bgcolor,0,8))
	end
	if font then
		self.font = font
	end
end

function ILI9341:print(str)
	local n,c,b,bk,bj,il,is,sn,slen,sp
	local h1,v1,h2,v2
	local s = ""
	local p = {}
	local fw = self.font.width
	local fh = self.font.height
	local mg = self.mag
	local bx = bit32.extract
	local mf = math.floor
	local s0 = string.rep(self.bc,mg)
	local s1 = string.rep(self.fc,mg)
	local ti = table.insert

	self:setRamMode(0,0,1)

	is = 1
	slen = #str
	while slen>0 do
		sn = mf((self.xMax+1-self.x)/mg/fw)
		il = sn<slen and sn or slen
		slen = slen - il
		h1,v1,h2,v2 = self:bTrans(self.x,self.y,self.xMax,self.y+mg*fh-1)
		self:setWindow(h1,v1,h2,v2)
--		if self.mx==0 then self:writeRamCmd(h1,v2) else	self:writeRamCmd(h2,v1) end

		bk=1
		for i=is,is+il-1 do
			c = str.sub(str,i,i)
			b = self.font[c]
			for j=1,fw do
				bj,bk=b[j],bk+fh
				for k=fh-1,0,-1 do ti(p,bx(bj,k)>0 and s1 or s0) end
				if bk>800 or mg>1 then
					s = table.concat(p)
					for l=1,mg do
						self:writeRamData(s)
					end
					bk=1
					p={}
				end
			end
		end
		if bk>1 and il>0 then
			s = table.concat(p)
			for l=1,mg do
				 self:writeRamData(s)
			end
			p={}
		end
		self.x = self.x+mg*fw*il
		if slen>0 or self.x>self.xMax then
			self.x,self.y = self.x0,self.y+mg*fh
			is = is+il
		end
		s=""
		collectgarbage()
	end
	self:resetWindow()
	self:setRamMode(0,0,0)

	return self.x,self.y
end

function ILI9341:println(str)
	self:print(str)
	self.x,self.y = self.x0,self.y+self.mag*self.font.height

	return self.x,self.y
end

function ILI9341:pio(ctrl, data)
	local dat,s,ret

	if self.type>1 then
		s,ret = self:pinSet((1-ctrl)*2+data,4,4,4,4)
		if s==1 then
			ret = bit32.btest(ret,0x10) and 1 or 0
		end
	end

	return ret
end

function ILI9341:ledOn()
	if self.type==3 then
		sleep(30)
		self:pio(1,1)
	end
end

function ILI9341:ledOff()
	if self.type==3 then
		self:pio(1,0)
	end
end

function ILI9341:spiInit(period,mode,bit,cstype)
	if self.type~=4 then
		return
	end
	self.spiPeriod = period
	self.spiMode   = mode
	self.spiBit    = bit
	self.spiCstype = cstype or 0
	local cs = (cstype==2) and 2 or 1-cstype
	self:pinSet(cs,4,4,4,4)
end

function ILI9341:spiWrite(data,num)
	return self.spiSub(0,data,num)
end

function ILI9341:spiRead(data,num)
	return self.spiSub(1,data,num)
end

collectgarbage()
return ILI9341
