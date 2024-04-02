using Base: BitInteger, BitUnsigned, bitrotate, leading_zeros, trailing_zeros

@inline bitsof(x) = sizeof(x) << 3

@inline allzerobits(::Type{T}) where {T<:BitInteger} = zero(T)
@inline allonebits(::Type{T}) where {T<:BitInteger} = ~zero(T)

@inline onebits(::Type{T}, n) where {T<:BitInteger} = allonebits(T) >> max(0, (bitsof(T) - n))

@inline masklsbs(n::T) where {T<:BitInteger} = (one(T) << n) - one(T)
@inline masklsbs(::Type{T}, n) where {T<:BitInteger} = (one(T) << n) - one(T)

@inline maskbits(n::T, offset) where {T<:BitInteger} = masklsbs(n) << offset
@inline maskbits(::Type{T}, n, offset) where {T<:BitInteger} = masklsbs(T, n) << offset

@inline filterbits(n::T, offset) where {T<:BitInteger} = ~maskbits(n, offset)
@inline filterbits(::Type{T}, n, offset) where {T<:BitInteger} = ~maskbits(T, n, offset)
