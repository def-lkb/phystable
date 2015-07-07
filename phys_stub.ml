external caml_stat_minor_collections : unit -> int =
  "ml_caml_stat_minor_collections"
  "ml_caml_stat_minor_collections"
  "noalloc"

external caml_stat_compactions : unit -> int =
  "ml_caml_stat_compactions"
  "ml_caml_stat_compactions"
  "noalloc"

external caml_is_young : Obj.t -> bool =
  "ml_caml_is_young"
  "ml_caml_is_young"
  "noalloc"
