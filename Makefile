VENV=rep_localstack
PATH := $(CURDIR)/$(VENV)/bin:$(PATH)

export AWS_ACCESS_KEY_ID ?= test
export AWS_SECRET_ACCESS_KEY ?= test
export AWS_DEFAULT_REGION ?= us-east-1

init:
	python3 -m venv $(VENV)
	$(VENV)/bin/python3 -m pip install --upgrade pip
	$(VENV)/bin/python3 -m pip install localstack awscli awscli-local

auth:
	$(VENV)/bin/localstack auth set-token "$(TOKEN)"

start:
	$(VENV)/bin/localstack start -d

status:
	$(VENV)/bin/localstack status services
	curl -s http://localhost:4566/_localstack/health

deploy:
	./scripts/deploy.sh

test:
	./scripts/test_api.sh

stop:
	$(VENV)/bin/localstack stop

clean:
	rm -f function.zip response.json trust-policy.json .localstack-tp.env
