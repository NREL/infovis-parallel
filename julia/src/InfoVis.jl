module InfoVis

module Buffers
  const _ProtoBuf_Top_ = @static isdefined(parentmodule(@__MODULE__), :_ProtoBuf_Top_) ? (parentmodule(@__MODULE__))._ProtoBuf_Top_ : parentmodule(@__MODULE__)
  include("Buffers.jl")
end

module Transport
  include("Transport.jl")
end

module Primitives
  include("Primitives.jl")
end

module Plots
  include("Plots.jl")
end

end
