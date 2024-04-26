"""
    struct BasicBitFields

- const field `masks`
- const field `shifts`
"""
struct BasicBitFields{N, T<:BitInteger}
    masks::NTuple{N,T}
    shifts::NTuple{N,Int8}
end

function BasicBitFields(::Type{T}, bitmasks::NTuple{N,T}) where {N,T<:BitInteger}
     bitshifts = map(a->Int8(trailing_zeros(a)), bitmasks)
     BasicBitFields{N,T}(bitmasks, bitshifts)
end

function BasicBitFields(::Type{T}, bitspans::NTuple{N,<:Signed}) where {N,T}
     BasicBitFields(T, masks_from_spans(T, bitspans))
end

Base.fieldcount(x::BasicBitFields{N,T}) where {N,T} = N

masks(x::BasicBitFields) = x.masks
shifts(x::BasicBitFields) = x.shifts
mask(x::BasicBitFields, i) = @inbounds x.masks[i]
offset(x::BasicBitFields, i) = @inbounds x.shifts[i]
masklsbs(x::BasicBitFields, i) = @inbounds x.masks[i] >> x.shifts[i]

"""
    eltype(_)

underlying type
"""
Base.eltype(x::BasicBitFields{N,T}) where {N,T} = T

"""
    masks_from_spans

a negative span skips over the offset bits associated with that span
- the positioned span is made unavailable and is unused
"""
function masks_from_spans(::Type{T}, spans::NTuple{N,I}) where {N,T<:BitInteger,I<:Signed}
    if any(map(isnegative, spans))
        return masks_from_spans_with_skips(T, spans)
    end
    offsets = offsets_for_masks(spans)
    lsbmasks = masks_in_lsbs(T, spans)
    map((lsbmask, offset) -> lsbmask << offset, lsbmasks, offsets)
end

"""
    getvalue(BasicBitFields, i, source)

obtain source shifted into the lsbs
"""
getvalue(bf::BasicBitFields{N,T}, i, x::T) where {N,T} = 
    (x & mask(bf, i)) >> offset(bf, i)

"""
    setvalue!(BasicBitFields, i, source, newvalue)

shift the newvalue into position, replace value(x)
"""
@inline function setvalue!(bf::BasicBitFields{N,T}, i, x::T, newvalue) where {N,T}
     newval = isa(newvalue, T) ? newvalue : convert(T, newvalue)
     newval = (newval & masklsbs(bf, i)) << offset(bf, i)
     x = x & ~mask(bf, i)
     x | newval
end
















struct BasicBitFieldspecs{N, T} <: Unsigned
     specs::NTuple{N, BasicBitFieldspec{T}}
end

specs(x::BasicBitFieldspecs) = x.specs
nspecs(x::BasicBitFieldspecs{N,T}) where {N,T} = N
Base.names(x::BasicBitFieldspecs) = map(name, x.specs)

Base.eltype(x::BasicBitFieldspecs) = eltype(x[1])

BasicBitFieldspecs(structs::Vararg{BasicBitFieldspec}) = BasicBitFieldspecs(structs)

function BasicBitFieldspecs(masks::NTuple{N,T}) where {N, T<:Base.BitUnsigned}
     sortedmasks = Tuple(sort([masks...]))
     # check for overlapping masks
     overlap = !iszero( foldl(|, [foldl(&, sortedmasks[i:i+1]) for i=1:N-1]) )
     overlap && throw(DomainError("the bitfield masks overlap: $(sortedmasks)"))
     specs = map(BasicBitFieldspec, sortedmasks)
     BasicBitFieldspecs(specs)
end

function BasicBitFieldspecs(::Type{T1};width::NTuple{N, T2}) where {T1<:Base.BitUnsigned, T2, N}
     # highs = cumsum(width)
     # lows = highs .- width .+ 1
     # fieldspans = map((lo,hi)->lo:hi, lows, highs)
     shifts = cumsum(width) .- width
     map((count, shift)->BasicBitFieldspec(count, shift), width, shifts)
end

function Base.show(io::IO, x::BasicBitFieldspecs{N, T}) where {N, T}
    str = string(x)
    print(io, str) 
end

function Base.string(x::BasicBitFieldspecs{N, T}) where {N, T}
     join(map(string, x.specs), '\n')
end

struct BasicBitFields{N, T} <: Unsigned
    fields::NTuple{N, T}
end

fields(x::BasicBitFields) = x.fields
nfields(x::BasicBitFields{N,T}) where {N,T} = N
Base.names(x::BasicBitFields) = map(x->x.spec.name, x.fields)
Base.eltype(x::BasicBitFields) = eltype(x[1])

BasicBitFields(fields::Vararg{BitField}) = BasicBitFieldspecs(fields)

BasicBitFields(bfs::BasicBitFieldspecs) = map(BitField, bfs.specs)

function Base.show(io::IO, x::BasicBitFields{N, T}) where {N, T}
    str = string(x)
    print(io, str) 
end

function Base.string(x::BasicBitFields{N, T}) where {N, T}
     symbols = names(x)
     values = map(x->Int64(content(x)), x.fields)
     nt = NamedTuple{symbols}(values)
     string(nt)
end

Base.getindex(x::BasicBitFields, i::Integer) = getindex(x.fields, i) 

function Base.setindex!(x::BasicBitFields, value::Integer, idx::Integer)
     val = value % eltype(x)
     bf = x.fields[idx]
     setfield!(bf, :content, val)
end
     
function Base.getproperty(x::BasicBitFields, nm::Symbol)
     if nm == :fields
          getfield(x, :fields)
     else
        idx = findfirst(x->name(x)==(nm), getfield(x, :fields))
        if !isnothing(idx)
            getfield(x, :fields)[idx]
        else
           throw(ErrorException("fieldname $(nm) is not found"))
        end
     end
end

function Base.setproperty!(x::BasicBitFields, nm::Symbol, targetvalue::Integer)
     val = targetvalue % eltype(x)
     idx = findfirst(x->name(x)==(nm), getfield(x, :fields))
     isnothing(idx) && throw(ErrorException("fieldname $(nm) is not found"))
     setfield!(getfield(x, :fields)[idx], :content, val)
end

