TERRAFORM_REQUIRED_VERSION := 1.2.1
TERRAFORM_INSTALLED_VERSION := $(shell terraform version 2>/dev/null | perl -n -e 'print $$1 if /Terraform v(\d+.\d+.\d+)/')
MODULE_NAME := $(basename $(pwd))

define README_MD
# ${MODULE_NAME}

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
endef

all: validate docs

tfenv:
	if [ "${TERRAFORM_REQUIRED_VERSION}" != "${TERRAFORM_INSTALLED_VERSION}" ] && command -v tfenv > /dev/null ; then tfenv install ${TERRAFORM_REQUIRED_VERSION} && tfenv use ${TERRAFORM_REQUIRED_VERSION}; fi


all: validate docs

validate: tfenv
	terraform init --upgrade
	terraform fmt
	terraform validate

version_check:
	echo ${TERRAFORM_INSTALLED_VERSION}

export README_MD
README.md:
	echo "$$README_MD" >> $@

docs: README.md
	terraform-docs markdown table --output-file $< .

test: validate
	./az-login.sh
	(cd tests ; go mod download ; go test -v -timeout 60m)

entr:
	find . -name '*.tf' -o -name '*.tfvars' -o -name '*.hcl' -o -name '*.md' | entr -c make

clean:
	find . -type d -name ".terragrunt-cache" -prune -exec rm -rf {} \;
	find . -type d -name ".terraform" -prune -exec rm -rf {} \;
	find . -type f -name .terraform.lock.hcl -delete


install_tools_macos:
	brew install entr
	brew install tfenv
	brew install golang
	brew install terraform-docs
