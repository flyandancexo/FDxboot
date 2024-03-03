# FDxboot - New 2024 World Fastest AVR MCU Bootloader
## AVR109 (45.9kB/s write and 51.1kB/s read) -  STK500 (To be released next)

![FDxboot](https://github.com/flyandancexo/FDxboot/assets/66555404/83d59ccd-a65c-4e93-824f-3d62e073551f)

A bootloader can actually be anything, but it's normally used as a means for the MCU to program itself via various input sources such as UART, SPI, I2C and etc. UART is ideal because it's relatively simple and fast.

An AVR MCU has built-in flash memory that can be separated into 2 sections: Application and Bootloader; The CPU level SPM instruction can only be run on the bootloader section, so self-program code can only be resided in the bootloader section. An 8kB MCU can have a bootloader size from 256 bytes to 2K bytes, and this is configured by its LOW and HIGH fuses. To sum up, a MCU with bootloader is like having 2 mini operational systems on one chip.

Note: 45.1kB/s is about 45,100 bytes per second. It's the fastest write speed on any known AVR MCU bootloader.

## Features for FDxboot v1.62 (AVR109):
- 1k bootloader with the fastest upload speed (see table below)
- Universally support all MCUs using UART as default data input
- Auto jump to application after a delay period, so auto-upload is supported
- Stable at 2Mbps using a Ch340 USB-to-Serial converter chip
- loosely based on AVR109, tested on AVRdude 6.3 and 7.0
- Highly optimized over and over again
- EEPROM read and write are not supported yet

## FDxboot V1.62 Speed Test Results - Loosely based on AVR109
| Baud Rate | MCU | Page Size | File Size | Write Time | Upload Speed | Read Time | Download Speed |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **2Mbps** | Atmega128 | 256 | 129,998 | 2.83s | **45,935 B/s** | 2.54s | **51,180 B/s** | 
| 1Mbps | Atmega128 | 256 | 129,998 | 3.36s | 38,689 B/s | 3.05s | 42,622 B/s | 
| 500kbps | Atmega128 | 256 | 129,998 | 4.57s | 28,445 B/s | 4.07s | 31,940 B/s | 
| **2Mbps** | Atmega328p | 128 | 31,736 | 1.20s | **26,446 B/s** | 0.99s | **32,056 B/s** | 
| 1Mbps | Atmega328p | 128 | 31,736 | 1.37s | 23,164 B/s | 0.99s | 32,056 B/s | 
| 500kbps | Atmega328p | 128 | 31,736 | 1.63s | 19,469 B/s | 1.24s | 25,593 B/s | 
| **2Mbps** | Atmega16 | 128 | 15,352 | 0.57s | **26,933 B/s** | 0.48s | **31,983 B/s** | 
| 1Mbps | Atmega16 | 128 | 15,352 | 0.65s | 23,618 B/s | 0.48s | 31,983 B/s | 
| 500kbps | Atmega16 | 128 | 15,352 | 0.77s | 19,937 B/s | 0.6s | 25,586 B/s | 
| **2Mbps** | Atmega88 | 64 | 6,102 | 0.43s | **14,190 B/s** | 0.29s | **21,041 B/s** | 
| 1Mbps | Atmega88 | 64 | 6,102 | 0.43s | 14,190 B/s | 0.29s | 21,041 B/s | 
| 500kbps | Atmega88 | 64 | 6,102 | 0.48s | 12,712 B/s | 0.39s | 15,646 B/s | 

## Features for FDxboot v2.x (STK500 to be released next):

## Potential Problems:
The USB cable and USB port can be very critical. The same cable works on other USB transfers may not work with AVRdude because AVRdude is actually a very primitive application without any error detection or recovery, so if one bit is corrupted during transfer, the whole upload is corrupted and it's very common to see error messages or out of sync problem with AVRdude. My bootloader is **highly optimized** and has been fully tested without any error on my antique PC whatsoever even with a CH340g at 2Mbps, and as a matter of fact, all the tests done were using a Ch340G, but if it's used on a USB hub with a lot of activity, then upload error is very normal, and it may not even work at all, but this is not the fault of my bootloader nor is there a bug in my bootloader. You are free to use other slower or more "stable" bootloader, and there are plenty to choose from. 

## How to Use:
1. Set the correct Fuses: 1k BOOTSZx and BOOTRST;
2. Upload the correct bootloader firmware to the MCU
3. Set lock fuse to 0xef
4. Use the following commands to send new code to the MCU

```
avrdude.exe -c avr109 -p m328p -b 2000000 -P COM3 -U flash:w:"new.hex":i
avrdude.exe -c avr109 -p m328p -b 1000000 -P COM3 -U flash:w:"new.hex":i
avrdude.exe -c avr109 -p m328p -b 500000  -P COM3 -U flash:w:"new.hex":i
```

## IDE-less 2.0:
The bootloader works flawlessly with my IDE-less script program: 

```
===============================================================
  Flyandance Advanced 8-bit AVR Compile and Upload UNI 2.0:
===============================================================
     << C Project:Juno_V4   ||   MCU:atmega88 >>
---------------------------------------------------------------
Compiling 3 source files:
V4DEV.c v4LCD.c V4_Main.c
===============================================================
=====>>              Compiling and Linking              <<=====
===============================================================

   <Project:Juno_V4> compiled Successfully! :)
   -------------------------------------------------------
   text    data     bss     dec     hex filename
   7082       0       6    7088    1bb0 Juno_AVR.elf
   -------------------------------------------------------
   <Juno_V4.hex> can be found here:
   C:\E-Dream\Project\Juno_V4\Output\

***************************************************************
>>>>>>>>           Upload Via butterfly           >>>>>>>>
***************************************************************

Connecting to programmer: .
Found programmer: Id = "FDxBoot"; type = S
    Software Version = 1.6; No Hardware Version given.
Programmer supports buffered memory access with buffersize=64 bytes.

Programmer supports the following devices:

avrdude.exe: AVR device initialized and ready to accept instructions

Reading | ################################################## | 100% 0.00s

avrdude.exe: Device signature = 0x1e930a (probably m88)
avrdude.exe: NOTE: "flash" memory has been specified, an erase cycle will be per
formed
             To disable this feature, specify the -D option.
avrdude.exe: erasing chip
avrdude.exe: reading input file "Juno_V4.hex"
avrdude.exe: writing flash (7082 bytes):

Writing | ################################################## | 100% 0.56s

avrdude.exe: 7082 bytes of flash written
avrdude.exe: verifying flash memory against Juno_V4.hex:

Reading | ################################################## | 100% 0.29s

avrdude.exe: 7082 bytes of flash verified

avrdude.exe done.  Thank you.

***************************************************************
*****                 Upload Successfully                 *****
***************************************************************
```

## More about Transfer Speed:
The absolute write speed for a 128-byte page MUC is 128/0.0045=28,444 B/s, and FDxboot V1.62 has achieved 26,446 B/s; On the other hand, the absolute write speed for a 64-byte page MUC is 64/0.0045=14,222 B/s, and FDxboot V1.62 has achieved 14,190 B/s. It's very close to unity. Read speed doesn't have any limit, but to make it stable at 2Mbps, FDxboot actually adds some delay to it, so it's stable at 2Mbps even using a CH340g. All the tests are done using a CH340g; Other USB-to-serial chip could be faster on the read speed, but probably not on the write speed. 

## Why faster is better:
1. For serious MCU developers, a faster bootloader allows him or her to upload more frequently.
2. A bootloader's only job is to upload and download, so its speed defines its quality.
3. Ultimately the creation of FDxboot is to test my understanding and have some fun.

To support the creation of more quality project, do donate whatever amount that you are comfortable with.

[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://paypal.me/flyandance?country.x=US&locale.x=en_US)

