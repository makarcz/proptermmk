{{

  Homebrew Serial Keyboard + TV Terminal.
  Marek Karcz (C) 2016. All rights reserved.
  Free for personal and educational use.  

  Serial keyboard consists of matrix retro keyboard (TI 99/4A)
  and AT89S52 controller + open collector clock and data output,
  pretty much like a PS/2 keyboard, but the protocol is different.
  See documentation in serkb_recv object.

  This configuration uses P8X32A QuickStart Board + Human Interface Board
  from Parallax INC. Note that the A/V output from Human Interface Board
  uses TRRS type cable and it seems that not all cables work and those
  that work often have video output (yellow cable) swapped with one of the
  audio outputs (red cable).
  
}}
CON
  _clkmode = xtal1 + pll16x 'Use low crystal gain, wind up 16x
  _xinfreq = 5_000_000 'External 5 MHz crystal on XI & XO
  ''_CLKFREQ = 80_000_000

  SDA_pin = 26  'keyboard port on human interface board
  SCL_pin = 27

  SerialTx_pin = 5
  SerialRx_pin = 7

  SerialBaud = 9600
  SerialMode = %0011

  MAX_col = 39
  MAX_row = 12

  'MAX_col = 31
  'MAX_row = 14

  CRSBLDEL = 2000  

OBJ
  scr     : "TV_Text"
  'scr     : "vga_text_mk"
  serkb   : "serkb_recv"
  rs232   : "FullDuplexSerial_mk"
  'serial  : "Parallax Serial Terminal"
  'Num    : "numbers"   

DAT
  str01     BYTE "Serial Keyboard + TV Terminal.",$0D,0
  str02     BYTE "CTRL-C to Clear Screen",$0D,0
  str03     BYTE "CTRL-H to Backspace",$0D,0
  'strSpaces BYTE "              ",0

VAR  
  long  col, row
  long  rcv, key
  long  crsct
  
PUB Main

  crsct := CRSBLDEL
  col := 0
  row := 0
  dira[18] := 0  'serkb_recv blinks this LED, we read it to control cursor blinking
  'Num.init
  'serial.Start(115200)
  rs232.Start(SerialRx_pin, SerialTx_pin, SerialMode, SerialBaud)
  serkb.Start(SCL_pin, SDA_pin)  ' Start the serial keyboard object
  scr.start(13)
  'scr.start(16)
  ScrStr(@str01)
  ScrStr(@str02)
  ScrStr(@str03)
  col := 3
  waitcnt(cnt + clkfreq)
  Cursor
  rs232.RxFlush
  repeat
    key := serkb.GetKey
    'PrnChar(rcv)
    if key > 0
      if key == $0A
        key := $0D
      rs232.Tx(key & $ff)
      'PrnChar(key & $ff)
    rcv := rs232.RxCheck
    if rcv => 0
      'serial.Str(STRING("Received character from RS232:"))
      'serial.Dec(rcv)
      'serial.NewLine
      PrnChar(rcv & $ff)
    Cursor

PUB ScrStr(strptr)
  scr.str(strptr)

PUB ScrOut(c)
  scr.out(c)      

PUB Cursor
  crsct--
  if col < MAX_col
    if crsct > CRSBLDEL / 2
      ScrOut("|")
    else
      ScrOut("_")
    ScrOut(8)
  if crsct == 0
    crsct := CRSBLDEL

PUB IncRow
  row := row + 1
  if row > MAX_row
    row := MAX_row

PUB IncCol
  col := col + 1
  if col > MAX_col
    col := 0
    IncRow

PUB DecCol
  if col > 0
    col := col - 1          

PUB PrnChar(c)
  if c == 10 or c == 13
    ScrOut(" ")
    ScrOut($0D)
    col := 0
    IncRow
  if c == 3 'CTRL-C, Clear Screen
    ScrOut(0)
    col := 0
    row := 0
  if c == 8
    if col < MAX_col
      ScrOut(" ")
      ScrOut(8)
    ScrOut(8)
    DecCol
  if c > 31 and c < 127
    ScrOut(c)
    IncCol
  Cursor
   