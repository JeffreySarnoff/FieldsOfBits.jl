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


