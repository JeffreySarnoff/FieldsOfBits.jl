using Base: BitInteger, BitUnsigned, bitrotate, leading_zeros, trailing_zeros

@inline bitsof(x) = sizeof(x) << 3

@inline allzerobits(::Type{T}) where {T<:BitInteger} = zero(T)
@inline allonebits(::Type{T}) where {T<:BitInteger} = ~zero(T)

@inline onebits(::Type{T}, n) where {T<:BitInteger} = allonebits(T) >> max(0, (bitsof(T) - n))

@inline masklsbs(n::T) where {T<:BitInteger} = (one(T) << n) - one(T)
@inline masklsbs(::Type{T}, n) where {T<:BitInteger} = (one(T) << n) - one(T)

@inline maskbits(n::T, shift) where {T<:BitInteger} = masklsbs(n) << shift
@inline maskbits(::Type{T}, n, shift) where {T<:BitInteger} = masklsbs(T, n) << shift

@inline filterbits(n::T, shift) where {T<:BitInteger} = ~maskbits(n, shift)
@inline filterbits(::Type{T}, n, shift) where {T<:BitInteger} = ~maskbits(T, n, shift)
