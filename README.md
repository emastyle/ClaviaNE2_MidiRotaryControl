# ClaviaNE2_MidiRotaryControl

Using a three halfmoon like switch we can send the command to control the rotary emulator on Clavia Nord Electro 3.
Circuit is simple, using a PIC16F84

Command sent:
;Rotary Speaker Fast/Slow CC -> 0x52 ( CC 82 value -> 0 = slow, 127 = fast  )
;Rotary Speaker Run/Stop CC -> 0x53  ( CC 83 value -> 0 = off, 127 = on )
