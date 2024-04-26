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

