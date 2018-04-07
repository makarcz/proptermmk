{{

  Homebrew Serial Keyboard + VGA Terminal (80x40) and SD card.
  Marek Karcz (C) 2016, 2017. All rights reserved.
  Free for personal and educational use.  

  Serial keyboard consists of matrix retro keyboard (TI 99/4A)
  and AT89S52 controller + open collector clock and data output,
  pretty much like a PS/2 keyboard, but the protocol is different.
  See documentation in serkb_recv object.

  This configuration uses P8X32A QuickStart Board + Human Interface Board
  from Parallax INC.

  Terminal will also work with PC keyboard and Keyboard object.
  
}}
CON
  _clkmode = xtal1 + pll16x 'Use low crystal gain, wind up 16x
  _xinfreq = 5_000_000 'External 5 MHz crystal on XI & XO
  ''_CLKFREQ = 80_000_000

  SDA_pin = 26  'keyboard port on human interface board
  SCL_pin = 27

  'SDA_pin = 24  'keyboard port on human interface board
  'SCL_pin = 25  

  SerialTx_pin = 5
  SerialRx_pin = 7

  SerialBaud = 9600
  SerialMode = %0011

  MAX_col = scr#cols - 1
  MAX_row = scr#rows - 1

  chrs = scr#cols * scr#rows 

  'MAX_col = 31
  'MAX_row = 14

  CRSBLDEL = 3000

  BKSPC = 8
  BKSPC_PC = $C8
  CTRL_H_PC = $268
  NUMLOCK_PC = $DF
  NL = $0D
  CR = $0A
  CTRL_C = 3             ' CTRL-C from TI99/4A keyboard driver
  CTRL_C_PC = $263       ' CTRL-C from PS/2 keyboard driver
  CTRL_Z = 26
  CTRL_Z_PC = $27A
  SPC = $20
  ESC_PC = $CB
  ESC = $1B
  F1_PC = $D0
  CTRL_Q_PC = $271
  CTRL_Q = $11

  ' Micro SD connections
  
  CS  = 3       ' Propeller Pin 3 - Set up these pins to match the Parallax Micro SD Card adapter connections.
  DI  = 2       ' Propeller Pin 2 - For additional information, download and refer to the Parallax PDF file for the Micro SD Adapter.                        
  CLK = 1       ' Propeller Pin 1 - The pins shown here are the correct pin numbers for my Micro SD Card adapter from Parallax                               
  D0  = 0       ' Propeller Pin 0 - In addition to these pins, make the power connections as shown in the following comment block.  

OBJ
  sdfat   : "fsrw"                     '  r/w file system
  scr     : "vga_hires_text_mk"
  'serkb   : "serkb_recv"             '  serkb_recv object is interchangeable
  serkb   : "keyboard"               ' with keyboard object - no more code
                                     '  changes are required, just swap them here
  rs232   : "FullDuplexSerial_mk"
  'rs232   : "rs232_driver_mk"
  'serial  : "Parallax Serial Terminal"
  'Num    : "numbers"

  streng  : "ASCII0_STREngine_1"       ' string library

