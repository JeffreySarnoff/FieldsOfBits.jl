struct BitFields{N,T<:BitInteger} <: Integer
    value::T
    bitfields::NamedBitFields{N,T}
end

value(x::BitFields) = x.value
bitfields(x::BitFields) = x.bitfields
masks(x::BitFields) = x.bitfields.masks
shifts(x::BitFields) = x.bitfields.shifts
syms(x::BitFields) = x.bitfields.syms

mask(x::BitFields, i) = @inbounds masks(x)[i]
shift(x::BitFields, i) = @inbounds shift(x)[i]
name(x::BitFields, i) = @inbounds name(x)[i]

masklsbs(x::BitFields, i) = mask(x, i) >> shift(x, i)
bitwidth(x::BitFields{N,T}, i) where {N,T} = bitsof(T) - leading_zeros(masklsbs(x, i))

Base.eltype(x::BitFields{N,T}) where {N,T} = T

function Base.getproperty(bfs::BitFields{N,T}, name::Symbol) where {N,T}
    idx = findfirst(===(name), names(bfs))
    (mask(bfs, idx), shift(bfs, idx))
end


BitFields(nbf::NamedBitFields{N,T}) where {N,T} =
    BitFields{N,T}(zero(T), nbf)

function BitFields(::Type{T}, nbf::NamedBitFields{N,T}) where {N,T}
    BitFields{N,T}(zero(T), nbf)
end

function BitFields(::Type{T}, names::NTuple{N,Symbol}, bitmasks::NTuple{N,<:Unsigned}) where {N,T<:BitInteger}
    namedbitfields = NamedBitFields(T, names, bitmasks)
    BitFields{N,T}(zero(T), namedbitfields)
end

function BitFields(::Type{T}, names::NTuple{N,Symbol}, bitspans::NTuple{N,<:Signed}) where {N,T}
    namedbitfields = NamedBitFields(T, names, bitspans)
    BitFields{N,T}(zero(T), namedbitfields)
end

function Base.show(io::IO, x::BitFields)
    valstr = string(x.value)
    str = valstr * ": " * string(NamedTuple(x.bitfields))
    print(io, str)
end

