"""
    struct NamedBitFields

- const field `masks`
- const field `shifts`
- const field `ids`
"""
struct NamedBitFields{N, T<:BitInteger}
    masks::NTuple{N,T}
    shifts::NTuple{N,Int8}
    ids::NTuple{N,Symbol}
end

function NamedBitFields(basic::BasicBitFields{N,T}, symbols::Tuple{Vararg{Symbol,N}}) where {N,T}
    themasks = masks(basic)
    theshifts = shifts(basic)
    NamedBitFields{N,T}(themasks, theshifts, symbols)
end

function NamedBitFields(::Type{T}, ids::NTuple{N,Symbol}, bitmasks::NTuple{N,<:Unsigned}) where {N,T<:BitInteger}
    bitshifts = map(a -> Int8(trailing_zeros(a)), bitmasks)
    NamedBitFields{N,T}(bitmasks, bitshifts, ids)
end

function NamedBitFields(::Type{T}, ids::NTuple{N,Symbol}, bitspans::NTuple{N,S}) where {N,T,S}
    NamedBitFields(T, masks_from_spans(T, bitspans), ids)
end

Base.fieldcount(x::NamedBitFields{N,T}) where {N,T} = N

masks(x::NamedBitFields) = getfield(x, :masks)
shifts(x::NamedBitFields) = getfield(x, :shifts)
ids(x::NamedBitFields) = getfield(x, :ids)

mask(x::NamedBitFields, i) = @inbounds masks(x)[i]
shift(x::NamedBitFields, i) = @inbounds shifts(x)[i]
sym(x::NamedBitFields, i) = @inbounds ids(x)[i]
masklsbs(x::BasicBitFields, i) = @inbounds masks(x)[i] >> shifts(x)[i]

function Base.NamedTuple(x::NamedBitFields{N,T}) where {N,T}
    NamedTuple{ids(x)}(collect(zip(masks(x), shifts(x))))
end

function Base.show(io::IO, x::NamedBitFields{N,T}) where {N,T}
    nt = NamedTuple{ids(nbf)}(zip(masks(nbf), shifts(nbf)))
    str = string("NamedBitFields{",N,",",T,"}",nt)
    print(io, str)
end
