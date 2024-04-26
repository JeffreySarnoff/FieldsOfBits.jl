module FieldsOfBits

export BitMask, BitField, Carrier,
       BitFields, NT

using Base: BitUnsigned, BitInteger
using Static
import TupleTools as TT

bitsof(::Type{T}) where {T} = sizeof(T) << 3
bitsof(x::T) where {T} = bitsof(T)

"""
    notnegative(x)

relatively more performant than `x >= 0`
- both 0.0 and -0.0 are considered nonnegative
- use !signbit(x) to map 0.0 to true, -0.0 to false
"""
notnegative(x::T) where {T} = x === abs(x)

"""
    isnegative(x)

can be more performant than `x < 0`
- both 0.0 and -0.0 are considered nonnegative
- use signbit(x) to map 0.0 to true, -0.0 to false
"""
isnegative(x::T) where {T} = x !== abs(x) && x !== zero(T)


include("bitops.jl")
include("bitfield.jl")
include("basic_bitfields.jl")
include("named_bitfields.jl")


abstract type Carrier{T<:BitUnsigned} end

struct BitMask{T<:BitUnsigned}
    mask::T
end

mask(@nospecialize(x::BitMask)) = x.mask
shift(@nospecialize(x::BitMask)) = trailing_zeros(x.mask)
nbits(x::BitMask{T}) where {T} = bitsof(T) - leading_zeros(x.mask >> trailing_zeros(x.mask))
masklow(@nospecialize(x::BitMask)) = x.mask >> trailing_zeros(x.mask)
unmask(@nospecialize(x::BitMask)) = ~x.mask
unmasklow(@nospecialize(x::BitMask)) = ~masklow(x)

Base.eltype(x::BitMask{T}) where {T} = T


function BitMask(nbits::T, shift::T) where {T<:Integer}
    nbits > 0 || throw(DomainError("nbits ($nbits) must be in (0..128]"))
    shift >= 0 || throw(DomainError("shift ($shift) must be in [0..127]"))
    hibit = nbits + shift
    maskbits = nextpow(2, nbits + shift)
    masktype = if maskbits == 8
                   UInt8
               elseif maskbits == 16
                   UInt16
               elseif maskbits == 32
                   UInt32
               elseif maskbits == 64
                   UInt64
               elseif maskbits == 128
                   UInt128
               else
                   throw(DomainError("maskbits ($maskbits) must be in [8,16,32,64,128]."))
               end
    mask = ~zero(masktype) >> (bitsof(masktype) - nbits)
    mask = mask << shift
    BitMask(mask)
end

struct BitField{T<:BitUnsigned}
     mask::T
     name::Symbol
end

BitField(name::Symbol, mask::T) where {T<:BitUnsigned} =
    BitField(mask, name)

BitMask(x::BitField{T}) where {T} =
    BitMask(x.mask)

BitField(name::Symbol, mask::BitMask{T}) where {T} =
    BitField(mask.mask, name)

BitField(mask::BitMask{T}, name::Symbol) where {T} =
    BitField(mask.mask, name)

mask(@nospecialize(x::BitField)) = x.mask
name(@nospecialize(x::BitField)) = x.name
shift(@nospecialize(x::BitField)) = trailing_zeros(x.mask)
nbits(x::BitField{T}) where {T} = bitsof(T) - leading_zeros(x.mask >> trailing_zeros(x.mask))
masklow(@nospecialize(x::BitField)) = x.mask >> trailing_zeros(x.mask)
unmask(@nospecialize(x::BitField)) = ~x.mask
unmasklow(@nospecialize(x::BitField)) = ~masklow(x)

Base.eltype(x::BitField{T}) where {T} = T

include("bitfields.jl")
include("builders.jl")

end  # BitFields

