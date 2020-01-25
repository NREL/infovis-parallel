# syntax: proto3
using ProtoBuf
import ProtoBuf.meta

mutable struct Geometry <: ProtoType
    fram::Int32
    iden::Int64
    _type::Int32
    mask::Int32
    cnts::Base.Vector{Int32}
    posx::Base.Vector{Float64}
    posy::Base.Vector{Float64}
    posz::Base.Vector{Float64}
    size::Float64
    colr::UInt32
    text::AbstractString
    glyp::Int32
    Geometry(; kwargs...) = (o=new(); fillunset(o); isempty(kwargs) || ProtoBuf._protobuild(o, kwargs); o)
end #mutable struct Geometry
const __pack_Geometry = Symbol[:cnts,:posx,:posy,:posz]
const __wtype_Geometry = Dict(:colr => :fixed32)
meta(t::Type{Geometry}) = meta(t, ProtoBuf.DEF_REQ, ProtoBuf.DEF_FNUM, ProtoBuf.DEF_VAL, true, __pack_Geometry, __wtype_Geometry, ProtoBuf.DEF_ONEOFS, ProtoBuf.DEF_ONEOF_NAMES, ProtoBuf.DEF_FIELD_TYPES)

mutable struct Location <: ProtoType
    posx::Float64
    posy::Float64
    posz::Float64
    rotw::Float64
    rotx::Float64
    roty::Float64
    rotz::Float64
    Location(; kwargs...) = (o=new(); fillunset(o); isempty(kwargs) || ProtoBuf._protobuild(o, kwargs); o)
end #mutable struct Location

mutable struct Request <: ProtoType
    show::Int32
    message::AbstractString
    reset::Bool
    upsert::Base.Vector{Geometry}
    delete::Base.Vector{Int64}
    viewloc::Location
    toolloc::Location
    offsetloc::Location
    Request(; kwargs...) = (o=new(); fillunset(o); isempty(kwargs) || ProtoBuf._protobuild(o, kwargs); o)
end #mutable struct Request
const __pack_Request = Symbol[:delete]
meta(t::Type{Request}) = meta(t, ProtoBuf.DEF_REQ, ProtoBuf.DEF_FNUM, ProtoBuf.DEF_VAL, true, __pack_Request, ProtoBuf.DEF_WTYPES, ProtoBuf.DEF_ONEOFS, ProtoBuf.DEF_ONEOF_NAMES, ProtoBuf.DEF_FIELD_TYPES)

mutable struct Response <: ProtoType
    shown::Int32
    message::AbstractString
    hover::Base.Vector{Int64}
    unhover::Base.Vector{Int64}
    select::Base.Vector{Int64}
    deselect::Base.Vector{Int64}
    viewloc::Location
    toolloc::Location
    offsetloc::Location
    depressed::UInt32
    pressed::UInt32
    released::UInt32
    analog::Base.Vector{Float64}
    Response(; kwargs...) = (o=new(); fillunset(o); isempty(kwargs) || ProtoBuf._protobuild(o, kwargs); o)
end #mutable struct Response
const __pack_Response = Symbol[:hover,:unhover,:select,:deselect,:analog]
const __wtype_Response = Dict(:depressed => :fixed32, :pressed => :fixed32, :released => :fixed32)
meta(t::Type{Response}) = meta(t, ProtoBuf.DEF_REQ, ProtoBuf.DEF_FNUM, ProtoBuf.DEF_VAL, true, __pack_Response, __wtype_Response, ProtoBuf.DEF_ONEOFS, ProtoBuf.DEF_ONEOF_NAMES, ProtoBuf.DEF_FIELD_TYPES)

export Geometry, Location, Request, Response
