EMACS ?= emacs
PYTHON ?= python3

.PHONY: test test-python test-emacs compile demo clean

test: test-python test-emacs

test-python:
	$(PYTHON) -m unittest discover -s test -p 'test_*.py' -v

test-emacs:
	ORG_REASON_TEST_PYTHON="$(PYTHON)" $(EMACS) -Q --batch --eval '(setq load-prefer-newer t)' -L . -l test/org-reason-tests.el -f ert-run-tests-batch-and-exit

# The package's own files, not the ones package-vc generates in a clone.
ELISP = $(filter-out %-pkg.el %-autoloads.el,$(wildcard org-reason*.el))

# Compiles to .elc beside the sources; `make clean` removes them again.
compile:
	$(EMACS) -Q --batch --eval '(setq load-prefer-newer t byte-compile-error-on-warn t)' -L . -f batch-byte-compile $(ELISP)

# The tutorial on fictional data, in ~/.emacs.d/org-reason-demo/ (C-c r h does the same).
demo:
	$(EMACS) -Q --eval '(setq load-prefer-newer t)' -L . -l org-reason-demo

clean:
	rm -f *.elc test/*.elc
