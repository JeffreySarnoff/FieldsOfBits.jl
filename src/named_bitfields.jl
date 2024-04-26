"""
    struct NamedBitFields

- const field `masks`
- const field `shifts`
- const field `syms`
"""
struct NamedBitFields{N, T<:BitInteger}
    masks::NTuple{N,T}
    shifts::NTuple{N,Int8}
    syms::NTuple{N,Symbol}
end

function NamedBitFields(::Type{T}, syms::NTuple{N,Symbol}, bitmasks::NTuple{N,<:Unsigned}) where {N,T<:BitInteger}
    bitshifts = map(a -> Int8(trailing_zeros(a)), bitmasks)
    NamedBitFields{N,T}(bitmasks, bitshifts, syms)
end

function NamedBitFields(::Type{T}, syms::NTuple{N,Symbol}, bitspans::NTuple{N,<:Signed}) where {N,T}
    NamedBitFields(T, masks_from_spans(T, bitspans), syms)
end

Base.fieldcount(x::NamedBitFields{N,T}) where {N,T} = N

masks(x::NamedBitFields) = x.masks
shifts(x::NamedBitFields) = x.shifts
syms(x::NamedBitFields) = x.syms

mask(x::NamedBitFields, i) = @inbounds x.masks[i]
offset(x::NamedBitFields, i) = @inbounds x.shifts[i]
sym(x::NamedBitFields, i) = @inbounds x.syms[i]
masklsbs(x::BasicBitFields, i) = @inbounds x.masks[i] >> x.shifts[i]

function Base.NamedTuple(x::NamedBitFields{N,T}) where {N,T}
    NamedTuple{syms(x)}(collect(zip(masks(x), shifts(x))))
end

function Base.show(io::IO, x::NamedBitFields{N,T}) where {N,T}
    str = string(NamedTuple(x))
    print(io, str)
end
