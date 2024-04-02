struct BitFieldSpecs{N, T} <: Unsigned
     specs::NTuple{N, BitFieldSpec{T}}
end

specs(x::BitFieldSpecs) = x.specs
nspecs(x::BitFieldSpecs{N,T}) where {N,T} = N
Base.names(x::BitFieldSpecs) = map(name, x.specs)

Base.eltype(x::BitFieldSpecs) = eltype(x[1])

BitFieldSpecs(structs::Vararg{BitFieldSpec}) = BitFieldSpecs(structs)

function BitFieldSpecs(masks::NTuple{N,T}) where {N, T<:Base.BitUnsigned}
     sortedmasks = Tuple(sort([masks...]))
     # check for overlapping masks
     overlap = !iszero( foldl(|, [foldl(&, sortedmasks[i:i+1]) for i=1:N-1]) )
     overlap && throw(DomainError("the bitfield masks overlap: $(sortedmasks)"))
     specs = map(BitFieldSpec, sortedmasks)
     BitFieldSpecs(specs)
end

function BitFieldSpecs(::Type{T1};nbits::NTuple{N, T2}) where {T1<:Base.BitUnsigned, T2, N}
     # highs = cumsum(nbits)
     # lows = highs .- nbits .+ 1
     # fieldspans = map((lo,hi)->lo:hi, lows, highs)
     offsets = cumsum(nbits) .- nbits
     map((count, offset)->BitFieldSpec(count, offset), nbits, offsets)
end

function Base.show(io::IO, x::BitFieldSpecs{N, T}) where {N, T}
    str = string(x)
    print(io, str) 
end

function Base.string(x::BitFieldSpecs{N, T}) where {N, T}
     join(map(string, x.specs), '\n')
end

struct BitFields{N, T} <: Unsigned
    fields::NTuple{N, T}
end

fields(x::BitFields) = x.fields
nfields(x::BitFields{N,T}) where {N,T} = N
Base.names(x::BitFields) = map(x->x.spec.name, x.fields)
Base.eltype(x::BitFields) = eltype(x[1])

BitFields(fields::Vararg{BitField}) = BitFieldSpecs(fields)

function Base.show(io::IO, x::BitFields{N, T}) where {N, T}
    str = string(x)
    print(io, str) 
end

function Base.string(x::BitFields{N, T}) where {N, T}
     symbols = names(x)
     values = map(x->Int64(content(x)), x.fields)
     nt = NamedTuple{symbols}(values)
     string(nt)
end

Base.getindex(x::BitFields, i::Integer) = getindex(x.fields, i) 

function Base.getproperty(x::BitFields, nm::Symbol)
     if nm == :fields
          getfield(x, :fields)
     else
        idx = findfirst(x->name(x)==(nm), getfield(x, :fields))
        if !isnothing(idx)
            getfield(x, :fields)[idx]
        else
           throw(ErrorException("name $(nm) is not found"))
        end
     end
end


#=
@inline idxofname(x::BitFields, name::Symbol) =
     findfirst(==(name), names(x))

@inline function getnamedfield(x::BitFields, name::Symbol)
     idx = idxofname(x, name)
     isnothing(idx) && throw(ErrorException("name $(name) is not found"))
     x.fields[idx]
end

function Base.getindex(x::BitFields, nm::Symbol)
     idx = findfirst(x->name(x)==(nm), x.fields)
     !isnothing(idx) ? x.fields[idx] : idx
end
=#

#=
function Base.getindex(x::BitFields, idx::Integer)
     x.fields[idx]
end
=#
