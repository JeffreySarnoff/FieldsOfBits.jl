
using Base: BitUnsigned, BitInteger
using Static
import TupleTools as TT

const Masks = static(1)
const Shifts = static(2)
const Ids = static(3)

const Mask = static(1)
const Shift = static(2)

bitsof(::Type{T}) where {T} = sizeof(T) << 3
bitsof(x::T) where {T} = bitsof(T)

"""
    notnegative(x)

relatively more performant than `x >= 0`
- both 0.0 and -0.0 are considered nonnegative
- use !signbit(x) to map 0.0 to true, -0.0 to false
"""
notnegative(x::T) where {T} = x === abs(x)

"""
    isnegative(x)

can be more performant than `x < 0`
- both 0.0 and -0.0 are considered nonnegative
- use signbit(x) to map 0.0 to true, -0.0 to false
"""
isnegative(x::T) where {T} = x !== abs(x) && x !== zero(T)

const zerostr = "00000000000000000000000000000000"

function hexstring(x::Unsigned)
    hexstr = string(x, base=16)
    nhexdigits = length(hexstr)
    nzeros = max(2, nextpow(2, nhexdigits)) - nhexdigits
    zs = zerostr[1:nzeros]
    "0x" * zs * hexstr
end

# =====================

surrounding_zeros(x) = leading_zeros(x) + trailing_zeros(x)

"""
    mutable struct BitField

- mutable field `value`
- const field `mask`
"""
struct BitField{T<:Base.BitInteger}
    mask::T
    shift::Int8
end

mask(x::BitField) = getfield(x, 1)
shift(x::BitField) = getfield(x, 2)
masklsbs(x::BitField) = mask(x) >> shift(x)
width(x::BitField{T}) where {T} = bitsof(T) - surrounding_zeros(mask(x))

BitField(mask::T) where {T<:Base.BitUnsigned} =
    BitField{T}(mask, trailing_zeros(mask))

function Base.copy(x::BitField{T}) where {T}
    BitField(mask(x), shift(x))
end

Base.eltype(x::BitField{T}) where {T} = T

function Base.show(io::IO, x::BitField)
    str = string(x)
    print(io, str)
end

function Base.string(x::BitField)
    string("BitField(", hexstring(mask(x)), ")")
end

# ================================

"""
    struct BasicBitFields

- const field `masks`
- const field `shifts`
"""
struct BasicBitFields{N,T<:BitInteger}
    masks::NTuple{N,T}
    shifts::NTuple{N,Int8}
end

function BasicBitFields(::Type{T}, bitmasks::NTuple{N,T}) where {N,T<:BitInteger}
    bitshifts = map(a -> Int8(trailing_zeros(a)), bitmasks)
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
    aoffsets = [offsets_for_masks(aspans)...]
    offsets = Tuple(aoffsets[map(notnegative, [spans...])])
    bitspans = filter(notnegative, spans)
    lsbmasks = masks_in_lsbs(T, bitspans)
    map((lsbmask, offset) -> lsbmask << offset, lsbmasks, offsets)
end

function offsets_for_masks(spans::NTuple{N,<:Integer}) where {N}
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

# ======================================

"""
    struct NamedBitFields

- const field `masks`
- const field `shifts`
- const field `ids`
"""
struct NamedBitFields{N,T<:BitInteger}
    masks::NTuple{N,T}
    shifts::NTuple{N,Int8}
    ids::NTuple{N,Symbol}
end

function NamedBitFields(::Type{T}, ids::NTuple{N,Symbol}, bitmasks::NTuple{N,<:Unsigned}) where {N,T<:BitInteger}
    bitshifts = map(a -> Int8(trailing_zeros(a)), bitmasks)
    NamedBitFields{N,T}(bitmasks, bitshifts, ids)
end

function NamedBitFields(::Type{T}, ids::NTuple{N,Symbol}, bitspans::NTuple{N,<:Signed}) where {N,T}
    NamedBitFields(T, masks_from_spans(T, bitspans), ids)
end

Base.fieldcount(x::NamedBitFields{N,T}) where {N,T} = N

masks(x::NamedBitFields) = getfield(x, :masks)
shifts(x::NamedBitFields) = getfield(x, :shifts)
ids(x::NamedBitFields) = getfield(x.:ids)

