PROGRAMS=org-tangle org-weave
TARGETS=$(PROGRAMS) README.md org-tangle.md org-weave.md

all: $(TARGETS)

%: %.org
	./org-tangle -l emacs-lisp,org $<

%.md: %.org
	./org-weave -f gfm -O '-Q --batch -L ~/.emacs.d/local-packages' $< > $@

DESTDIR=/home/soft/bin
install: all
	install -m 755 $(PROGRAMS) $(DESTDIR)
