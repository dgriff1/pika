SIBLING_CODEGEN_DIR=../rabbitmq-codegen/
AMQP_CODEGEN_DIR=$(shell [ -d $(SIBLING_CODEGEN_DIR) ] && echo $(SIBLING_CODEGEN_DIR) || echo codegen)
AMQP_SPEC_JSON_FILES=$(AMQP_CODEGEN_DIR)/amqp-rabbitmq-0.9.1.json

ifeq ($(shell python -c 'import simplejson' 2>/dev/null && echo yes),yes)
PYTHON=python
else
ifeq ($(shell python2.6 -c 'import simplejson' 2>/dev/null && echo yes),yes)
PYTHON=python2.6
else
ifeq ($(shell python2.5 -c 'import simplejson' 2>/dev/null && echo yes),yes)
PYTHON=python2.5
else
# Hmm. Missing simplejson?
PYTHON=python
endif
endif
endif

all: pika/spec.py test documentation

pika/spec.py: codegen.py $(AMQP_CODEGEN_DIR)/amqp_codegen.py $(AMQP_SPEC_JSON_FILES)
	$(PYTHON) codegen.py spec $(AMQP_SPEC_JSON_FILES) $@

# For dev work, when working from a git checkout
codegen/amqp_codegen.py:
	if [ -d codegen ]; then rmdir codegen; else true; fi
	curl http://hg.rabbitmq.com/rabbitmq-codegen/archive/default.tar.bz2 | tar -jxvf -
	mv rabbitmq-codegen-default codegen

regenclean: clean
	rm -f pika/spec.py

distclean: clean
	rm -rf codegen

clean:
	rm -f pika/*.pyc
	rm -f tests/*.pyc tests/functional/*.pyc tests/unit/*.pyc
	rm -f examples/*.pyc examples/blocking/*.pyc
	$(MAKE) -C docs clean

# For building a releasable tarball
codegen:
	mkdir -p $@
	cp -r "$(AMQP_CODEGEN_DIR)"/* $@
	$(MAKE) -C $@ clean

test: pep8
	cd tests && $(PYTHON) run_tests.py

pep8:
	pep8 --ignore=E501 --statistics --count -r codegen.py pika/spec.py tests/unit/table_test.py
	pep8 --exclude=spec.py,table_test.py --statistics --count -r pika examples tests

documentation:
	$(MAKE) -C docs html

push_documentation: documentation
	git commit docs
	git clone git@github.com:tonyg/pika.git -b gh-pages gh-pages
	cd gh-pages && git rm -rf *
	cp -R docs/_build/html/* gh-pages
	cd gh-pages && git add -A
	cd gh-pages && git commit -m 'Update documentation from master' -a
	cd gh-pages && git push
	rm -rf gh-pages
