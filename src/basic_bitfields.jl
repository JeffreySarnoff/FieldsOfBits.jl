"""
    struct BasicBitFields

- const field `masks`
- const field `shifts`
"""
struct BasicBitFields{N, T<:BitInteger}
    masks::NTuple{N,T}
    shifts::NTuple{N,Int8}
end

function BasicBitFields(::Type{T}, bitmasks::NTuple{N,T}) where {N,T<:BitInteger}
     bitshifts = map(a->Int8(trailing_zeros(a)), bitmasks)
     BasicBitFields{N,T}(bitmasks, bitshifts)
end

function BasicBitFields(::Type{T}, bitspans::NTuple{N,<:Signed}) where {N,T}
     BasicBitFields(T, masks_from_spans(T, bitspans))
end

Base.fieldcount(x::BasicBitFields{N,T}) where {N,T} = N

masks(x::BasicBitFields) = getfield(x, :masks)
shifts(x::BasicBitFields) = getfield(x, :shifts)

mask(x::BasicBitFields, i) = @inbounds masks(x)[i]
shift(x::BasicBitFields, i) = @inbounds shifts(x)[i]
masklsbs(x::BasicBitFields, i) = @inbounds masks(x)[i] >> shifts(x)[i]

"""
    eltype(_)

underlying type
"""
Base.eltype(x::BasicBitFields{N,T}) where {N,T} = T

"""
    masks_from_spans

a negative span skips over the shift bits associated with that span
- the positioned span is made unavailable and is unused
"""
function masks_from_spans(::Type{T}, spans::NTuple{N,I}) where {N,T<:BitInteger,I<:Signed}
    if any(map(isnegative, spans))
        return masks_from_spans_with_skips(T, spans)
    end
    shifts = shifts_for_masks(spans)
    lsbmasks = masks_in_lsbs(T, spans)
    map((lsbmask, shift) -> lsbmask << shift, lsbmasks, shifts)
end

function masks_from_spans_with_skips(::Type{T}, spans::NTuple{N,<:Integer}) where {N,T<:BitInteger}
    aspans = abs.(spans)
    aoffsets = [shifts_for_masks(aspans)...]
    offsets = Tuple(aoffsets[map(notnegative, [spans...])])
    bitspans = filter(notnegative, spans)
    lsbmasks = masks_in_lsbs(T, bitspans)
    map((lsbmask, offset) -> lsbmask << offset, lsbmasks, offsets)
end

function shifts_for_masks(spans::NTuple{N,<:Integer}) where {N}
    (0, cumsum(spans)[1:end-1]...)
end

function masks_in_lsbs(::Type{T}, spans::NTuple{N,<:Integer}) where {N,T}
    map(a -> masklsbs(T, a), spans)
end

function masklsbs(::Type{T}, nbits::Integer) where {T}
    nbits > bitsof(T) && throw(DomainError("nbits ($nbits) must be <= $(bitsof(T))"))
    nbits == bitsof(T) && return onebits(T)
    (one(T) << nbits) - one(T)
end

"""
    getvalue(BasicBitFields, i, source)

obtain source shifted into the lsbs
"""
getvalue(bf::BasicBitFields{N,T}, i, x::T) where {N,T} = 
    (x & mask(bf, i)) >> shift(bf, i)

"""
    setvalue!(BasicBitFields, i, source, newvalue)

shift the newvalue into position, replace value(x)
"""
@inline function setvalue!(bf::BasicBitFields{N,T}, i, x::T, newvalue) where {N,T}
     newval = isa(newvalue, T) ? newvalue : convert(T, newvalue)
     newval = (newval & masklsbs(bf, i)) << shift(bf, i)
     x = x & ~mask(bf, i)
     x | newval
end

