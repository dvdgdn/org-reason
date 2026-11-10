EMACS ?= emacs
PYTHON ?= python3

.PHONY: test test-python test-emacs compile demo clean

test: test-python test-emacs

test-python:
	$(PYTHON) -m unittest discover -s test -p 'test_*.py' -v

test-emacs:
	ORG_REASON_TEST_PYTHON="$(PYTHON)" $(EMACS) -Q --batch -L . -l test/org-reason-tests.el -f ert-run-tests-batch-and-exit

# Compiles to .elc beside the sources; `make clean` removes them again.
compile:
	$(EMACS) -Q --batch -L . --eval '(setq byte-compile-error-on-warn t)' -f batch-byte-compile org-reason*.el

# The tutorial on fictional data, in ~/.emacs.d/org-reason-demo/ (C-c r h does the same).
demo:
	$(EMACS) -Q -L . -l org-reason-demo

clean:
	rm -f *.elc test/*.elc
