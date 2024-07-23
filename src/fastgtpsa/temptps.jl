"""
    struct TempTPS{T<:Union{Float64,ComplexF64}}

This is for internal use only. `TempTPS` is a temporary `TPS`, which has 
been pre-allocated in a buffer for each thread in the `Descriptor` C struct. 
When using the `@FastGTPSA` macro, all temporaries generated will be used 
from this buffer. "Constructors" of this type simply take a temporary from 
that particular thread's buffer in a stack-like manner and "Destructors" 
(which must be manually called because this is immutable) release it from 
the stack.

### Fields
- `t::Ptr{TPS{T}}` -- Pointer to the `TPS` in the buffer in the `Descriptor`
"""
struct TempTPS{T<:Union{Float64,ComplexF64}}
  t::Ptr{TPS{T}}

  function TempTPS{Float64}(use::Union{TPS,TempTPS})
    desc = unsafe_load(getdesc(use).desc)
    tmpidx = unsafe_load(desc.ti, Threads.threadid())
    if tmpidx == DESC_MAX_TMP
      # Run out of temporaries... no choice but to throw error 
      # Release this thread's temporaries and give warning to run cleartemps!()
      unsafe_store!(desc.ti, Cint(0), Threads.threadid())
      unsafe_store!(desc.cti, Cint(0), Threads.threadid())
      try
        error("Permanent temporaries buffer out of memory (max $DESC_MAX_TMP). To use @FastGTPSA, please split expression into subexpressions.")
      finally
        #GTPSA.cleartemps!(getdesc(use))
      end
    end
    idx = (Threads.threadid()-1)*DESC_MAX_TMP+tmpidx+1 # Julia is one based with unsafe_load! First this is 0
    t = unsafe_load(Base.unsafe_convert(Ptr{Ptr{TPS{Float64}}}, desc.t), idx)

    #println("threadid = ", Threads.threadid(), ", getting temp t[", idx-1,"], incrementing ti[", Threads.threadid()-1, "] = ", tmpidx, "->", tmpidx+1)
    unsafe_store!(desc.ti, tmpidx+Cint(1), Threads.threadid())
    return new(t)
  end

  function TempTPS{ComplexF64}(use::Union{TPS,TempTPS})
    desc =  unsafe_load(getdesc(use).desc)
    tmpidx = unsafe_load(desc.cti, Threads.threadid())
    if tmpidx == DESC_MAX_TMP
      # Run out of temporaries... no choice but to throw error 
      # Release this thread's temporaries and give warning to run cleartemps!()
      unsafe_store!(desc.ti, Cint(0), Threads.threadid())
      unsafe_store!(desc.cti, Cint(0), Threads.threadid())
      error("Permanent temporaries buffer out of memory (max $DESC_MAX_TMP). To use @FastGTPSA, please split expression into subexpressions, and if this Julia run is not terminated, GTPSA.cleartemps!(d::Descriptor=GTPSA.desc_current) must be executed.")
    end
    idx = (Threads.threadid()-1)*DESC_MAX_TMP+tmpidx+1
    t = unsafe_load(Base.unsafe_convert(Ptr{Ptr{TPS{ComplexF64}}}, desc.ct), idx)

  
    unsafe_store!(desc.cti, tmpidx+Cint(1), Threads.threadid())
    return new(t)
  end
end

# --- "destructors" ---
# These release a temporary from the stack
function rel_temp!(t::TempTPS{Float64})
  desc = unsafe_load(mad_tpsa_desc(t))
  tmpidx = unsafe_load(desc.ti, Threads.threadid())
  #println("decrementing ti[", Threads.threadid()-1, "] = ", tmpidx, "->", tmpidx-1)
  # Make sure we release this actual temporary
  @assert unsafe_load(Base.unsafe_convert(Ptr{Ptr{TPS{Float64}}}, desc.t), (Threads.threadid()-1)*DESC_MAX_TMP+tmpidx) == t.t "Something went wrong"
  
  unsafe_store!(desc.ti, tmpidx-Cint(1), Threads.threadid())
  return
