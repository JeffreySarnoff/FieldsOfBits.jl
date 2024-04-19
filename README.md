# FieldsOfBits.jl
#### This package provides a clean way to define, access, and alter bitfields.
#### Copyright  © 2024 by Jeffrey A. Sarnoff \<jeffrey.sarnoff@ieee.org\>.
##### Released under the MIT License.
----

A bitfield is a named span of bits within an unsigned bitstype. A well-formed set of bitfields is non-overlapping. 

The `carrier` type assigned a well-formed set of bitfields is the smallest one that accommodates all of the constituent bitfields, unless otherwise explicitly given.



Every bitfield has a name. This name is used to reference the field within a carrier.  and each bitfield set has a name.  These names are given as Symbols.


 of the bitfield is used to extract the field content from the surrounding the binary information and to reset the content within the surrounding the binary information.

- One way to specify a bitfield is to give its *bitwidth*, the count of bits spanned, and its *shift*, the shift up from the least significant bit.
- Another way to specify a bitfield is to give its *bitmask*, the sequence of bits (all set to 0b1) that covers the bitfield exactly, in its intended position.

The targeted unsigned type, the type wherein the bitfield is to be placed, may be specified explicitly. 
- If unspecified, then the smallest unsigned type that accommodates [all] the bitfield[s] is used.

----

![BitFields (a)](https://github.com/JeffreySarnoff/FieldsOfBits.jl/blob/main/assets/images/BitFields(1).svg)<img src="
https://github.com/JeffreySarnoff/FieldsOfBits.jl/blob/main/assets/images/BitFields(1).svg">

