{{

  Serial Keyboar Receiver
  Marek Karcz (C) 2016. All rights reserved.
  Free for personal and educational use.

  Serial keyboard consists of matrix retro keyboard (TI 99/4A)
  and AT89S52 controller + open collector clock and data output,
  pretty much like a PS/2 keyboard, but the protocol is different.

  However the electrical voltage levels are the same as in PS/2.
  Therefore the PS/2 interface inputs used in Propeller based
  boards can be used, Data for SCL pin and Clock for SCL pin.

  This object starts 2 processes in 2 cogs.
  1-st one is listening for incoming from keyboard characters
  on pins SDA_pin and SCL_pin and storing them in the buffer,
  which then can be retrieved by client object with PUB method.

  The 2-nd process monitors SDA and SCL pins and displays their
  states on 2 LED-s. It also blinks one of the LED-s to show
  that it is running.
    
}}
CON
  _clkmode = xtal1 + pll16x 'Use low crystal gain, wind up 16x
  _xinfreq = 5_000_000 'External 5 MHz crystal on XI & XO
  dbg = 0

OBJ
  pst : "Parallax Serial Terminal" ' Serial communication object
  Num : "numbers"

VAR
  byte  SCL_pin
  byte  SDA_pin
  byte  cog, cog2
  byte  data[16]
  byte  buf_start
  byte  buf_end
  long  counter
  long  Stack[128]
  'long  Stack2[20]
  byte  StrBuf[40]

PRI SerLog(s)
  if dbg == 1
    pst.Str(Num.ToStr(counter,NUM#DEC))
    pst.Str(String(" : "))
    pst.Str(s)
    pst.Str(String(pst#NL))
    counter := counter + 1
    
PUB Start(data_pin, clk_pin) | good

  counter := 0
  Num.init
  if dbg == 1
    pst.Start(115200) ' Start Parallax Serial Terminal cog
  Stop
  SCL_pin := clk_pin
  SDA_pin := data_pin
  
  good := cog := cognew(kbrcv, @Stack) + 1

  SerLog ( String("serkb_recv started") )

  'cog2 := cognew(Leds(SCL_pin,SDA_pin), @Stack2) + 1

  return (good) ' and cog2)

PUB Stop
  if cog
    cogstop(cog~ - 1)
    SerLog( String("serkb_recv stopped") )
  if cog2
    cogstop(cog2~ - 1)

PUB Key | kc
  kc := -1
  if buf_start <> buf_end
    kc := data[buf_start]
    data[buf_start] := 0
    buf_start := buf_start + 1
    if buf_start => 16
      buf_start := 0

  return (kc)
  
PRI init
  buf_start := buf_end := 0
  data[0] := 0
  dira[SCL_pin] := 0     ' set to input
  dira[SDA_pin] := 0

PRI detect_start
  'SDA .../||||\____...
  'SCL .../||||\____...
  'wait for SDA and SCL to go HIGH
  repeat until ina[SCL_pin] == 1 and ina[SDA_pin] == 1
  'wait for SDA and SCL to go LOW  
  repeat until ina[SCL_pin] == 0 and ina[SDA_pin] == 0
 
  SerLog( String("start detected") )

PRI get_byte | b, l

  b := 0
  repeat 8
    'detect clock pulse SCL .../||||\____...
    repeat while ina[SCL_pin] == 0
    repeat while ina[SCL_pin] == 1
    b := (b << 1) | ina[SDA_pin]      ' read the bit    

  if dbg == 1
    bytefill(@StrBuf, 0, 40)
    l := strsize(Num.ToStr(b & $ff, NUM#DEC))
    bytemove(@StrBuf, String("Got Byte ["), 10)   
    bytemove(@StrBuf+10, Num.ToStr(b & $ff, NUM#DEC), l)
    bytemove(@StrBuf+10+l, String("]"), 1)
    SerLog ( @StrBuf ) 
                             
  return (b & $FF)  

PRI kbrcv
  init
  repeat
    detect_start
    data[buf_end] := get_byte
    buf_end := buf_end + 1
    if buf_end => 16
      buf_end := 0
    data[buf_end] := 0

{
PRI Leds(scl,sda) | ct
  ' LED-s
  dira[16] := 1
  dira[17] := 1
  dira[18] := 1
  ct := 0
  repeat
    outa[16] := !ina[scl]
    outa[17] := !ina[sda]
    if ct > 10000
      ct := 0
      !outa[18]
    ct := ct + 1    
} 