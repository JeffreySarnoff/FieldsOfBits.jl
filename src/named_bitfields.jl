"""
    struct NamedBitFields

- const field `masks`
- const field `shifts`
- const field `names`
"""
struct NamedBitFields{N, T<:BitInteger}
    masks::NTuple{N,T}
    shifts::NTuple{N,Int8}
    names::NTuple{N,Symbol}
end


function NamedBitFields(::Type{T}, names::NTuple{N,Symbol}, bitmasks::NTuple{N,T}) where {N,T<:BitInteger}
    bitshifts = map(a -> Int8(trailing_zeros(a)), bitmasks)
    NamedBitFields{N,T}(bitmasks, bitshifts, names)
end

function NamedBitFields(::Type{T}, names::NTuple{N,Symbol}, bitspans::NTuple{N,<:Signed}) where {N,T}
    NamedBitFields(T, masks_from_spans(T, bitspans), names)
end

Base.fieldcount(x::NamedBitFields{N,T}) where {N,T} = N

fields(x::NamedBitFields) = x.fields
masks(x::NamedBitFields) = x.masks
mask(x::NamedBitFields, i) = @inbounds x.masks[i]
offset(x::NamedBitFields, i) = trailing_zeros(mask(x, i))
value(x::NamedBitFields, i) = fields(x) & mask(x, i)
