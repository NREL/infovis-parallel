// Generated by the protocol buffer compiler.  DO NOT EDIT!
// source: infovis.proto3
#pragma warning disable 1591, 0612, 3021
#region Designer generated code

using pb = global::Google.Protobuf;
using pbc = global::Google.Protobuf.Collections;
using pbr = global::Google.Protobuf.Reflection;
using scg = global::System.Collections.Generic;
namespace Infovis.Protobuf {

  /// <summary>Holder for reflection information generated from infovis.proto3</summary>
  public static partial class InfovisReflection {

    #region Descriptor
    /// <summary>File descriptor for infovis.proto3</summary>
    public static pbr::FileDescriptor Descriptor {
      get { return descriptor; }
    }
    private static pbr::FileDescriptor descriptor;

    static InfovisReflection() {
      byte[] descriptorData = global::System.Convert.FromBase64String(
          string.Concat(
            "Cg5pbmZvdmlzLnByb3RvMxIHSW5mb3ZpcyKkAQoIR2VvbWV0cnkSDAoEZnJh",
            "bRgBIAEoBRIMCgRpZGVuGAIgASgDEgwKBHR5cGUYAyABKAUSDAoEbWFzaxgE",
            "IAEoBRIMCgRjbnRzGAUgAygFEgwKBHBvc3gYBiADKAESDAoEcG9zeRgHIAMo",
            "ARIMCgRwb3N6GAggAygBEgwKBHNpemUYCiABKAESDAoEY29schgLIAEoBxIM",
            "CgR0ZXh0GAwgASgJIksKB1JlcXVlc3QSDQoFcmVzZXQYASABKAgSIQoGdXBz",
            "ZXJ0GAIgAygLMhEuSW5mb3Zpcy5HZW9tZXRyeRIOCgZkZWxldGUYAyADKAMi",
            "FwoIUmVzcG9uc2USCwoDbG9nGAEgASgJQhOqAhBJbmZvdmlzLlByb3RvYnVm",
            "YgZwcm90bzM="));
      descriptor = pbr::FileDescriptor.FromGeneratedCode(descriptorData,
          new pbr::FileDescriptor[] { },
          new pbr::GeneratedClrTypeInfo(null, new pbr::GeneratedClrTypeInfo[] {
            new pbr::GeneratedClrTypeInfo(typeof(global::Infovis.Protobuf.Geometry), global::Infovis.Protobuf.Geometry.Parser, new[]{ "Fram", "Iden", "Type", "Mask", "Cnts", "Posx", "Posy", "Posz", "Size", "Colr", "Text" }, null, null, null),
            new pbr::GeneratedClrTypeInfo(typeof(global::Infovis.Protobuf.Request), global::Infovis.Protobuf.Request.Parser, new[]{ "Reset", "Upsert", "Delete" }, null, null, null),
            new pbr::GeneratedClrTypeInfo(typeof(global::Infovis.Protobuf.Response), global::Infovis.Protobuf.Response.Parser, new[]{ "Log" }, null, null, null)
          }));
    }
    #endregion

  }
  #region Messages
  public sealed partial class Geometry : pb::IMessage<Geometry> {
    private static readonly pb::MessageParser<Geometry> _parser = new pb::MessageParser<Geometry>(() => new Geometry());
    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public static pb::MessageParser<Geometry> Parser { get { return _parser; } }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public static pbr::MessageDescriptor Descriptor {
      get { return global::Infovis.Protobuf.InfovisReflection.Descriptor.MessageTypes[0]; }
    }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    pbr::MessageDescriptor pb::IMessage.Descriptor {
      get { return Descriptor; }
    }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public Geometry() {
      OnConstruction();
    }

    partial void OnConstruction();

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public Geometry(Geometry other) : this() {
      fram_ = other.fram_;
      iden_ = other.iden_;
      type_ = other.type_;
      mask_ = other.mask_;
      cnts_ = other.cnts_.Clone();
      posx_ = other.posx_.Clone();
      posy_ = other.posy_.Clone();
      posz_ = other.posz_.Clone();
      size_ = other.size_;
      colr_ = other.colr_;
      text_ = other.text_;
    }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public Geometry Clone() {
      return new Geometry(this);
    }

