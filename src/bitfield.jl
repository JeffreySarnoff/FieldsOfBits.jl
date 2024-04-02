struct BitFieldSpec{T<:Base.BitUnsigned} <: Unsigned
    mask::T
    offset::UInt16
    nbits::UInt16
    name::Symbol
end

mask(x::BitFieldSpec) = x.mask
offset(x::BitFieldSpec) = x.offset
nbits(x::BitFieldSpec) = x.nbits
name(x::BitFieldSpec) = x.name
Base.eltype(x::BitFieldSpec{T}) where {T} = T

Base.leading_zeros(x::BitFieldSpec) = leading_zeros(mask(x))
Base.trailing_zeros(x::BitFieldSpec) = offset(x)

function BitFieldSpec(name::Symbol, mask::T) where {T<:Base.BitUnsigned}
     offset = UInt16(trailing_zeros(mask))
     nbits  = UInt16(trailing_ones(mask >> offset))
     BitFieldSpec(mask, offset % UInt16, nbits % UInt16, name)
end

function BitFieldSpec(::Type{T}; name::Symbol, nbits, offset) where {T<:Base.BitUnsigned}
    (bitsof(T) < nbits + offset) && throw(DomainError("$(bitsof(T)) < offset + nbits ($(offset) + $(nbits))"))
    nbits == 0 && return throw(DomainError("nbits must be > 0"))
    nbits == bitsof(T) && return ones(T)
    mask = (one(T) << nbits - one(T)) << offset
    BitFieldSpec(mask, offset % UInt16, nbits % UInt16, name)
end

function Base.show(io::IO, x::BitFieldSpec)
    str = string(x)
    print(io, str)
end

function Base.string(x::BitFieldSpec)
    mask = x.mask
    offset = Int16(x.offset)
    nbits = Int16(x.nbits)
    name = x.name
    nt = (;name, mask, offset, nbits)
    string(nt)
end

@inline function validate(bfs::BitFieldSpec{T}, x::T) where {T}
    leading_zeros(x) >= bitsof(T) - bfs.nbits
end

mutable struct BitField{T<:Base.BitUnsigned} <: Unsigned
    content::T
    const spec::BitFieldSpec
end

content(x::BitField{T}) where {T} = x.content
spec(x::BitField{T}) where {T} = x.spec
mask(x::BitField{T}) where {T} = x.spec.mask
offset(x::BitField{T}) where {T} = x.spec.offset
nbits(x::BitField{T}) where {T} = x.spec.nbits
name(x::BitField{T}) where {T} = x.spec.name
Base.eltype(x::BitField{T}) where {T} = T

@inline bitfield(x::BitField{T}) where {T} = x.content << x.spec.offset
@inline bitfield(bfs::BitFieldSpec{T}, x::T) where {T} = (x & bfs.mask) >> bfs.offset

Base.leading_zeros(x::BitField) = leading_zeros(spec(x))
Base.trailing_zeros(x::BitField) = trailing_zeros(spec(x))

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
    !validate(x.spec, value) && throw(DomainError("cannot set $(x.spec.nbits) bit field to $(value)"))
    unsafe_set!(x, value)
    x
end

function Base.show(io::IO, x::BitField)
    str = string(x)
    print(io, str)
end

function Base.string(x::BitField)
    content = x.spec.nbits < 64 ? Int64(x.content) : Int128(x.content)
    field = bitfield(x)
    nt = (;field, content)
    string(nt)
end


