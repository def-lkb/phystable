#include <caml/mlvalues.h>

extern intnat
     caml_stat_minor_collections,
     caml_stat_major_collections,
     caml_stat_heap_wsz,
     caml_stat_top_heap_wsz,
     caml_stat_compactions,
     caml_stat_heap_chunks;

value ml_caml_stat_minor_collections(value unit)
{
  (void)unit;
  return Val_int(caml_stat_minor_collections);
}

value ml_caml_stat_compactions(value unit)
{
  (void)unit;
  return Val_int(caml_stat_compactions);
}

extern value *caml_young_start, *caml_young_end;

#define Is_young(val) \
  ((void*)(val) < (void*)caml_young_end && (void*)(val) > (void*)caml_young_start)

value ml_caml_is_young(value obj)
{
  return Val_bool(Is_block(obj) && Is_young(obj));
}