DAT
  str01     BYTE "Serial Keyboard + VGA Terminal (80x40).",NL,0
  strFmVer  BYTE "Firmware version 2.2.",NL,0
  strCpr01  BYTE "Copyright (C) by Marek Karcz 2016,2017.",NL,0
  strCpr02  BYTE "All rights reserved.",NL,0
  str01_1   BYTE NL,"Press (at any time):",NL,NL,0
  str02     BYTE "   CTRL-C to Clear Screen,",NL,0
  str03     BYTE "   CTRL-H to Backspace/Delete,",NL,0
  str04     BYTE "   CTRL-Z to open Terminal Menu,",NL,0
  str05     BYTE "   CTRL-Q (F1) to see this help.",NL,0
  strSdFnd  BYTE NL,"SD card found. Open Terminal Menu to mount.",NL,0
  strNoSd   BYTE NL,"ERROR: There is no SD card.",NL,0
  strSpaces BYTE "                                ",0
  strRdCmd  BYTE "r ",0
  strSelec  BYTE "Your selection ? ",0
  strInvSel BYTE "Invalid selection.",NL,0
  strQuit   BYTE "Quit.",NL,0
  strTermMn BYTE "Terminal Menu:",NL,0
  strMenu01 BYTE "   1 - Send file from SD card to serial port.",NL,0
  strMenu02 BYTE "   2 - Save memory write commands to file on SD card.",NL,0
  strMenu03 BYTE "   3 - Save output from command to file on SD card.",NL,0    
  strMenu04 BYTE "   4 - Directory of SD card.",NL,0
  strMenu05 BYTE "   5 - List file contents.",NL,0
  strMenu08 BYTE "   8 - Delete file on SD card.",NL,0    
  strMenuQ  BYTE "   Q - Exit Menu",NL,0    
  strStAddr BYTE "Enter start address (hex DDDD, e.g: 0400):",NL,0
  strEndAdr BYTE "Enter end address (hex DDDD, e.g: 1000):",NL,0
  strAdrRng BYTE "Address range must be greater than 14 bytes.",NL,0
  strCommnd BYTE "Command: ",0
  strBufEq  BYTE "buf=",0
  
VAR  
  long  col, row
  long  rcv, key, prevkey
  'long  crsct
  'sync long - written to -1 by VGA driver after each screen refresh
  long  sync
  'screen buffer - could be bytes, but longs allow more efficient scrolling
  long  screen[chrs/4]
  'row colors
  word  colors[MAX_row+1]
  'cursor control bytes
  byte  cx0, cy0, cm0, cx1, cy1, cm1
  byte  fname[13]
  byte  staddr[5], endaddr[5]
  byte  buf[256], cmdbuf[40]
  long  sdcard_found
  
PUB Main | i

  sdcard_found := -1
  prevkey := 0
  'crsct := CRSBLDEL
  col := 0
  row := 0
  'Num.init
  'serial.Start(115200)
  rs232.Start(SerialRx_pin, SerialTx_pin, SerialMode, SerialBaud)
  serkb.Start(SDA_pin, SCL_pin)  ' Start the serial keyboard object
  scr.start(16, @screen, @colors, @cx0, @sync)
  'set up colors, clear screen
  repeat i from 0 to MAX_row
    'colors[i] := %%0100_1310
    colors[i] := %%3330_0000
  repeat i from 0 to chrs - 1
    screen.byte[i] := $20      
  ScrStr(@str01)
  ScrStr(@strFmVer)
  ScrStr(@strCpr01)
  ScrStr(@strCpr02)
  HelpInfo
  waitcnt(cnt + clkfreq)
  MountSD(FALSE)
  if sdcard_found => 0
    ScrStr(@strSdFnd)
    UnmountSD(FALSE) 
  rs232.RxFlush
  repeat
    key := serkb.Key
    ' conversions related to used keyboard driver (ti99/4a a.k.a. serkb_recv or ps/2 a.k.a. keyboard)
    if key > 0
      if key == CR
        key := NL
      if key == CTRL_C_PC
        key := CTRL_C
      if key == CTRL_Z_PC
        key := CTRL_Z
      if key == BKSPC_PC or key == CTRL_H_PC
        key := BKSPC
      if key == NUMLOCK_PC
        key := 0
      if key == ESC_PC
        key := ESC
      if key == CTRL_Q_PC or key == F1_PC
        key := CTRL_Q
    if key > 0 and key <> CTRL_Z
      rs232.Tx(key & $ff)
    rcv := rs232.RxTime(20)
    if key == CTRL_Z
       rcv := CTRL_Z
    if rcv => 0
      PrnChar(rcv & $ff)
      prevkey := rcv & $ff
    Cursor

