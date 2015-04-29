SANDBOX := ./sandbox

.PHONY: symbols

all: elc package

clean: clean-elc clean-package clean-sandbox

test:
	emacs -mm tests.v

test24:
	emacs24 -mm tests.v

elc:
	emacs --batch -L . --script ~/.emacs -f batch-byte-compile *.el

clean-elc:
	rm -rf *.elc

package-name:
	$(eval PKG := company-coq-$(shell sed -n -e 's/.*"\(.*\)".*/\1/' -e 3p company-coq-pkg.el))

package: clean-package package-name
	mkdir -p build/$(PKG)
	cp -R *.el refman build/$(PKG)
	cd build && tar -cf $(PKG).tar $(PKG)

clean-package:
	rm -rf build

install:
	emacs \
		-l package \
		--eval "(add-to-list 'package-archives '(\"melpa\" . \"http://melpa.org/packages/\") t)" \
		--eval "(package-refresh-contents)" \
		--eval "(package-initialize)" \
		--eval "(package-install-file \"build/$(PKG).tar\")"

sandbox: clean-sandbox package
	mkdir -p $(SANDBOX)

	emacs24 -Q \
		--eval '(setq user-emacs-directory "$(SANDBOX)")' \
		-L "~/.emacs.d/lisp/ProofGeneral/generic/" \
		-l package \
		-l proof-site \
		--eval "(setq garbage-collection-messages t)" \
		--eval "(add-to-list 'package-archives '(\"gnu\" . \"http://elpa.gnu.org/packages/\") t)" \
		--eval "(add-to-list 'package-archives '(\"melpa\" . \"http://melpa.org/packages/\") t)" \
		--eval "(package-refresh-contents)" \
		--eval "(package-initialize)" \
		--eval "(package-install-file \"build/$(PKG).tar\")"

clean-sandbox:
	rm -rf $(SANDBOX)

etc: clean-etc
	cd /build/coq/ && make doc-html
	rm -f refman/
	./parse-hevea.py refman/ ./company-coq-abbrev.el.template /build/coq/doc/refman/html/Reference-Manual*.html
	parallel -j8 gzip -9 -- refman/*.html

clean-etc:
	rm -rf refman/

deep-clean: clean clean-etc
	cd /build/coq/ && make docclean

ack:
	cd refman && ack "hevea_quickhelp.*" -o | cut -c -80

symbols:
	awk -F'\\s+' -v NL=$$(wc -l < etc/symbols) -f etc/symbols.awk < etc/symbols