    /// <summary>Field number for the "fram" field.</summary>
    public const int FramFieldNumber = 1;
    private int fram_;
    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public int Fram {
      get { return fram_; }
      set {
        fram_ = value;
      }
    }

    /// <summary>Field number for the "iden" field.</summary>
    public const int IdenFieldNumber = 2;
    private long iden_;
    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public long Iden {
      get { return iden_; }
      set {
        iden_ = value;
      }
    }

    /// <summary>Field number for the "type" field.</summary>
    public const int TypeFieldNumber = 3;
    private int type_;
    /// <summary>
    /// 1 = points, 2 = polylines, 3 = rectangles, 4 = label, 5 = axis
    /// </summary>
    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public int Type {
      get { return type_; }
      set {
        type_ = value;
      }
    }

    /// <summary>Field number for the "mask" field.</summary>
    public const int MaskFieldNumber = 4;
    private int mask_;
    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public int Mask {
      get { return mask_; }
      set {
        mask_ = value;
      }
    }

    /// <summary>Field number for the "cnts" field.</summary>
    public const int CntsFieldNumber = 5;
    private static readonly pb::FieldCodec<int> _repeated_cnts_codec
        = pb::FieldCodec.ForInt32(42);
    private readonly pbc::RepeatedField<int> cnts_ = new pbc::RepeatedField<int>();
    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public pbc::RepeatedField<int> Cnts {
      get { return cnts_; }
    }

    /// <summary>Field number for the "posx" field.</summary>
    public const int PosxFieldNumber = 6;
    private static readonly pb::FieldCodec<double> _repeated_posx_codec
        = pb::FieldCodec.ForDouble(50);
    private readonly pbc::RepeatedField<double> posx_ = new pbc::RepeatedField<double>();
    /// <summary>
    /// mask = 0001b = 1
    /// </summary>
    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public pbc::RepeatedField<double> Posx {
      get { return posx_; }
    }

    /// <summary>Field number for the "posy" field.</summary>
    public const int PosyFieldNumber = 7;
    private static readonly pb::FieldCodec<double> _repeated_posy_codec
        = pb::FieldCodec.ForDouble(58);
    private readonly pbc::RepeatedField<double> posy_ = new pbc::RepeatedField<double>();
    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public pbc::RepeatedField<double> Posy {
      get { return posy_; }
    }

    /// <summary>Field number for the "posz" field.</summary>
    public const int PoszFieldNumber = 8;
    private static readonly pb::FieldCodec<double> _repeated_posz_codec
        = pb::FieldCodec.ForDouble(66);
    private readonly pbc::RepeatedField<double> posz_ = new pbc::RepeatedField<double>();
    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public pbc::RepeatedField<double> Posz {
      get { return posz_; }
    }

    /// <summary>Field number for the "size" field.</summary>
    public const int SizeFieldNumber = 10;
    private double size_;
    /// <summary>
    /// mask = 0100b = 2
    /// </summary>
    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public double Size {
      get { return size_; }
      set {
        size_ = value;
      }
    }

    /// <summary>Field number for the "colr" field.</summary>
    public const int ColrFieldNumber = 11;
    private uint colr_;
    /// <summary>
    /// mask = 1000b = 4
    /// </summary>
    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public uint Colr {
      get { return colr_; }
      set {
        colr_ = value;
      }
    }

