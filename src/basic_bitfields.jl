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

masks(x::BasicBitFields) = x.masks
shifts(x::BasicBitFields) = x.shifts
mask(x::BasicBitFields, i) = @inbounds x.masks[i]
offset(x::BasicBitFields, i) = @inbounds x.shifts[i]
masklsbs(x::BasicBitFields, i) = @inbounds x.masks[i] >> x.shifts[i]

"""
    eltype(_)

underlying type
"""
Base.eltype(x::BasicBitFields{N,T}) where {N,T} = T

"""
    masks_from_spans

a negative span skips over the offset bits associated with that span
- the positioned span is made unavailable and is unused
"""
function masks_from_spans(::Type{T}, spans::NTuple{N,I}) where {N,T<:BitInteger,I<:Signed}
    if any(map(isnegative, spans))
        return masks_from_spans_with_skips(T, spans)
    end
    offsets = offsets_for_masks(spans)
    lsbmasks = masks_in_lsbs(T, spans)
    map((lsbmask, offset) -> lsbmask << offset, lsbmasks, offsets)
end

"""
    getvalue(BasicBitFields, i, source)

obtain source shifted into the lsbs
"""
getvalue(bf::BasicBitFields{N,T}, i, x::T) where {N,T} = 
    (x & mask(bf, i)) >> offset(bf, i)

"""
    setvalue!(BasicBitFields, i, source, newvalue)

shift the newvalue into position, replace value(x)
"""
@inline function setvalue!(bf::BasicBitFields{N,T}, i, x::T, newvalue) where {N,T}
     newval = isa(newvalue, T) ? newvalue : convert(T, newvalue)
     newval = (newval & masklsbs(bf, i)) << offset(bf, i)
     x = x & ~mask(bf, i)
     x | newval
end