end

function rel_temp!(t::TempTPS{ComplexF64})
  desc = unsafe_load(mad_ctpsa_desc(t))
  tmpidx = unsafe_load(desc.cti, Threads.threadid())

    # Make sure we release this actual temporary
  @assert unsafe_load(Base.unsafe_convert(Ptr{Ptr{TPS{ComplexF64}}}, desc.ct), (Threads.threadid()-1)*DESC_MAX_TMP+tmpidx) == t.t "Something went wrong"

  unsafe_store!(desc.cti, tmpidx-Cint(1), Threads.threadid())
  return
end

# --- temporary sanity checks/cleaners ---
# Clears all temporaries:
function cleartemps!(d::Descriptor=GTPSA.desc_current)
  desc = unsafe_load(d.desc)
  for i = 1:Threads.nthreads()
    unsafe_store!(desc.ti, Cint(0), i)
    unsafe_store!(desc.cti, Cint(0), i)
  end
  return
end

# Checks that no temps are being used
function checktemps(d::Descriptor=GTPSA.desc_current)
  desc = unsafe_load(d.desc)
  for i=1:desc.nth
    unsafe_load(desc.ti, i) == 0 || return false
    unsafe_load(desc.cti, i) == 0 || return false
  end
  return true
end

Base.unsafe_convert(::Type{Ptr{TPS{T}}}, t::TempTPS{T}) where {T} = t.t
Base.eltype(::Type{TempTPS{T}}) where {T} = T
Base.eltype(::TempTPS{T}) where {T} = T

promote_rule(::Type{TempTPS{Float64}}, ::Type{T}) where {T<:Real} = TempTPS{Float64} 
promote_rule(::Type{TempTPS{Float64}}, ::Type{TempTPS{ComplexF64}}) = TempTPS{ComplexF64}
promote_rule(::Type{TempTPS{ComplexF64}}, ::Type{T}) where {T<:Number} = TempTPS{ComplexF64}
promote_rule(::Type{TempTPS{Float64}}, ::Type{T}) where {T<:Number} = TempTPS{ComplexF64}
promote_rule(::Type{T}, ::Type{TempTPS{Float64}}) where {T<:AbstractIrrational} = (T <: Real ? TempTPS{Float64} : TempTPS{ComplexF64})
promote_rule(::Type{T}, ::Type{TempTPS{ComplexF64}}) where {T<:AbstractIrrational} = TempTPS{ComplexF64}
promote_rule(::Type{T}, ::Type{TempTPS{Float64}}) where {T<:Rational} = (T <: Real ? TempTPS{Float64} : TempTPS{ComplexF64})
promote_rule(::Type{T}, ::Type{TempTPS{ComplexF64}}) where {T<:Rational} = TempTPS{ComplexF64}
promote_rule(::Type{TempTPS{Float64}}, ::Type{TPS{Float64}}) = TempTPS{Float64}
promote_rule(::Type{TempTPS{Float64}}, ::Type{TPS{ComplexF64}}) = TempTPS{ComplexF64}
promote_rule(::Type{TempTPS{ComplexF64}}, ::Type{TPS{Float64}}) = TempTPS{ComplexF64}
promote_rule(::Type{TempTPS{ComplexF64}}, ::Type{TPS{ComplexF64}})  = TempTPS{ComplexF64}

getmo(t::TempTPS) = unsafe_load(Base.unsafe_convert(Ptr{LowTempTPS}, t.t)).mo

# This struct just allows access to the fields of the temporaries
# because unsafe_load of mutable structs causes allocation in Julia
# instead of just reading the struct
struct LowTempTPS
  d::Ptr{Desc}                                            
  lo::UInt8                
  hi::UInt8     
  mo::UInt8  
  ao::UInt8
  uid::Cint            
  nam::NTuple{16,UInt8}  # NAMSZ = 16
  # End of compatibility
end