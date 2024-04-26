using Base: BitInteger, BitUnsigned, bitrotate, leading_zeros, trailing_zeros

@inline bitsof(x) = sizeof(x) << 3

@inline zerobits(::Type{T}) where {T<:BitInteger} = zero(T)
@inline onebits(::Type{T}) where {T<:BitInteger} = ~zero(T)

@inline onebits(::Type{T}, n) where {T<:BitInteger} = onebits(T) >> max(0, (bitsof(T) - n))

@inline masklsbs(n::T) where {T<:BitInteger} = (one(T) << n) - one(T)
@inline masklsbs(::Type{T}, n) where {T<:BitInteger} = (one(T) << n) - one(T)

@inline maskbits(n::T, shift) where {T<:BitInteger} = masklsbs(n) << shift
@inline maskbits(::Type{T}, n, shift) where {T<:BitInteger} = masklsbs(T, n) << shift

@inline filterbits(n::T, shift) where {T<:BitInteger} = ~maskbits(n, shift)
@inline filterbits(::Type{T}, n, shift) where {T<:BitInteger} = ~maskbits(T, n, shift)

"""
    masks_from_spans_with_skips

use negative numbers for spans to be skipped, making them unavailable
- each negative value makes the corresponding positioned span unavailable
"""
function masks_from_spans_with_skips(::Type{T}, spans::NTuple{N,<:Integer}) where {N,T<:BitInteger}
    aspans = abs.(spans)
    aoffsets = [offsets_for_masks(aspans)...]
    offsets = Tuple(aoffsets[map(notnegative, [spans...])])
    bitspans = filter(notnegative, spans)
    lsbmasks = masks_in_lsbs(T, bitspans)
    map((lsbmask, offset) -> lsbmask << offset, lsbmasks, offsets)
end

function masklsbs(::Type{T}, nbits::Integer) where {T}
    nbits > bitsof(T) && throw(DomainError("nbits ($nbits) must be <= $(bitsof(T))"))
    nbits == bitsof(T) && return onebits(T)
    (one(T) << nbits) - one(T)
end

function offsets_for_masks(spans::NTuple{N,<:Integer}) where {N}
    (0, cumsum(spans)[1:end-1]...)
end

function masks_in_lsbs(::Type{T}, spans::NTuple{N,<:Integer}) where {N,T}
    map(a->masklsbs(T, a), spans)
end


