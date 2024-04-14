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
    mask  = x.mask
    shift = Int16(x.shift)
    width = Int16(x.width)
    name  = x.name
    spec = (; name, mask, shift, width)
    string(spec)
end

@inline function validate(bfs::BitFieldSpec{T}, x::T) where {T}
    leading_zeros(x) >= bitsof(T) - bfs.width
end

mutable struct BitField{T<:Base.BitUnsigned} <: Unsigned
    content::T
    const spec::BitFieldSpec
end

content(x::BitField{T}) where {T} = x.content

spec(x::BitField{T}) where {T} = x.spec
mask(x::BitField{T}) where {T} = x.spec.mask
shift(x::BitField{T}) where {T} = x.spec.shift
masklsbs(x::BitField{T}) where {T} = masklsbs(x.spec)
width(x::BitField{T}) where {T} = x.spec.width
name(x::BitField{T}) where {T} = x.spec.name

Base.eltype(x::BitField{T}) where {T} = T

Base.leading_zeros(x::BitField) = leading_zeros(spec(x))
Base.trailing_zeros(x::BitField) = trailing_zeros(spec(x))

@inline iso_bitfield(x::BitField{T}) where {T} =
    (content(x) & mask(x))

@inline set_bitfield!(x::BitField{T}, content::T) where {T} =
     (content & masklsbs(x)) << x.spec.shift

@inline get_bitfield(x::BitField{T}) where {T} =
     (content(x) >> shift(x)) & masklsbs(x)



function BitField(spec::BitFieldSpec{T}) where {T}
    BitField(zero(T), spec)
end

@inline function Base.get(x::BitField{T}) where {T}
    x.content
end

@inline function unsafe_set!(x::BitField{T}, content::T) where {T}
    x.content = content
    x
end

@inline function set!(x::BitField{T}, content::T1) where {T,T1}
    value = content % T
    !validate(x.spec, value) && throw(DomainError("cannot set $(x.spec.width) bit field to $(value)"))
    unsafe_set!(x, value)
    x
end

function Base.show(io::IO, x::BitField)
    str = string(x)
    print(io, str)
end

function Base.string(x::BitField)
    content = x.spec.width < 64 ? Int64(x.content) : Int128(x.content)
    field = bitfield(x)
    nt = (;field, content)
    string(nt)
end


