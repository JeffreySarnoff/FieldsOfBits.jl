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

masks(x::NamedBitFields) = x.masks
shifts(x::NamedBitFields) = x.shifts
names(x::NamedBitFields) = x.names

mask(x::NamedBitFields, i) = @inbounds x.masks[i]
offset(x::NamedBitFields, i) = @inbounds x.shifts[i]
name(x::NamedBitFields, i) = @inbounds x.names[i]
masklsbs(x::BasicBitFields, i) = @inbounds x.masks[i] >> x.shifts[i]

function Base.NamedTuple(x::NamedBitFields{N,T}) where {N,T}
    NamedTuple{names(x)}( collect(zip(masks(x), shifts(x))))
end

