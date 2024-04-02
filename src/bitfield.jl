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
     BitFieldSpec(T, nbits, offset)
end

function BitFieldSpec(::Type{T}; nbits, offset) where {T<:Base.BitUnsigned}
    (bitsof(T) < nbits + offset) && throw(DomainError("$(bitsof(T)) < offset + nbits ($(offset) + $(nbits))"))
    nbits == 0 && return throw(DomainError("nbits must be > 0"))
    nbits == bitsof(T) && return ones(T)
    mask = (one(T) << nbits - one(T)) << offset
    BitFieldSpec(mask, offset, nbits)
end

function Base.show(io::IO, x::BitFieldSpec)
    str = string(x)
    print(io, str)
end

function Base.string(x::BitFieldSpec)
    mask = x.mask
    offset = Int16(x.offset)
    nbits = Int16(x.nbits)
    nt = (;mask, offset, nbits)
    string(nt)
end

@inline function validate(bfs::BitFieldSpec{T}, x::T) where {T}
    leading_zeros(x) >= bitsof(T) - bfs.nbits
end

struct NamedBitFieldSpec{T<:Base.BitUnsigned} <: Unsigned
    spec::BitFieldSpec{T}
    name::Symbol
end

mask(x::NamedBitFieldSpec) = x.spec.mask
offset(x::NamedBitFieldSpec) = x.spec.offset
nbits(x::NamedBitFieldSpec) = x.spec.nbits
name(x::NamedBitFieldSpec) = x.name
Base.eltype(x::NamedBitFieldSpec{T}) where {T} = T

Base.leading_zeros(x::BitFieldSpec) = leading_zeros(mask(x))
Base.trailing_zeros(x::BitFieldSpec) = offset(x)

function NamedBitFieldSpec(name::Symbol, mask::T) where {T<:Base.BitUnsigned}
     offset = UInt16(trailing_zeros(mask))
     nbits  = UInt16(trailing_ones(mask >> offset))
     spec = BitFieldSpec(T, nbits, offset)
     NamedBitFieldSpec(spec, name)
end

function NamedBitFieldSpec(::Type{T}; name::Symbol, nbits, offset) where {T<:Base.BitUnsigned}
    (bitsof(T) < nbits + offset) && throw(DomainError("$(bitsof(T)) < offset + nbits ($(offset) + $(nbits))"))
    nbits == 0 && return throw(DomainError("nbits must be > 0"))
    nbits == bitsof(T) && return ones(T)
    mask = (one(T) << nbits - one(T)) << offset
    spec = BitFieldSpec(mask, offset, nbits)
    NamedBitFieldSpec(spec, name)
end

function Base.show(io::IO, x::NamedBitFieldSpec)
    str = string(x)
    print(io, str)
end

function Base.string(x::NamedBitFieldSpec)
    name = x.name
    mask = x.spec.mask
    offset = Int16(x.spec.offset)
    nbits = Int16(x.spec.bits)
    nt = (;name, mask, offset, nbits)
    string(nt)
end

@inline function validate(bfs::NamedBitFieldSpec{T}, x::T) where {T}
    leading_zeros(x) >= bitsof(T) - bfs.spec.nbits
end

mutable struct BitField{T<:Base.BitUnsigned} <: Unsigned
    content::T
    const spec::BitFieldSpec
end

content(x::BitField{T}) where {T} = x.content
spec(x::BitField{T}) where {T} = x.spec
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
end

@inline function unsafe_set!(x::BitField{T}, content::Base.BitInteger) where {T}
    unsafe_set!(x, content % T)
end

@inline function set!(x::BitField{T}, content::T) where {T}
    !validate(x.spec, content) && throw(DomainError("cannot set $(x.spec.nbits) bit field to $(content)"))
    x.content = content
    x
end

@inline function set!(x::BitField{T}, content::Base.BitInteger) where {T}
    set!(x, content % T)
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

mutable struct NamedBitField{T<:Base.BitUnsigned} <: Unsigned
    content::T
    const spec::BitFieldSpec
    const name::Symbol
end

content(x::NamedBitField{T}) where {T} = x.content
spec(x::NamedBitField{T}) where {T} = x.spec
name(x::NamedBitField{T}) where {T} = x.name
Base.eltype(x::NamedBitField{T}) where {T} = T

@inline bitfield(x::NamedBitField{T}) where {T} = x.content << x.spec.offset
@inline bitfield(bfs::NamedBitFieldSpec{T}, x::T) where {T} = (x & bfs.mask) >> bfs.offset

Base.leading_zeros(x::NamedBitField) = leading_zeros(spec(x))
Base.trailing_zeros(x::NamedBitField) = trailing_zeros(spec(x))

function NamedBitField(name::Symbol, spec::BitFieldSpec{T}) where {T}
    NamedBitField(zero(T), spec, name)
end

@inline function Base.get(x::NameBitField{T}) where {T}
    x.content
end

@inline function unsafe_set!(x::NamedBitField{T}, content::T) where {T}
    x.content = content
end

@inline function unsafe_set!(x::NamedBitField{T}, content::Base.BitInteger) where {T}
    unsafe_set!(x, content % T)
end

@inline function set!(x::NamedBitField{T}, content::T) where {T}
    !validate(x.spec, content) && throw(DomainError("cannot set $(x.spec.nbits) bit field to $(content)"))
    x.content = content
    x
end

@inline function set!(x::NamedBitField{T}, content::Base.BitInteger) where {T}
    set!(x, content % T)
end

function Base.show(io::IO, x::NamedBitField)
    str = string(x)
    print(io, str)
end

function Base.string(x::NamedBitField)
    content = x.spec.nbits < 64 ? Int64(x.content) : Int128(x.content)
    field = bitfield(x)
    name = x.name
    nt = (;name, field, content)
    string(nt)
end