PUB UnmountSD(verbose)
  if verbose == TRUE   
    PrnChar(NL)                 
  if sdcard_found => 0
    sdfat.unmount
    sdcard_found := -1
    if verbose == TRUE
      ScrStr(String("SD card has been unmounted successfully.",NL))
  else
    if verbose == TRUE
      ScrStr(String("ERROR: Nothing to unmount. (already unmounted?)",NL))

PUB MountSD(verbose)
  if verbose == TRUE
    PrnChar(NL)
  if sdcard_found < 0
    sdcard_found := \sdfat.mount_explicit(D0, CLK, DI, CS) ' Here we call the 'mount' method using the 4 pins described in the 'CON' section.
    if verbose == TRUE
      if sdcard_found => 0
        ScrStr(String("SD card has been mounted successfully.",NL))
      else
        ScrStr(String("ERROR: Unable to mount SD card, error code="))
        ScrStr(streng.integerToHexadecimal(sdcard_found, 8))
        PrnChar(NL)
  else
    if verbose == TRUE
      ScrStr(String("ERROR: Nothing to mount. (already mounted?)",NL))         

PUB HelpInfo
  StrOut(@str01_1)
  StrOut(@str02)
  StrOut(@str03)
  StrOut(@str04)
  StrOut(@str05)
  Cursor     

PUB ScrStr(strptr)
  repeat StrSize(strptr)
    PrnChar(byte[strptr++])

PUB ScrOut(c)
  screen.byte[row*(MAX_col+1) + col] := c

PUB StrOut(strptr)
  repeat StrSize(strptr)
    if byte[strptr] == NL
      col := 0
      IncRow
      strptr++
    else
      ScrOut(byte[strptr++])
      IncCol

PUB Cursor
  cx0 := col
  cy0 := row
  cm0 := %010
  ' uncomment code below to enable own cursor implementation
  ' and comment code above
  {{
  crsct--
  if crsct > CRSBLDEL / 2
    ScrOut("|")
  else
    ScrOut("_")
  if crsct == 0
    crsct := CRSBLDEL
  }}

PUB IncRow
  row := row + 1
  if row > MAX_row
    row := MAX_row
    ByteMove(@screen, @screen+MAX_col+1, chrs-MAX_col-1)
    ByteFill(@screen+chrs-MAX_col-1, 32, MAX_col+1)

PUB IncCol
  col := col + 1
  if col > MAX_col
    col := 0
    IncRow

PUB DecCol
  if col > 0
    col := col - 1

PUB ReadSerialAndPrint(rdw)
  repeat
    'rcv := rs232.RxCheck
    rcv := rs232.RxTime(rdw)
    if rcv < 0
      Quit
    PrnChar(rcv & $ff)

PUB SDDir | n, lc
  if sdcard_found < 0
    ScrStr(@strNoSd)
    return
  PrnChar(NL)
  PrnChar(NL)
  ScrStr(String("Directory:",NL))
  PrnChar(NL)
  sdfat.opendir
  lc := 20
  repeat
    n := sdfat.nextfile(@fname)
    if n < 0
      Quit
    ScrStr(@fname)
    lc--
    if lc == 0
      lc := 20
      PrnChar(NL)
      ScrStr(String("[More...]",NL))
      GetStr(@cmdbuf,1)
    PrnChar(NL)

PUB GetStr(pstr, size) | n, q
  n := 0
  q := FALSE
  repeat until q == TRUE
    key := serkb.Key
    if key > 0
      if key == CR
        key := NL
      if key == CTRL_C_PC
        key := CTRL_C
      if key == CTRL_Z_PC
        key := CTRL_Z
      if key == BKSPC_PC
        key := BKSPC
      if key == NUMLOCK_PC
        key := 0                    
      case key
        NL:    byte[pstr+n] := 0
               q := TRUE
        BKSPC: if n > 0
                 n := n - 1
                 byte[pstr+n] := 0
        OTHER: if key > 0 and n < size-1
                 byte[pstr+n] := key
                 n := n + 1
                 byte[pstr+n] := 0
      col := 0
      ScrStr(@strSpaces)
      ScrOut(SPC)
      col := 0
      ScrStr(pstr)
    Cursor    

