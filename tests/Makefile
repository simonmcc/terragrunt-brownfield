# Sync with axon-kubetools-slim:20220726.15, which has Terraform 1.2.1
TERRAFORM_REQUIRED_VERSION := 1.2.1
TERRAGRUNT_REQUIRED_VERSION := 0.38.12
TERRAFORM_INSTALLED_VERSION := $(shell terraform version 2>/dev/null | perl -n -e 'print $$1 if /Terraform v(\d+.\d+.\d+)/')
TERRAGRUNT_INSTALLED_VERSION := $(shell terragrunt --version 2>/dev/null | perl -n -e 'print $$1 if /Terraform v(\d+.\d+.\d+)/')

all: test

tfenv:
	if [ "${TERRAFORM_REQUIRED_VERSION}" != "${TERRAFORM_INSTALLED_VERSION}" ] && command -v tfenv > /dev/null ; then tfenv install ${TERRAFORM_REQUIRED_VERSION} && tfenv use ${TERRAFORM_REQUIRED_VERSION}; fi

tgenv:
	if [ "${TERRAGRUNT_REQUIRED_VERSION}" != "${TERRAGRUNT_INSTALLED_VERSION}" ] && command -v tgenv > /dev/null ; then tgenv install ${TERRAGRUNT_REQUIRED_VERSION} && tgenv use ${TERRAGRUNT_REQUIRED_VERSION}; fi

all: fmt test

fmt: tfenv tgenv
	terraform fmt -recursive
	terragrunt hclfmt

version_check:
	echo ${TERRAFORM_INSTALLED_VERSION}

test: fmt
	go mod download
	go test -v -timeout 60m

entr:
	find . -name '*.tf' -o -name '*.tfvars' -o -name '*.hcl' -o -name '*.md' | entr -c make

clean:
	find . -type f -name .terraform.lock.hcl -delete
	find . -type d -name .terraform -delete
	find . -type d -name ".terragrunt-cache" -prune -exec rm -rf {} \;


install_tools_macos:
	brew install entr
	brew install tfenv tgenv
	brew install golang
