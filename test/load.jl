
using Base: BitUnsigned, BitInteger
using Static
import TupleTools as TT

const Masks = static(1)
const Shifts = static(2)
const Syms = static(3)

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

masks(x::BasicBitFields) = x.masks
shifts(x::BasicBitFields) = x.shifts
mask(x::BasicBitFields, i) = @inbounds x.masks[i]
shift(x::BasicBitFields, i) = @inbounds x.shifts[i]
masklsbs(x::BasicBitFields, i) = @inbounds x.masks[i] >> x.shifts[i]

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

"""
    struct NamedBitFields

- const field `masks`
- const field `shifts`
- const field `syms`
"""
struct NamedBitFields{N,T<:BitInteger}
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
shift(x::NamedBitFields, i) = @inbounds x.shifts[i]
sym(x::NamedBitFields, i) = @inbounds x.syms[i]
masklsbs(x::BasicBitFields, i) = @inbounds x.masks[i] >> x.shifts[i]

function Base.NamedTuple(x::NamedBitFields{N,T}) where {N,T}
    NamedTuple{syms(x)}(collect(zip(masks(x), shifts(x))))
end

function Base.show(io::IO, x::NamedBitFields{N,T}) where {N,T}
    str = string(NamedTuple(x))
    print(io, str)
end

mutable struct BitFields{N,T<:BitInteger} <: Integer
    value::T
    const syms::NTuple{N,Symbol}
    const masks::NTuple{N,T}
    const shifts::NTuple{N,Int8}
end

# field indices
const BFvalue = 1
const BFsyms = 2
const BFmasks = 3
const BFshifts = 4

value(x::BitFields) = getfield(x, BFvalue)
syms(x::BitFields) = getfield(x, BFsyms)
masks(x::BitFields) = getfield(x, BFmasks)
shifts(x::BitFields) = getfield(x, BFshifts)

sym(x::BitFields, i) = @inbounds syms(x)[i]
mask(x::BitFields, i) = @inbounds masks(x)[i]
shift(x::BitFields, i) = @inbounds shifts(x)[i]

masklsbs(x::BitFields, i) = mask(x, i) >> shift(x, i)
bitwidth(x::BitFields{N,T}, i) where {N,T} = bitsof(T) - leading_zeros(masklsbs(x, i))

Base.eltype(x::BitFields{N,T}) where {N,T} = T

function specify(bfs::BitFields{N,T}, sym::Symbol) where {N,T}
    symbols = syms(bfs)
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
    symbols = syms(bfs)
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
    symbols = syms(bfs)
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
    BitFields{N,T}(zero(T), specs.syms, specs.masks, specs.shifts)

function BitFields(::Type{T}, specs::NamedBitFields{N,T}) where {N,T}
    BitFields{N,T}(zero(T), specs.syms, specs.masks, specs.shifts)
end

function BitFields(::Type{T}, syms::NTuple{N,Symbol}, bitmasks::NTuple{N,<:Unsigned}) where {N,T<:BitInteger}
    specs = NamedBitFields(T, syms, bitmasks)
    BitFields{N,T}(zero(T), specs.syms, specs.masks, specs.shifts)
end

function BitFields(::Type{T}, syms::NTuple{N,Symbol}, bitspans::NTuple{N,<:Signed}) where {N,T}
    specs = NamedBitFields(T, syms, bitspans)
    BitFields{N,T}(zero(T), specs.syms, specs.masks, specs.shifts)
end

