"""
    BitFieldSpec()


"""
struct BitFieldSpec{T<:Base.BitUnsigned} <: Unsigned
    mask::T
    shift::UInt16
    width::UInt16
    name::Symbol
end

mask(x::BitFieldSpec) = x.mask
shift(x::BitFieldSpec) = x.shift
masklsbs(x::BitFieldSpec) = (x.mask) >> x.shift
width(x::BitFieldSpec) = x.width
name(x::BitFieldSpec) = x.name

Base.eltype(x::BitFieldSpec{T}) where {T} = T

Base.leading_zeros(x::BitFieldSpec) = leading_zeros(mask(x))
Base.trailing_zeros(x::BitFieldSpec) = shift(x)

function BitFieldSpec(name::Symbol, mask::T) where {T<:Base.BitUnsigned}
    shift = UInt16(trailing_zeros(mask))
    width = UInt16(trailing_ones(mask >> shift))
    BitFieldSpec(mask, shift % UInt16, width % UInt16, name)
end

function BitFieldSpec(::Type{T}; name::Symbol, width, shift) where {T<:Base.BitUnsigned}
    (bitsof(T) < width + shift) && throw(DomainError("$(bitsof(T)) < shift + width ($(shift) + $(width))"))
    width == 0 && return throw(DomainError("width must be > 0"))
    width == bitsof(T) && return ones(T)
    mask = (one(T) << width - one(T)) << shift
    BitFieldSpec(mask, shift % UInt16, width % UInt16, name)
end

function Base.show(io::IO, x::BitFieldSpec)
    str = string(x)
    print(io, str)
end

function Base.string(x::BitFieldSpec)
    mask = x.mask
    shift = Int16(x.shift)
    width = Int16(x.width)
    name = x.name
    spec = (; name, mask, shift, width)
    string(spec)
end

@inline function validate(bfs::BitFieldSpec{T}, x::T) where {T}
    leading_zeros(x) >= bitsof(T) - bfs.width
end

