struct BitsField{T<:Base.BitUnsigned} <: Unsigned
    mask::T
    offset::UInt16
    nbits::UInt16
end

struct BitField{{T<:Base.BitUnsigned} <: Unsigned
    x::T
    field::BitsField
end

BitsField(::Type{T}, nbits::UInt16, offset::UInt16) where {T<:Base.BitUnsigned}
    if nbits == bitsof(T)
        BitField{T}(~zero(T), zero(UInt16), UInt16(bitsof(T))
    else
        mask = onebits(T, n) << (bitsof(T) - offset)
        BitField{T}(mask, offset, nbits)
    end
end

isolate(x::BitField{T}) where {T<:Base.BitUnsigned}
   (x.x & x.field.mask)
end