    /// <summary>Field number for the "text" field.</summary>
    public const int TextFieldNumber = 12;
    private string text_ = "";
    /// <summary>
    /// mask = 0000b = 8
    /// </summary>
    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public string Text {
      get { return text_; }
      set {
        text_ = pb::ProtoPreconditions.CheckNotNull(value, "value");
      }
    }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public override bool Equals(object other) {
      return Equals(other as Geometry);
    }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public bool Equals(Geometry other) {
      if (ReferenceEquals(other, null)) {
        return false;
      }
      if (ReferenceEquals(other, this)) {
        return true;
      }
      if (Fram != other.Fram) return false;
      if (Iden != other.Iden) return false;
      if (Type != other.Type) return false;
      if (Mask != other.Mask) return false;
      if(!cnts_.Equals(other.cnts_)) return false;
      if(!posx_.Equals(other.posx_)) return false;
      if(!posy_.Equals(other.posy_)) return false;
      if(!posz_.Equals(other.posz_)) return false;
      if (Size != other.Size) return false;
      if (Colr != other.Colr) return false;
      if (Text != other.Text) return false;
      return true;
    }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public override int GetHashCode() {
      int hash = 1;
      if (Fram != 0) hash ^= Fram.GetHashCode();
      if (Iden != 0L) hash ^= Iden.GetHashCode();
      if (Type != 0) hash ^= Type.GetHashCode();
      if (Mask != 0) hash ^= Mask.GetHashCode();
      hash ^= cnts_.GetHashCode();
      hash ^= posx_.GetHashCode();
      hash ^= posy_.GetHashCode();
      hash ^= posz_.GetHashCode();
      if (Size != 0D) hash ^= Size.GetHashCode();
      if (Colr != 0) hash ^= Colr.GetHashCode();
      if (Text.Length != 0) hash ^= Text.GetHashCode();
      return hash;
    }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public override string ToString() {
      return pb::JsonFormatter.ToDiagnosticString(this);
    }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public void WriteTo(pb::CodedOutputStream output) {
      if (Fram != 0) {
        output.WriteRawTag(8);
        output.WriteInt32(Fram);
      }
      if (Iden != 0L) {
        output.WriteRawTag(16);
        output.WriteInt64(Iden);
      }
      if (Type != 0) {
        output.WriteRawTag(24);
        output.WriteInt32(Type);
      }
      if (Mask != 0) {
        output.WriteRawTag(32);
        output.WriteInt32(Mask);
      }
      cnts_.WriteTo(output, _repeated_cnts_codec);
      posx_.WriteTo(output, _repeated_posx_codec);
      posy_.WriteTo(output, _repeated_posy_codec);
      posz_.WriteTo(output, _repeated_posz_codec);
      if (Size != 0D) {
        output.WriteRawTag(81);
        output.WriteDouble(Size);
      }
      if (Colr != 0) {
        output.WriteRawTag(93);
        output.WriteFixed32(Colr);
      }
      if (Text.Length != 0) {
        output.WriteRawTag(98);
        output.WriteString(Text);
      }
    }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public int CalculateSize() {
      int size = 0;
      if (Fram != 0) {
        size += 1 + pb::CodedOutputStream.ComputeInt32Size(Fram);
      }
      if (Iden != 0L) {
        size += 1 + pb::CodedOutputStream.ComputeInt64Size(Iden);
      }
      if (Type != 0) {
        size += 1 + pb::CodedOutputStream.ComputeInt32Size(Type);
      }
      if (Mask != 0) {
        size += 1 + pb::CodedOutputStream.ComputeInt32Size(Mask);
      }
      size += cnts_.CalculateSize(_repeated_cnts_codec);
      size += posx_.CalculateSize(_repeated_posx_codec);
      size += posy_.CalculateSize(_repeated_posy_codec);
      size += posz_.CalculateSize(_repeated_posz_codec);
      if (Size != 0D) {
        size += 1 + 8;
      }
      if (Colr != 0) {
        size += 1 + 4;
      }
      if (Text.Length != 0) {
        size += 1 + pb::CodedOutputStream.ComputeStringSize(Text);
      }
      return size;
    }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public void MergeFrom(Geometry other) {
      if (other == null) {
        return;
      }
      if (other.Fram != 0) {
        Fram = other.Fram;
      }
      if (other.Iden != 0L) {
        Iden = other.Iden;
      }
      if (other.Type != 0) {
        Type = other.Type;
      }
      if (other.Mask != 0) {
        Mask = other.Mask;
      }
      cnts_.Add(other.cnts_);
      posx_.Add(other.posx_);
      posy_.Add(other.posy_);
      posz_.Add(other.posz_);
      if (other.Size != 0D) {
        Size = other.Size;
      }
      if (other.Colr != 0) {
        Colr = other.Colr;
      }
      if (other.Text.Length != 0) {
        Text = other.Text;
      }
    }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public void MergeFrom(pb::CodedInputStream input) {
      uint tag;
      while ((tag = input.ReadTag()) != 0) {
        switch(tag) {
          default:
            input.SkipLastField();
            break;
          case 8: {
            Fram = input.ReadInt32();
            break;
          }
          case 16: {
            Iden = input.ReadInt64();
            break;
          }
          case 24: {
            Type = input.ReadInt32();
            break;
          }
          case 32: {
            Mask = input.ReadInt32();
            break;
          }
          case 42:
          case 40: {
            cnts_.AddEntriesFrom(input, _repeated_cnts_codec);
            break;
          }
          case 50:
          case 49: {
            posx_.AddEntriesFrom(input, _repeated_posx_codec);
            break;
          }
          case 58:
          case 57: {
            posy_.AddEntriesFrom(input, _repeated_posy_codec);
            break;
          }
          case 66:
          case 65: {
            posz_.AddEntriesFrom(input, _repeated_posz_codec);
            break;
          }
          case 81: {
            Size = input.ReadDouble();
            break;
          }
          case 93: {
            Colr = input.ReadFixed32();
            break;
          }
          case 98: {
            Text = input.ReadString();
            break;
          }
        }
      }
    }

  }

