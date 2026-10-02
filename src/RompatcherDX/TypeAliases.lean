/-!
# ROM and patch types

This module names the byte arrays used by the library for ROMs and patches.
-/

namespace RompatcherDX

/-- The binary representation of a patch. -/
abbrev Patch := ByteArray
/-- The binary representation of a ROM. -/
abbrev ROM := ByteArray

end RompatcherDX
