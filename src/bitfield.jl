struct BitFieldSpec{T<:Base.BitUnsigned} <: Unsigned
    mask::T
    offset::UInt16
    nbits::UInt16
end

mask(x::BitFieldSpec) = x.mask
offset(x::BitFieldSpec) = x.offset
nbits(x::BitFieldSpec) = x.nbits
Base.eltype(x::BitFieldSpec{T}) where {T} = T

Base.leading_zeros(x::BitFieldSpec) = leading_zeros(mask(x))
Base.trailing_zeros(x::BitFieldSpec) = offset(x)

function BitFieldSpec(mask::T) where {T<:Base.BitUnsigned}
     offset = UInt16(trailing_zeros(mask))
     nbits  = UInt16(trailing_ones(mask >> offset))
     BitFieldSpec(mask, offset, nbits)
end

function BitFieldSpec(::Type{T}; offset, nbits) where {T<:Base.BitUnsigned}
    (bitsof(T) < nbits + offset) && throw(DomainError("$(bitsof(T)) < offset + nbits ($(offset) + $(nbits))"))
    nbits == 0 && return throw(DomainError("nbits must be > 0"))
    nbits == bitsof(T) && return ones(T)
    mask = (one(T) << nbits - one(T)) << offset
    BitFieldSpec(mask, offset, nbits)
end

function Base.show(io::IO, x::BitFieldSpec)
    mask = x.mask
    offset = x.offset
    nbits = x.nbits
    nt = (;mask, offset, nbits)
    show(io, nt)
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
Base.eltype(x::BitFiel{T}) where {T} = T

@inline bitfield(x::BitField{T}) where {T} = x.content << x.spec.offset

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
end

@inline function set!(x::BitField{T}, content::T) where {T}
    !validate(x.spec, content) && throw(DomainError("cannot set $(x.spec.nbits) bit field to $(content)"))
    x.content = content
    x
end

function Base.show(io::IO, x::BitField)
    content = x.content
    field = bitfield(x)
    nt = (;field, content)
    show(io, nt)
end

@inline isolate(x::BitField{T}) where {T<:Base.BitUnsigned} =
   (x.x & x.spec.mask)

@inline intolsbs(x::BitField{T}) where {T<:Base.BitUnsigned} =
    isolate(x) >> x.spec.offset

@inline fromlsbs(x::T, b::BitField{T}) where {T<:Base.BitUnsigned} =
  b.x = (x << b.spec.offset) & b.spec.mask


