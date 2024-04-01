using Base: bitrotate, leading_zeros, trailing_zeros

@inline masklsbs(n::T) where {T<:BitInteger} = (one(T) << n) - one(T)
@inline masklsbs(::Type{T}, n) where {T<:BitInteger} = (one(T) << n) - one(T)

@inline maskbits(n::T, offset) where {T<:BitInteger} = masklsbs(n) << offset
@inline maskbits(::Type{T}, n, offset) where {T<:BitInteger} = masklsbs(T, n) << offset

@inline filterbits(n::T, offset) where {T<:BitInteger} = ~maskbits(n, offset)
@inline filterbits(::Type{T}, n, offset) where {T<:BitInteger} = ~maskbits(T, n, offset)
