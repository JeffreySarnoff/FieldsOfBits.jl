"""
    NamedNTuple( ids::NTuple{N, Symbol}, ::T) where {N,T}

NamedNTuple((:a, :b), ::Int) ↦ NamedTuple{(:a, :b), {Int, Int}}
"""
function NamedNTuple(ids::NTuple{N, Symbol}, ::Type{T}) where {N,T}
    NamedTuple{ids, NTuple{N,T}}
end

function Base.sort(nt::NamedTuple; rev::Bool=false)
    ids = keys(nt)
    vals = values(nt)
    sperm = TT.sortperm(vals)
    if rev
        sperm = reverse(sperm)
    end
    sortedids = Tuple([ids[i] for i in sperm])
    sortedvals = [vals[i] for i in sperm]
    NamedTuple{sortedids}(sortedvals)
end

# UNCHECKED PRECONDITION nt = sort(nt)
function unsafe_overlap(nt::NamedTuple)
    increments = first.(values(nt))[2:end] .- last.(values(nt))[1:end-1]
    any(map(x->(x<1), increments))
end

const UINTs = (UInt8, UInt8, UInt8, UInt16, UInt32, UInt64, UInt128)

function uintfor(nt::NamedTuple)
    mx = last(values(nt)[end])
    UINTs[ceil(Int, log2(mx))]
end

function BitFieldSpecs(nt::NamedTuple)
   snt = sort(nt)
   unsafe_overlap(snt) && throw(ErrorException("bitfields must not overlap"))
   uint = uintfor(snt)
   symbols = keys(snt)
   uints = fill(uint, length(symbols))
   bitwidths = map(length, values(snt))
   shifts = map(first, values(snt)) .- 1
   znt = zip(uints, symbols, bitwidths, shifts)
   fieldspecs = Tuple(map(a->BitFieldSpec(a[1]; name=a[2], width=a[3], shift=a[4]), znt))
   BitFieldSpecs(fieldspecs)
end

function BitFields(nt::NamedTuple)
   BitFields(BitFieldSpecs(nt))
end
