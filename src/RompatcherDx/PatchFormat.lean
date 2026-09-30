namespace RompatcherDx

inductive PatchFormat where
  | ips
  | bps
  | ppf
  | ups
  | aps
  | rup
  | ebp

def PatchFormat.parse? (name : String) : Option PatchFormat :=
  match name.toLower with
  | "ips" => some .ips
  | "bps" => some .bps
  | "ppf" => some .ppf
  | "ups" => some .ups
  | "aps" => some .aps
  | "rup" => some .rup
  | "ebp" => some .ebp
  | _ => none

end RompatcherDx
