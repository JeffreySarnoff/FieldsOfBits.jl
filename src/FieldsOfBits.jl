module FieldsOfBits

export BitField, Carrier,
       BitFields, NT

using Base: BitUnsigned, BitInteger
import TupleTools as TT

bitsof(::Type{T}) = sizeof(T) << 3
bitsof(x::T) where {T} = sizeof(T) << 3

abstract type Carrier{T<:Unsigned} end

struct BitField{T} <: Carrier{T}
    mask::T
    nbits::UInt16
    shift::UInt16
end

mask(@nospecialize(x::BitField)) = x.mask
nbits(@nospecialize(x::BitField)) = x.nbits
shift(@nospecialize(x::BitField)) = x.shift

Base.eltype(x::BitField{T}) where {T} = T

function BitField(mask::T) where {T<:BitUnsigned}
    shift = trailing_zeros(mask) % UInt16
    nbits = (bitsof(T) - leading_zeros(mask >> shift)) % UInt16
    BitField(mask, nbits, shift)
end

function BitField(nbits::T, shift::T) where {T<:Integer}
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
    BitField(mask, nbits % UInt16, shift % UInt16)
end




include("bitops.jl")
include("bitfieldspec.jl")
include("bitfield.jl")
include("bitfields.jl")
include("builders.jl")

end  # BitFields

