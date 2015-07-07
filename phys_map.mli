type ('a, 'b) t
val create : unit -> ('a, 'b) t
val add : ('a, 'b) t -> 'a -> 'b -> unit
val mem : ('a, 'b) t -> 'a -> bool
val find : ('a, 'b) t -> 'a -> 'b
