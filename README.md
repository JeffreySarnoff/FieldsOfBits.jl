# FieldsOfBits.jl
#### This package provides a clean way to define, organize and use bitfields.
#### Copyright  © 2024 by Jeffrey A. Sarnoff \<jeffrey.sarnoff@ieee.org\>.
##### Released under the MIT License.

----

```
bitsof(x) = sizeof(x) * 8

struct BitField{T<:Base.BitUnsigned}
    bitmask::T
    name::Symbol
end

bitmask(bitfield) = bitfield.bitmask
name(bitfield) = bitfield.name
```

###
##### *Here, a three bit field is positioned to cover the most significant bits a byte.*
```
    ---------------------------------
    | 1 | 1 | 1 | 0 | 0 | 0 | 0 | 0 |
    ---------------------------------
      7   6   5   4   3   2   1   0      offset (gives each bit position)
```
- The bitmask for this bitfield is `0b1110_0000`.
- The bitwidth of this bitfield is `3`, the number of bits spanned.
- The offset of this bitfield is `5`, the position of its lsb within the byte.

```
offset(bitfield)   = offset(bitmask(bitfield))
bitwidth(bitfield) = bitwidth(bitmask(bitfield))

offset(bitmask)    = trailing_zeros(bitmask)
bitwidth(bitmask)  = bitsof(bitmask) - zerobits(bitmask)

zerobits(bitfield) = zerobits(bitmask(bitfield))
zerobits(bitmask)  = leading_zeros(bitmask) + trailing_zeros(bitmask)
```

- Every bitfield is given by its *name* and its *bitmask*.
- Every bitfield covers one or more adjacent bits, this extent is its *width*. 
- Every bitfield is shifted up from the least significant bit position of carrier into the carrier by zero or more from the  lsb by zero or more bit positions, this count is its *offset*.
 [offsets are 0-based, offset=index-1].

A bitfield is a named span of bits within an unsigned bitstype. Multiple bitfields may co-reside within an unsigned bitstype.  Coresident bitfields must be non-overlapping.

The unsigned bitstype in which mutiple bitfields co-reside is their `carrier`.   The `Carrier Type` automatically assigned to hold co-resident bitfields is the smallest unsigned type that accommodates all of the constituent bitfields. If desired, a larger carrier type may be specified.



```
    bitsof(x) = 8sizeof(x) 

    bitsof(bitmask) == bitwidth of bitfield +
       leading_zeros(bitmask) + 
       trailing_zeros(bitfield)
```

- One way to specify a bitfield is to give its *bitwidth*, the count of bits spanned, and its *shift*, the shift up from the least significant bit.

- Another way to specify a bitfield is to give its *bitmask*, the sequence of bits that covers the bitfield exactly set to 0b1 and there rest of the bits , in its intended position.

Usually, related bitfields are collected as sequenced coEvery co-resident sequence of bitfields has a name, given as a Symbol.

- One way to give a bitfield sequence is to specify the constituent bitfields together as a NamedTuple. 

You may use either ascending position order or descending position order.

BitfieldSequence = 
    (UTF8 = 0b1000_0000,  ASCII=0b0111_1111)

BitfieldSequence =
    (parity = 0b0000_0001, task = 0b0000_1110)

----

![BitFields (a)](https://github.com/JeffreySarnoff/FieldsOfBits.jl/blob/main/assets/images/BitFields(1).svg)<img src="
https://github.com/JeffreySarnoff/FieldsOfBits.jl/blob/main/assets/images/BitFields(1).svg">

