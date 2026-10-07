import RompatcherDX

namespace RompatcherDX.formats.ips.codec

/-- A successful encoding decodes back to the same IPS contents. -/
private theorem decode_of_encode
    (contents : PatchContents) (patch : Aeneas.Std.alloc.vec.Vec Aeneas.Std.U8)
    (encoded : encode contents = .ok (.Ok patch)) :
    decode (Aeneas.Std.alloc.vec.Vec.deref patch) = .ok (.Ok contents) := by
  sorry

/-- Every successfully decoded IPS patch re-encodes to its original bytes. -/
private theorem encode_of_decode
    (contents : PatchContents) (patch : Aeneas.Std.alloc.vec.Vec Aeneas.Std.U8)
    (decoded : decode (Aeneas.Std.alloc.vec.Vec.deref patch) = .ok (.Ok contents)) :
    encode contents = .ok (.Ok patch) := by
  sorry

/-- IPS encoding succeeds with `patch` exactly when decoding `patch` yields `contents`. -/
theorem encode_eq_ok_iff_decode_eq_ok
    (contents : PatchContents) (patch : Aeneas.Std.alloc.vec.Vec Aeneas.Std.U8) :
    encode contents = .ok (.Ok patch) ↔
      decode (Aeneas.Std.alloc.vec.Vec.deref patch) = .ok (.Ok contents) := by
  constructor
  · exact decode_of_encode contents patch
  · exact encode_of_decode contents patch

end RompatcherDX.formats.ips.codec
