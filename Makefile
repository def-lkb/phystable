all: phys_stub.cma phys_stub.cmxa

ml_phys_stub.o: ml_phys_stub.c
	ocamlc -c -ccopt "-O2 -std=gnu99" $<

dll_phys_stub_stubs.so lib_phys_stub_stubs.a: ml_phys_stub.o
	ocamlmklib \
	    -o _phys_stub_stubs $< \
	    -ccopt -O2 -ccopt -std=gnu99

phys_stub.cmi: phys_stub.mli
	ocamlc -c $<

phys_stub.cmo: phys_stub.ml phys_stub.cmi
	ocamlc -c $<

phys_stub.cma: phys_stub.cmo dll_phys_stub_stubs.so
	ocamlc -a -custom -o $@ $< \
	       -dllib dll_phys_stub_stubs.so \
	       -cclib -l_phys_stub_stubs

phys_stub.cmx: phys_stub.ml phys_stub.cmi
	ocamlopt -c $<

phys_stub.cmxa phys_stub.a: phys_stub.cmx dll_phys_stub_stubs.so
	ocamlopt -a -o $@ $< \
	      -cclib -l_phys_stub \
	  		-ccopt -O2 -ccopt -std=gnu99

.PHONY: clean install uninstall reinstall

clean:
	rm -f *.[oa] *.so *.cm[ixoa] *.cmxa

DIST_FILES=              \
	phys_stub.a            \
	phys_stub.cmi          \
	phys_stub.cmo          \
	phys_stub.cma          \
	phys_stub.cmx          \
	phys_stub.cmxa         \
	lib_phys_stub_stubs.a  \
	dll_phys_stub_stubs.so

install: $(DIST_FILES) META
	ocamlfind install phys_stub $^

uninstall:
	ocamlfind remove phys_stub

reinstall:
	-$(MAKE) uninstall
	$(MAKE) install