PUB EnterFileName '| n, q
  PrnChar(NL)
  ScrStr(String("Enter file name:",NL))
  PrnChar(NL)
  Cursor
  GetStr(@fname, 13)

PUB SendFileFromSD2Serial | n, q, s, t, b, m
  b := FALSE ' b = mode, TRUE - binary / FALSE - ASCII
  m := TRUE  ' m = TRUE - monitor commands / FALSE - Text
  if sdcard_found < 0
    ScrStr(@strNoSd)
    return
  'SDDir
  EnterFileName
  PrnChar(NL)
  ScrStr(String("Monitor(1) / Binary(2) / Text(3) ?"))
  repeat
    key := serkb.Key
    if key > 0
      case key
        "1" :  b := FALSE
        "2" :  b := TRUE
        "3" :  m := FALSE
        OTHER: PrnChar(NL)
               ScrStr(String("Unknown menu option.",NL))
               b := FALSE
      PrnChar(NL)
      Quit  
  ReadSerialAndPrint(0)
  ScrStr(String("Fast(1) / Slow(2) ?"))
  repeat
    key := serkb.Key
    if key > 0
      case key
        "1" :  s := 6
               t := 250
        "2" :  s := 3
               t := 125
        OTHER: PrnChar(NL)
               ScrStr(String("Unknown menu option.",NL))
               s := 3
               t := 125
      PrnChar(NL)
      Quit  
  ReadSerialAndPrint(0)
  ScrStr(String("*** Loading file ***", NL))
  waitcnt(cnt + clkfreq)
  sdfat.popen(@fname, "r")
  if b == FALSE
    if m == TRUE
      key := NL
      rs232.Tx(key & $ff)
      ReadSerialAndPrint(0)
  key := 0
  repeat
    key := sdfat.pgetc
    if key < 0
      Quit
    if b == FALSE
      if key == NL
        key := 0
      if key == CR
        key := NL
      if key > 0      
        rs232.Tx(key & $ff)
        waitcnt(cnt + clkfreq/t)
      if key == NL
        waitcnt(cnt + clkfreq/s)
    else
      rs232.Tx(key & $ff)
      waitcnt(cnt + clkfreq/t)
    ReadSerialAndPrint(0)
  waitcnt(cnt + clkfreq*2)
  ReadSerialAndPrint(0)
  if m == TRUE
    PrnChar(NL)
  sdfat.pclose

PUB SaveMemory2FileSD | m, adrbeg, adrend
  if sdcard_found < 0
    ScrStr(@strNoSd)
    return
  EnterFileName
  PrnChar(NL)
  ScrStr(@strStAddr)
  PrnChar(NL)
  Cursor
  GetStr(@staddr, 5)
  adrbeg := streng.hexadecimalToInteger(@staddr)
  PrnChar(NL)
  PrnChar(NL)
  ScrStr(@strEndAdr)
  PrnChar(NL)
  Cursor
  GetStr(@endaddr, 5)
  adrend := streng.hexadecimalToInteger(@endaddr)
  PrnChar(NL)
  Cursor
  if adrend - adrbeg < 15
    ScrStr(@strAdrRng)
    return
  sdfat.popen(@fname, "w")
  cmdbuf[0] := 0
  streng.stringCopy(@cmdbuf, @strRdCmd)
  streng.stringConcatenate(@cmdbuf, @staddr)
  streng.stringConcatenate(@cmdbuf, String("-"))
  streng.stringConcatenate(@cmdbuf, @endaddr)
  streng.stringConcatenate(@cmdbuf, String(NL))
  ' Send the memory read command
  ScrStr(@strCommnd)
  ScrStr(@cmdbuf)    
  rs232.str(@cmdbuf)
  'skip until first NL (ignore echo-ed command)
  rcv := 0
  repeat until rcv == NL
    rcv := rs232.RxTime(20)  
  ' Read response from memory read command and save it to file
  ' line by line
  m := 0
  buf[m] := 0
  repeat
      rcv := rs232.RxTime(2000)
      if rcv < 0
        Quit
      if rcv <> NL
        if m < 255
          buf[m++] := rcv & $ff
          buf[m] := 0
      else
        if m < 255
          buf[m++] := NL
          buf[m] := 0
        if m < 255
          buf[m++] := CR
          buf[m] := 0
        'if buf[0] == "w"
        sdfat.pputs(@buf)
        ScrStr(@strBufEq)
        ScrStr(@buf)
        m := 0
        buf[m] := 0            

  sdfat.pclose
  PrnChar(NL)
  ScrStr(String("File saved.",NL))

