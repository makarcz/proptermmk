PropTermMK
Author: Marek Karcz
Copyright (c) 2017, 2018 Marek Karcz
=======================================
This project contains HW blueprints and firmware source code for a Parallax
Propeller based device which functions as a character terminal (ANSI) and
mass storage device for a specific homebrew computer project MKHBC-8-Rx.
It can be adapted to serve in any other project which requires character
terminal capability over RS232. It is capable of storing files on a SD card
and if the target device supports the simple protocol employed here it can
also be a mass storage device, but rather slow.

Its functions include:

* Sending and receiving characters over RS232 port in an interactive way.
* Reading contents of text or binary file from SD card and sending them to
  RS232 port.
* Sending memory read command in format 'r <start_addr_hex>-<end_addr_hex>'
  to a device connected to RS232 port and then receiving response from it
  and saving it in file on SD card. This feature is specific to MKHBC-8-Rx
  computer and its monitor program / O.S. (called M.O.S. (C) Scott
  Chidester). The M.O.S. will respond to 'r hexaddr-hexaddr' command with
  series of 'w hexaddr data ...' lines which then are saved in file. They
  can be later send from the file to RS232 port thus making the monitor
  program write target memory with the same contents as they were saved.
* Sending command via RS232 and saving received output in file on SD card.
  This allows to save output from any program under condition that output
  is not interactive (no input) and fast (no more than 2 seconds between
  characters transmission). This way user may save listing of BASIC
  program when working with BASIC interpreter or listing of any program
  for any interpreter and then such listing can be loaded back to the
  interpreter from file. Also helpful to save text from word processor.
* List the directory of files on SD card.
* List contents of text file on SD card.
* Delete files on SD card.
  
The device produces VGA video using  VGA High-Res Text Driver v1.0
by Chip Gracey, Copyright (c) 2006 Parallax, Inc.
The parameters of the video output are:
640 x 480 @ 69Hz settings: 80 x 40 characters.

The keyboard input can take regular PS/2 PC keyboard ('keyboard' object) or
custom made retro keyboard made for MKHBC-8-Rx computer, based on TI99/4A
matrix keyboard with AT89S52 (8052 compatible) as a controller ('serkb_recv'
object).
All that is needed is to swap the object and recompile / re-load firmware
to the Propeller chip:

  serkb   : "serkb_recv"         '  serkb_recv object is interchangeable
  'serkb   : "keyboard"          ' with keyboard object - no more code
                                 '  changes are required, just swap them here
								 
Other code / drivers used in this object are:

* fsrw 2.6 Copyright 2009  Tomas Rokicki and Jonathan Dummer
* SPI interface routines for SD & SDHC & MMC cards
  Jonathan "lonesock" Dummer
  version 0.3.0  2009 July 19
* Full-Duplex Serial Driver v1.2, Author: Chip Gracey, Jeff Martin
  Copyright (c) 2006-2009 Parallax, Inc.
* ASCII0 String Engine
  Author: Kwabena W. Agyeman
  Version: 1.2, Copyright (c) 2010 Kwabena W. Agyeman
  