mask(x::NamedBitFields, i) = @inbounds masks(x)[i]
shift(x::NamedBitFields, i) = @inbounds shifts(x)[i]
sym(x::NamedBitFields, i) = @inbounds ids(x)[i]
masklsbs(x::BasicBitFields, i) = @inbounds masks(x)[i] >> shifts(x)[i]

function Base.NamedTuple(x::NamedBitFields{N,T}) where {N,T}
    NamedTuple{ids(x)}(collect(zip(masks(x), shifts(x))))
end

function Base.show(io::IO, x::NamedBitFields{N,T}) where {N,T}
    str = string(NamedTuple(x))
    print(io, str)
end

# =========================

mutable struct BitFields{N,T<:BitInteger} <: Integer
    value::T
    const ids::NTuple{N,Symbol}
    const masks::NTuple{N,T}
    const shifts::NTuple{N,Int8}
end

# field indices
const BFvalue = 1
const BFids = 2
const BFmasks = 3
const BFshifts = 4

value(x::BitFields) = getfield(x, BFvalue)
ids(x::BitFields) = getfield(x, BFids)
masks(x::BitFields) = getfield(x, BFmasks)
shifts(x::BitFields) = getfield(x, BFshifts)

sym(x::BitFields, i) = @inbounds ids(x)[i]
mask(x::BitFields, i) = @inbounds masks(x)[i]
shift(x::BitFields, i) = @inbounds shifts(x)[i]

masklsbs(x::BitFields, i) = mask(x, i) >> shift(x, i)
bitwidth(x::BitFields{N,T}, i) where {N,T} = bitsof(T) - leading_zeros(masklsbs(x, i))

Base.eltype(x::BitFields{N,T}) where {N,T} = T

function specify(bfs::BitFields{N,T}, sym::Symbol) where {N,T}
    symbols = ids(bfs)
    idx = 1
    while idx <= N
        if sym === symbols[idx]
            break
        end
        idx += 1
    end
    NamedTuple{(:mask, :shift),Tuple{T,Int8}}((mask(bfs, idx), shift(bfs, idx)))
end

@inline function Base.getproperty(bfs::BitFields{N,T}, idx::Integer) where {N,T}
    (value(bfs) & mask(bfs, idx)) >>> shift(bfs, idx)
end

function Base.getproperty(bfs::BitFields{N,T}, sym::Symbol) where {N,T}
    symbols = ids(bfs)
    idx = 1
    while idx <= N
        if sym === symbols[idx]
            break
        end
        idx += 1
    end
    getproperty(bfs, idx)
end

@inline function Base.setproperty!(bfs::BitFields{N,T}, idx::Integer, newfieldvalue::T) where {N,T}
    newvalue = (value(bfs) & ~mask(bfs, idx)) |
               ((newfieldvalue << shift(bfs, idx)) & mask(bfs, idx))
    setfield!(bfs, :value, newvalue)
end

function Base.setproperty!(bfs::BitFields{N,T}, sym::Symbol, newfieldvalue::T) where {N,T}
    symbols = ids(bfs)
    idx = 1
    while idx <= N
        if sym === symbols[idx]
            break
        end
        idx += 1
    end
    newvalue = (value(bfs) & ~mask(bfs, idx)) |
               ((newfieldvalue << shift(bfs, idx)) & mask(bfs, idx))
    setfield!(bfs, :value, newvalue)
end

BitFields(specs::NamedBitFields{N,T}) where {N,T} =
    BitFields{N,T}(zero(T), specs.ids, specs.masks, specs.shifts)

function BitFields(::Type{T}, specs::NamedBitFields{N,T}) where {N,T}
    BitFields{N,T}(zero(T), specs.ids, specs.masks, specs.shifts)
end

function BitFields(::Type{T}, ids::NTuple{N,Symbol}, bitmasks::NTuple{N,<:Unsigned}) where {N,T<:BitInteger}
    specs = NamedBitFields(T, ids, bitmasks)
    BitFields{N,T}(zero(T), specs.ids, specs.masks, specs.shifts)
end

function BitFields(::Type{T}, ids::NTuple{N,Symbol}, bitspans::NTuple{N,<:Signed}) where {N,T}
    specs = NamedBitFields(T, ids, bitspans)
    BitFields{N,T}(zero(T), specs.ids, specs.masks, specs.shifts)
end

# ============================