PUB SaveOutput2FileSD | m
  if sdcard_found < 0
    ScrStr(@strNoSd)
    return
  PrnChar(NL)    
  EnterFileName
  PrnChar(NL)
  PrnChar(NL)  
  ScrStr(String("Enter command: ",NL))
  PrnChar(NL)  
  Cursor
  sdfat.popen(@fname, "w")  
  GetStr(@cmdbuf, 40)
  streng.stringConcatenate(@cmdbuf, String(NL))
  PrnChar(NL)
  Cursor  
  rs232.str(@cmdbuf)
  'skip until first NL (ignore echo-ed command)
  rcv := 0
  repeat until rcv == NL
    rcv := rs232.RxTime(20)
  'read the input stream and save it in file
  m := 0
  buf[m] := 0
  repeat
    rcv := rs232.RxTime(2000)
    if rcv < 0
      Quit
    if rcv == CR
      Next
    if rcv <> NL
      if m < 255
        buf[m++] := rcv & $ff
        buf[m] := 0
    else
      if m < 255
        buf[m++] := NL
        buf[m] := 0
      if m < 255
        buf[m++] := CR
        buf[m] := 0
      sdfat.pputs(@buf)
      ScrStr(@strBufEq)
      ScrStr(@buf)      
      m := 0
      buf[m] := 0
  sdfat.pclose
  PrnChar(NL)
  ScrStr(String("File saved.",NL))      

PUB ListFileSD | lc
  if sdcard_found < 0
    ScrStr(@strNoSd)
    return
  EnterFileName
  PrnChar(NL)
  sdfat.popen(@fname, "r")
  lc := 20
  repeat
    rcv := sdfat.pgetc
    if rcv < 0
      Quit
    PrnChar(rcv & $ff)
    if rcv == NL
      lc--
      if lc == 0
        lc := 20
        ScrStr(String("[More...]",NL))
        GetStr(@cmdbuf,1)        
  sdfat.pclose

PUB DeleteFileSD
  if sdcard_found < 0
    ScrStr(@strNoSd)
    return
  SDDir
  EnterFileName
  PrnChar(NL)
  ScrStr(String("Are you sure? (Y/N)",NL))
  repeat
    key := serkb.Key
    if key > 0
      if key == "y" or key == "Y"
        sdfat.popen(@fname, "d")
        sdfat.pclose
        ScrStr(String("File deleted.",NL))
        Quit
      else
        if key == "n" or key == "N"
          ScrStr(String("Delete aborted.",NL))
          Quit
        else
          ScrStr(String("Pardon? Delete file? (Y/N)",NL))       
                                  
