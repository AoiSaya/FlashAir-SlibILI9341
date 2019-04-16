# FlashAir-SlibILI9341

Lua library for TFT display modules with ILI9341 for FlashAir.  
<img src="img/ILI9341connect01.jpg" width="300">

## Tested equipment

Tested on the following TFT display module and FlashAir W-04 v4.00.03.  

 2.4inch SPI Module ILI9341(SKU:MSP2402)
--- | ---
240x320 offset=(0,0) gs=0
<img src="img/ILI9341front01.jpg" width="200">
<img src="img/ILI9341back01.jpg" width="200">

## FlashAir to TFT module connections

Please choose your favorite TYPE.

### Rename table

this text | module pin
--- | ---
CLK| CLK or SCK or SCL
SDI| SDI or SDA
DC | RS  or A0  or DC
CS or CS2| CS
RESET|RST or RESET or RES
LED| LED or LEDA  or BLK
GND| GND 
VCC| VCC

### TYPE list

FlashAir|TYPE1|TYPE2|TYPE3|TYPE4|TYPE21|TYPE22|TYPE23
--- | --- | --- | --- | --- | --- | --- | ---
---  |w/Reset|w/PIO|w/LED|w/SPI|primaly|secondary|twin
CMD  |SDI |SDI |SDI |SDI/DO |SDI   |SDI  |SDI
DAT0 |CLK |CLK |CLK |CLK/CLK|CLK   |CLK  |CLK
DAT1 |DC  |DC  |DC  |DC /-- |DC    |DC   |DC 
DAT2 |CS  |CS  |CS  |CS /DI |CS    |(CS )|CS 
DAT3 |RESET|PIO |LED |-- /CS |(CS2 )|CS2  |CS2 

*TYPE21,TYPE22,TYPE23 for two display*

### TYPE1  
Module Reset is hardwere reset.  

