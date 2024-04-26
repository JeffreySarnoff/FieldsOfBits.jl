struct BitFields{N,T<:BitInteger} <: Integer
    value::T
    fields::NamedBitFields{N,T}
end

value(x::BitFields) = x.value
fields(x::BitFields) = x.fields
masks(x::BitFields) = x.fields.masks
shifts(x::BitFieldSpec) = x.fields.shifts
names(x::BitFieldSpec) = x.fields.names

mask(x::BitFields, i) = @inbounds masks(x)[i]
shift(x::BitFields, i) = @inbounds shift(x)[i]
name(x::BitFields, i) = @inbounds name(x)[i]

masklsbs(x::BitFields, i) = mask(x, i) >> shift(x, i)
bitwidth(x::BitFields{N,T}, i) where {N,T} = bitsof(T) - leading_zeros(masklsbs(x, i))

Base.eltype(x::BitFields{N,T}) where {N,T} = T




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