PUB TermMenu | q
  q := FALSE
  MountSD(TRUE)  ' SD card us mounted only while in Terminal Menu
  repeat until q == TRUE
    ScrStr(@strTermMn)
    PrnChar(NL)  
    ScrStr(@strMenu01)
    ScrStr(@strMenu02)
    ScrStr(@strMenu03)    
    ScrStr(@strMenu04)
    ScrStr(@strMenu05)
    'ScrStr(String("   6 - Unmount SD card.",NL))
    'ScrStr(String("   7 - Mount SD card.",NL))
    ScrStr(@strMenu08)    
    ScrStr(@strMenuQ)
    PrnChar(NL)
    ScrStr(@strSelec)
    repeat
      key := serkb.Key
      if key > 0
        case key
          "1" :  SendFileFromSD2Serial
                 q := TRUE
          "2" :  SaveMemory2FileSD
                 q := TRUE
          "3" :  SaveOutput2FileSD
                 q := TRUE
          "4" :  SDDir
          "5" :  ListFileSD
          '"6" :  UnmountSD(TRUE)
          '"7" :  MountSD(TRUE)
          "8" :  DeleteFileSD
          "q" :  ScrStr(@strQuit)
                 q := TRUE
          OTHER: ScrStr(@strInvSel)
        PrnChar(NL)
        Quit
      Cursor
  ScrOut(SPC)
  UnmountSD(TRUE)  ' SD card is only mounted while in Terminal Menu

PUB ClrScr
  ByteFill(@screen, SPC, chrs) 
  col := 0
  row := 0

PUB IsDigit(c)
  if c => "0" and c =< "9"
    return TRUE

  return FALSE

' Read digits from rs232, convert to number and return value.
' The last read non-digit character code is remembered in key variable.
'  
PUB RdNumSer(chars) : numval | c, ba
  numval := -1
  ba := chars
  byte[chars] := 0
  c := rs232.RxTime(20)
  if IsDigit(c) == TRUE
    repeat while IsDigit(c) == TRUE
      byte[chars++] := c
      byte[chars] := 0
      c := rs232.RxTime(20)
  key := c
  numval := streng.decimalToInteger(ba)                             

PUB PrnChar(c) | n, lcol, lrow
  if c == "[" and prevkey == ESC
    lrow := RdNumSer(@buf)
    if lrow => 0
      case key
      
        "J"      : case lrow
                     0 :  ' write code here to clear from cursor to end of screen
                          return
                     1 :  ' write code here to clear from cursor to begin of screen
                          return
                     2 :
                          'StrOut(String("[CLS]"))
                          ClrScr
                          return
                          
                     OTHER : return
                     
        ";"      : 'StrOut(String("[;]"))
                   lcol := RdNumSer(@buf)
                   if lcol => 0
                     if key == "H" or key == "f"
                       col := lcol - 1
                       row := lrow - 1
                       if col < 0
                         col := 0
                       if row < 0
                         row := 0
                   return
                          
        OTHER    : return
  if c == CR
    'ScrOut(SPC) 'uncomment only if own cursor impl. is used
    col := 0
  if c == NL ' NOTE: NL here actually emulates CR,NL
    'ScrOut(SPC) 'uncomment only if own cursor impl. is used
    col := 0
    IncRow
  if c == CTRL_C 'CTRL-C, Clear Screen
    rs232.Tx(BKSPC) 'Send backspace to delete control character
    ClrScr
    rs232.Tx(NL) 'Send NL to serial
  if c == CTRL_Q
    HelpInfo
    rs232.Tx(NL) 'Send NL to serial    
  if c == BKSPC
    ScrOut(SPC)
    DecCol
  if c == CTRL_Z 'CTRL-Z, Menu
    'rs232.Tx(BKSPC) 'Send backspace to delete control character
    'ScrOut(SPC)
    col := 0
    IncRow
    IncRow
    TermMenu
    IncRow
    rs232.Tx(NL) 'Send NL to serial    
  if c > 31 and c < 127
    ScrOut(c)
    IncCol
    {{
  if c == ESC
    StrOut(String("[ESC]"))
    }}
  Cursor
   