  public sealed partial class Request : pb::IMessage<Request> {
    private static readonly pb::MessageParser<Request> _parser = new pb::MessageParser<Request>(() => new Request());
    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public static pb::MessageParser<Request> Parser { get { return _parser; } }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public static pbr::MessageDescriptor Descriptor {
      get { return global::Infovis.Protobuf.InfovisReflection.Descriptor.MessageTypes[1]; }
    }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    pbr::MessageDescriptor pb::IMessage.Descriptor {
      get { return Descriptor; }
    }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public Request() {
      OnConstruction();
    }

    partial void OnConstruction();

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public Request(Request other) : this() {
      reset_ = other.reset_;
      upsert_ = other.upsert_.Clone();
      delete_ = other.delete_.Clone();
    }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public Request Clone() {
      return new Request(this);
    }

    /// <summary>Field number for the "reset" field.</summary>
    public const int ResetFieldNumber = 1;
    private bool reset_;
    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public bool Reset {
      get { return reset_; }
      set {
        reset_ = value;
      }
    }

    /// <summary>Field number for the "upsert" field.</summary>
    public const int UpsertFieldNumber = 2;
    private static readonly pb::FieldCodec<global::Infovis.Protobuf.Geometry> _repeated_upsert_codec
        = pb::FieldCodec.ForMessage(18, global::Infovis.Protobuf.Geometry.Parser);
    private readonly pbc::RepeatedField<global::Infovis.Protobuf.Geometry> upsert_ = new pbc::RepeatedField<global::Infovis.Protobuf.Geometry>();
    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public pbc::RepeatedField<global::Infovis.Protobuf.Geometry> Upsert {
      get { return upsert_; }
    }

