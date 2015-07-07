external collections : unit -> int =
  "ml_caml_stat_minor_collections"
  "ml_caml_stat_minor_collections"
  "noalloc"

external compactions : unit -> int =
  "ml_caml_stat_compactions"
  "ml_caml_stat_compactions"
  "noalloc"

type (_, _) t = {
  mutable compactions: int;
  mutable collections: int;

  mutable major_order: int;
  mutable major_fill: int;
  mutable major: Obj.t array;
  mutable major_values: Obj.t array;

  mutable minor_order: int;
  mutable minor_fill: int;
  mutable minor: Obj.t array;
  mutable minor_values: Obj.t array;
}

let hash (n : Obj.t) =
  let n : int = Obj.obj n in
  (n + 15485863) * 2654435761

let null = Obj.repr (ref ())

let create () =
  let major = [||] in
  let minor = Array.make 16 null in
  let major_values = [||] in
  let minor_values = Array.make 16 null in
  let t = {
    compactions =  0 ; collections = 0;
    major_order = -1 ; minor_order = 4;
    major_fill  =  0 ; minor_fill  = 0;
    major            ; minor;
    major_values     ; minor_values;
  } in
  t.compactions <- compactions ();
  t.collections <- collections ();
  t

let is_full sz order = sz * 4 > 1 lsl order * 3

let rec next_order sz order =
  if is_full sz order
  then next_order sz (order + 1)
  else order

let flip x = - x - 1

let rec find arr obj mask i =
  let i = i land mask in
  let obj' = Array.unsafe_get arr i in
  if obj' == obj then
    i
  else if obj' == null then
    flip i
  else
    find arr obj mask (i + 1)

let rehash_major t sz =
  let order = next_order sz t.major_order in
  let sz = 1 lsl order in
  let major = Array.make sz null in
  let major_values = Array.make sz null in
  for i = 0 to 1 lsl t.major_order - 1 do
    let obj = Array.unsafe_get t.major i in
    if obj != null then
      let x = find major obj (sz - 1) (hash obj) in
      if x < 0 then
        (Array.unsafe_set major (flip x) obj;
         Array.unsafe_set major_values (flip x)
           (Array.unsafe_get t.major_values (flip x)))
  done;
  t.major_order <- order;
  t.major <- major

let prepare t =
  let minor = t.minor and minor_values = t.minor_values in
  let minor_full =
    not (t.collections <> collections ()) &&
    is_full t.minor_fill t.minor_order
  in
  if minor_full then begin
    t.minor_order <- t.minor_order + 1;
    t.minor <- Array.make (1 lsl t.minor_order) null;
    t.minor_values <- Array.make (1 lsl t.minor_order) null;
  end;
  if t.compactions <> compactions () then begin
    rehash_major t (t.major_fill + t.minor_fill);
    t.compactions <- compactions ();
  end;
  if t.collections <> collections () && t.minor_fill > 0 then begin
    let major_mask = 1 lsl t.major_order - 1 in
    for i = 0 to 1 lsl t.minor_order - 1 do
      let obj = Array.unsafe_get minor i in
      let obj_v = Array.unsafe_get minor_values i in
      Array.unsafe_set minor i null;
      Array.unsafe_set minor_values i null;
      if obj != null then
        let x = find t.major obj major_mask (hash obj) in
        if x < 0 then
          (Array.unsafe_set t.major (flip x) obj;
           Array.unsafe_set t.major_values (flip x) obj_v)
        else
          Array.unsafe_set t.major_values x obj_v
    done;
    t.major_fill <- t.major_fill + t.minor_fill;
    t.minor_fill <- 0;
  end;
  t.collections <- collections ()

let mem (t : ('a, _) t) (obj : 'a) =
  let obj = Obj.repr obj in
  prepare t;
  let h = hash obj in
  (find t.minor obj (1 lsl t.minor_order - 1) h >= 0) ||
  (t.major_order >= 0 &&
   (find t.major obj (1 lsl t.major_order - 1) h >= 0))

let add (t : ('a,'b) t) (obj : 'a) (v : 'b) =
  let obj = Obj.repr obj and v = Obj.repr v in
  prepare t;
  let h = hash obj in
  let x = find t.minor obj (1 lsl t.minor_order - 1) h in
  if x >= 0 then
    t.minor_values.(x) <- v
  else
    let x = flip x in
    t.minor_fill <- t.minor_fill + 1;
    t.minor.(x) <- obj;
    t.minor_values.(x) <- v

let find (t : ('a, _) t) (obj : 'a) =
  let obj = Obj.repr obj in
  prepare t;
  let h = hash obj in
  let x = find t.minor obj (1 lsl t.minor_order - 1) h in
  if x > 0 then t.minor_values.(x)
  else if t.major_order >= 0 then
    let x = find t.major obj (1 lsl t.major_order - 1) h in
    if x >= 0 then
      t.major_values.(x)
    else
      raise Not_found
  else
    raise Not_found
