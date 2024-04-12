# FieldsOfBits.jl
#### This package provides a clean way to define, access, and alter bitfields.
#### Copyright  © 2024 by Jeffrey A. Sarnoff \<jeffrey.sarnoff@ieee.org\>.
##### Released under the MIT License.
----

A bitfield is a span of bits within an unsigned type, often a UInt32 or a UInt64 (UInt8, UInt16, UInt32, UInt64, UInt128 are supported).
Typically, a sequence of bitfields is specified and the unsigned type used is the smallest one that accommodates all of the bitfields.

Bitfields have names. These names are of type Symbol. Every bitfield specification has its name.  The name of the bitfield is used to extract the field content from the surrounding the binary information and to reset the content within the surrouding the binary information.

- One way to specify a bitfield is to give its *bitwidth*, the count of bits spanned, and its *offset*, the shift up from the least significant bit.
- Another way to specify a bitfield is to give its *bitmask*, the sequence of bits (all set to 0b1) that covers the bitfield exactly, in its intended position.

The targeted unsigned type, the type wherein the bitfield is to be placed, may be specified explicitly. 
- If unspecified, then the smallest unsigned type that accommodates [all] the bitfield[s] is used.

----

[BitFields (a)](assets/images/BitFieldsA.svg)

