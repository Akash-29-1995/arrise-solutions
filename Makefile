.PHONY: fmt validate reviewer-validate verify sandbox-up sandbox-down preflight help

help:
	@echo "Reviewer commands:"
	@echo "  make reviewer-validate   Offline fmt/validate + assignment contracts"
	@echo "  make sandbox-up          Apply IAM sandbox in your AWS account"
	@echo "  make sandbox-down        Destroy that sandbox"
	@echo "  SANDBOX_WITH_EC2=1 make sandbox-up"
	@echo "  SANDBOX_AUTO_APPROVE=1 make sandbox-up"

fmt:
	terraform fmt -recursive

verify:
	./scripts/verify-requirements.sh

preflight:
	./scripts/preflight.sh offline

validate:
	terraform init -backend=false -input=false
	terraform validate
	terraform -chdir=bootstrap/remote-state init -backend=false -input=false
	terraform -chdir=bootstrap/remote-state validate

reviewer-validate:
	./scripts/reviewer-validate.sh

sandbox-up:
	./scripts/sandbox-up.sh

sandbox-down:
	./scripts/sandbox-down.sh
