# Committed sandbox profile — safe defaults for a reviewer AWS sandbox account.
# scripts/sandbox-up.sh layers a unique name_prefix on top so concurrent runs
# in a shared account do not collide on IAM role/user names.

aws_region  = "ap-south-1"
environment = "sandbox"
owner       = "reviewer"
tenant      = "sandbox"
project     = "arrise-devops-assignment"

# Single-account mode: leave account IDs / deploy roles unset.
# Ambient AWS credentials are used (no assume_role).

enable_iam = true
enable_ec2 = false

use_default_vpc               = true
manage_key_pairs              = true
generate_ssh_key              = true
force_destroy_iam_users       = true
create_console_login_profiles = false
create_role_c_bucket          = true

# Used only when SANDBOX_WITH_EC2=1
instance_inventory_file = "inventory/dev-instances-cheap.yaml"
