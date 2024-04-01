struct BitsField{T<:Base.BitUnsigned} <: Unsigned
    mask::T
    offset::UInt16
    nbits::UInt16
end

mutable struct BitField{{T<:Base.BitUnsigned} <: Unsigned
    x::T
    const field::BitsField
end

BitsField(::Type{T}, nbits::UInt16, offset::UInt16) where {T<:Base.BitUnsigned}
    if nbits == bitsof(T)
        BitField{T}(~zero(T), zero(UInt16), UInt16(bitsof(T))
    else
        mask = onebits(T, n) << (bitsof(T) - offset)
        BitField{T}(mask, offset, nbits)
    end
end

@inline isolate(x::BitField{T}) where {T<:Base.BitUnsigned} =
   (x.x & x.field.mask)

@inline intolsbs(x::BitField{T}) where {T<:Base.BitUnsigned} =
    isolate(x) >> x.field.offset

@inline fromlsbs(x::T, b::BitField{T}) where {T<:Base.BitUnsigned} =
  b.x = (x << b.field.offset) & b.field.mask


