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