FlashAir(Pin#) | ILI9341 TFT | Power | comment
--- | --- | --- | ---
CLK (5) |--- |Pull-down(10korm) to GND
CMD (2) |SDI |
DAT0(7) |CLK |
DAT1(8) |DC  |
DAT2(9) |CS  |
DAT3(1) |RESET|
---     |LED |3.3V|
VCC (4) |VCC |3.3V   
VSS(3,6)|GND |GND    

### TYPE2  
DAT3 of FlashAir can be used for PIO.  

FlashAir(Pin#) | ILI9341 TFT | Power | comment
--- | --- | --- | ---
CLK (5) |--- |Pull-down(10korm) to GND
CMD (2) |SDI |
DAT0(7) |CLK |
DAT1(8) |DC  |
DAT2(9) |CS  |
DAT3(1) |PIO |
---     |RESET|Pull-up(10korm) to 3.3V
---     |LED |3.3V
VCC (4) |VCC |3.3V
VSS(3,6)|GND |GND

### TYPE3  
DAT3 of FlashAir for LED backlight on/off control.  

FlashAir(Pin#) | ILI9341 TFT | Power | comment
--- | --- | --- | ---
CLK (5) |--- |Pull-down(10korm) to GND
CMD (2) |SDI |
DAT0(7) |CLK |
DAT1(8) |DC  |
DAT2(9) |CS  |
DAT3(1) |LED ||connect through 10kohm
---     |RESET|Pull-up(10korm) to 3.3V
VCC (4) |VCC |3.3V
VSS(3,6)|GND |GND 

### TYPE4  
CMD,DAT0,DAT2,DAT3 can be used for SPI.

FlashAir(Pin#) | ILI9341 TFT | SPI device | Power | comment
--- | --- | --- | --- | ---
CLK (5) |--- |---| Pull-down(10korm) to GND
CMD (2) |SDI |DO |
DAT0(7) |CLK |CLK|
DAT1(8) |DC  |---|
DAT2(9) |CS  |DI | Pull-up(10korm) to 3.3V
DAT3(1) |--- |CS |
---     |RESET|---| Pull-up(10korm) to 3.3V
---     |LED |---| 3.3V
VCC (4) |VCC |VCC| 3.3V
VSS(3,6)|GND |GND| GND

### TYPE21
If you connect two displays, use this for primaly display.

FlashAir(Pin#) | ILI9341 TFT | Power | comment
--- | --- | --- | ---
CLK (5) |--- | Pull-down(10korm) to GND
CMD (2) |SDI |
DAT0(7) |CLK |
DAT1(8) |DC  |
DAT2(9) |CS  | Pull-up(10korm) to 3.3V
DAT3(1) |(CS2 )|
---     |RESET| Pull-up(10korm) to 3.3V
---     |LED | 3.3V
VCC (4) |VCC | 3.3V
VSS(3,6)|GND | GND

### TYPE22  
If you connect two displays, use this for secondaly display.

FlashAir(Pin#) | ILI9341 TFT | Power | comment
--- | --- | --- | ---
CLK (5) |--- | Pull-down(10korm) to GND
CMD (2) |SDI |
DAT0(7) |CLK |
DAT1(8) |DC  |
DAT2(9) |(CS )| Pull-up(10korm) to 3.3V
DAT3(1) |CS2 |
---     |RESET| Pull-up(10korm) to 3.3V
---     |LED | 3.3V
VCC (4) |VCC | 3.3V
VSS(3,6)|GND | GND

### TYPE23  
If you connect two identical displays, use this for twin display.
You can draw each or both.

FlashAir(Pin#) | ILI9341 TFT1 | ILI9341 TFT2 | Power | comment
--- | --- | --- | --- | ---
CLK (5) |--- |--- | Pull-down(10korm) to GND
CMD (2) |SDI |SDI |
DAT0(7) |CLK |CLK |
DAT1(8) |DC  |DC  |
DAT2(9) |CS  |--- | Pull-up(10korm) to 3.3V
DAT3(1) |--- |CS2 |
---     |RESET|RESET| Pull-up(10korm) to 3.3V
---     |LED |LED | 3.3V
VCC (4) |VCC |VCC | 3.3V
VSS(3,6)|GND |GND | GND

## Install

SlibILI9341.lua -- Copy to somewhere in Lua's search path.

## Color format of functions

color   : BBBBB_GGGGGG_RRRRR (64K(16bpp) color)  
bgcolor : BBBBB_GGGGGG_RRRRR (64K(16bpp) back ground color)

## Internal bitmap data format

    -- same as FlashAir-SlibBMP.lua
    bitmap  = {}  
    bitmap.header -- copyed from BMP header  
    bitmap.width  -- bitmap width  
    bitmap.height -- bitmap height  
    bitmap.bit    -- bpp, 16(BBBBB_GGGGGG_RRRRR format)
    bitmap.flat   -- 1:Flat(Stuffing without leaving spaces for small image), 0:Stored in an array for each line.  
    bitmap.data   -- bitmap data  

## Internal font data format

    -- example --
    font74 = {
    height= 7;
    width = 4;
    [' '] ={0x00,0x00,0x00,0x00};
    ['!'] ={0x00,0x2F,0x00,0x00};
    ['"'] ={0x03,0x00,0x03,0x00};
    --
    ['~'] ={0x0C,0x04,0x06,0x00};
    }


## Usage
### Sample of init()

 1.44inch with ILI9341 V1.1 |
--- |
<img src="img/ILI9341rotation01.jpg" width="800"> |

1.44inch with ILI9341 V2.1 |
--- |
<img src="img/ILI9341rotation02.jpg" width="800"> |

### Description of the command

command | description
--- | ---
ILI9341:init(type,rotate,xSize,ySize,rOffset,dOffset,gm) | Parameter initialization and reset LCD module.<br>**type:** 1:D3=RST,  2:D3=PIO, 3:D3=LED, 4:with SPI, 21:primaly, 22:secondaly, 23:twin <br> See module connections information.<br>**rotate:** 0:Vertical default, 1:Horizontal default, 2:Vertical reverse, 3:Horizontal reverse<br>**xSize,ySize:** LCD x size, y size<br>**rOffset,dOffset:** RAM address offset<br>**gm:** module GM pad
ILI9341:flip(rFlip,dFlip) | Filp x-axis or y-axis for graphic writing.<br>**rFlip,dFlip:** 0:normal, 1:flip
tbl=ILI9341:duplicate() | Duplicate ILI9341 library, if you use two deferent TFT module of ILI9341 or rotation.<br>**return:** duplicated table of library.
ILI9341:writeStart([flag]) | Enable control.<br>**flag:** 1:primaly, 2:secondly, 3:both<br>default is 2 at TYPE22, 3 at TYPE23, 1 at others.
ILI9341:writeEnd()   | Disable control.
ILI9341:cls()        | Clear screen.
ILI9341:dspOn()      | Display contents of RAM.
ILI9341:dspOff()     | Do not display contents of RAM.
ILI9341:pset(x,y,color) | Plot point at (x,y).
ILI9341:line(x1,y1,x2,y2,color) | Plot line (x1,y1)-(x2,y2).
ILI9341:box(x1,y1,x2,y2,color) | Plot box (x1,y1)-(x2,y2).
ILI9341:boxFill(x1,y1,x2,y2,color) | Plot filled box (x1,y1)-(x2,y2).
ILI9341:circle(x,y,xr,yr,color) | Plot circle of center(x,y), radius(xr,yr).
ILI9341:circleFill(x,y,xr,yr,color) | Plot filled circle of center(x,y), radius(xr,yr).
ILI9341:put(x,y,bitmap) | Put 16bpp bitmap at upper left coordinates with (x,y).
ILI9341:put2(x,y,bitmap)| Put 16bpp flat bitmap faster at upper left coordinates with (x,y).
ILI9341:locate(x,y,mag,color,bgcolor,font) | Locate cursor, set print area(x,y)-(xSize-1,ySize-1), attributions and font.<br>If you do not want to change any arguments you can substitute nil.
x,y=ILI9341:print(str) | Print alphabets and return next cursor position.
x,y=ILI9341:println(str) | Print alphabets, creates a new line and return next cursor position.
ILI9341:ledOn() | LED backlight ON at TYPE2.
ILI9341:ledOff() | LED backlight OFF at TYPE2.
ret=ILI9341:pio(ctrl,data) | PIO control of DAT3 at TYPE3.<br>PIO default is input.<br>**ctrl:** 0:input, 1:output. data: value for output<br>**return:** input value or nil at TYPE1
ILI9341:spiInit(period,mode,bit,cstype)|SPI init for TYPE4.<br>**period,mode,bit:** same as fa.spi(...)<br>**cstype:** 0:low enable, 1:high enable, 2:always High-Z
res = ILI9341:spiWrite(data_num)<br>res = ILI9341:spiWrite(data_str,xfer_num)|SPI write for TYPE4.<br>**data_num,data_str,xfer_num,res:** same as fa.spi("write", ...)
res_num = ILI9341:spiRead()<br>res_tbl = ILI9341:spiRead(xfer_num,data_num)|SPI read for TYPE4.<br>**xfer_num,data_num,res_num,res_tbl:** same as fa.spi("read", ...)


## Sample program

<img src="img/ILI9341sample01.jpg" width="250"> <img src="img/ILI9341sample02.jpg" width="250">

>sample.lua       `-- draw graphics demo`  
>lib/SlibILI9341.lua  
>lib/SlibBMP.lua  `-- Copy from FlashAir-SlibBMP repository`  
>img/balloon01.bmp  
>img/balloon02.bmp  
>font/font74.lua  

These files copy to somewhere in FlashAir.


## Licence

[MIT](https://github.com/AoiSaya/FlashAir-libBMP/blob/master/LICENSE)

## Author

[GitHub/AoiSaya](https://github.com/AoiSaya)  
[Twitter ID @La_zlo](https://twitter.com/La_zlo)