    /// <summary>Field number for the "delete" field.</summary>
    public const int DeleteFieldNumber = 3;
    private static readonly pb::FieldCodec<long> _repeated_delete_codec
        = pb::FieldCodec.ForInt64(26);
    private readonly pbc::RepeatedField<long> delete_ = new pbc::RepeatedField<long>();
    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public pbc::RepeatedField<long> Delete {
      get { return delete_; }
    }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public override bool Equals(object other) {
      return Equals(other as Request);
    }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public bool Equals(Request other) {
      if (ReferenceEquals(other, null)) {
        return false;
      }
      if (ReferenceEquals(other, this)) {
        return true;
      }
      if (Reset != other.Reset) return false;
      if(!upsert_.Equals(other.upsert_)) return false;
      if(!delete_.Equals(other.delete_)) return false;
      return true;
    }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public override int GetHashCode() {
      int hash = 1;
      if (Reset != false) hash ^= Reset.GetHashCode();
      hash ^= upsert_.GetHashCode();
      hash ^= delete_.GetHashCode();
      return hash;
    }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public override string ToString() {
      return pb::JsonFormatter.ToDiagnosticString(this);
    }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public void WriteTo(pb::CodedOutputStream output) {
      if (Reset != false) {
        output.WriteRawTag(8);
        output.WriteBool(Reset);
      }
      upsert_.WriteTo(output, _repeated_upsert_codec);
      delete_.WriteTo(output, _repeated_delete_codec);
    }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public int CalculateSize() {
      int size = 0;
      if (Reset != false) {
        size += 1 + 1;
      }
      size += upsert_.CalculateSize(_repeated_upsert_codec);
      size += delete_.CalculateSize(_repeated_delete_codec);
      return size;
    }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public void MergeFrom(Request other) {
      if (other == null) {
        return;
      }
      if (other.Reset != false) {
        Reset = other.Reset;
      }
      upsert_.Add(other.upsert_);
      delete_.Add(other.delete_);
    }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public void MergeFrom(pb::CodedInputStream input) {
      uint tag;
      while ((tag = input.ReadTag()) != 0) {
        switch(tag) {
          default:
            input.SkipLastField();
            break;
          case 8: {
            Reset = input.ReadBool();
            break;
          }
          case 18: {
            upsert_.AddEntriesFrom(input, _repeated_upsert_codec);
            break;
          }
          case 26:
          case 24: {
            delete_.AddEntriesFrom(input, _repeated_delete_codec);
            break;
          }
        }
      }
    }

  }

  public sealed partial class Response : pb::IMessage<Response> {
    private static readonly pb::MessageParser<Response> _parser = new pb::MessageParser<Response>(() => new Response());
    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public static pb::MessageParser<Response> Parser { get { return _parser; } }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public static pbr::MessageDescriptor Descriptor {
      get { return global::Infovis.Protobuf.InfovisReflection.Descriptor.MessageTypes[2]; }
    }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    pbr::MessageDescriptor pb::IMessage.Descriptor {
      get { return Descriptor; }
    }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public Response() {
      OnConstruction();
    }

    partial void OnConstruction();

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public Response(Response other) : this() {
      log_ = other.log_;
    }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public Response Clone() {
      return new Response(this);
    }

    /// <summary>Field number for the "log" field.</summary>
    public const int LogFieldNumber = 1;
    private string log_ = "";
    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public string Log {
      get { return log_; }
      set {
        log_ = pb::ProtoPreconditions.CheckNotNull(value, "value");
      }
    }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public override bool Equals(object other) {
      return Equals(other as Response);
    }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public bool Equals(Response other) {
      if (ReferenceEquals(other, null)) {
        return false;
      }
      if (ReferenceEquals(other, this)) {
        return true;
      }
      if (Log != other.Log) return false;
      return true;
    }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public override int GetHashCode() {
      int hash = 1;
      if (Log.Length != 0) hash ^= Log.GetHashCode();
      return hash;
    }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public override string ToString() {
      return pb::JsonFormatter.ToDiagnosticString(this);
    }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public void WriteTo(pb::CodedOutputStream output) {
      if (Log.Length != 0) {
        output.WriteRawTag(10);
        output.WriteString(Log);
      }
    }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public int CalculateSize() {
      int size = 0;
      if (Log.Length != 0) {
        size += 1 + pb::CodedOutputStream.ComputeStringSize(Log);
      }
      return size;
    }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public void MergeFrom(Response other) {
      if (other == null) {
        return;
      }
      if (other.Log.Length != 0) {
        Log = other.Log;
      }
    }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    public void MergeFrom(pb::CodedInputStream input) {
      uint tag;
      while ((tag = input.ReadTag()) != 0) {
        switch(tag) {
          default:
            input.SkipLastField();
            break;
          case 10: {
            Log = input.ReadString();
            break;
          }
        }
      }
    }

  }

  #endregion

}

#endregion Designer generated code
