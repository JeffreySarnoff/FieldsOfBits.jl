surrounding_zeros(x) = leading_zeros(x) + trailing_zeros(x)

"""
    mutable struct BitField

- mutable field `value`
- const field `mask`
"""
mutable struct BitField{T<:Base.BitUnsigned}
    value::T
    const mask::T
end

value(x::BitField) = x.value
mask(x::BitField) = x.mask
shift(x::BitField) = trailing_zeros(mask(x))
masklsbs(x::BitField) = mask(x) >> shift(x)
width(x::BitField{T}) where {T} = bitsof(T) - surrounding_zeros(mask(x))

BitField(mask::T) where {T<:Base.BitUnsigned} =
    BitField{T}(zero(T), mask)

function Base.copy(x::BitField{T}) where {T}
    bf = BitField(mask(x))
    bf.value = x.value
    bf
end

"""
    utype(_)

unsigned type
"""
utype(x::BitField{T}) where {T} = T

"""
    getvalue(x::BitField)

obtain value(x) shifted into the lsbs
"""
@inline function getvalue(x::BitField{T}) where {T}
    (value(x) & mask(x)) >> trailing_zeros(mask(x))
end

"""
    setvalue!(x::BitField, newvalue)

shift the newvalue into position, replace value(x)
"""
@inline function setvalue!(x::BitField{T}, newvalue) where {T}
    newval = isa(newvalue, T) ? newvalue : convert(T, newvalue)
    newval = (newval & (mask(x) >> trailing_zeros(mask(x))))
    x.value = newval << trailing_zeros(mask(x))
end

function Base.show(io::IO, x::BitField)
    str = string(x)
    print(io, str)
end

function Base.string(x::BitField)
    string("BitField(", hexstring(value(x)), ")")
end

const zerostr = "00000000000000000000000000000000"

function hexstring(x::Unsigned)
    hexstr = string(x, base=16)
    nhexdigits = length(hexstr)
    nzeros = max(2, nextpow(2, nhexdigits)) - nhexdigits
    zs = zerostr[1:nzeros]
    "0x" * zs * hexstr
end
