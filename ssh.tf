# Sandbox ergonomics: generate a throwaway key when the reviewer did not supply one.
# Production / assignment demos should pass ssh_public_key explicitly.
resource "tls_private_key" "fleet" {
  count = var.enable_ec2 && var.manage_key_pairs && var.generate_ssh_key && trimspace(var.ssh_public_key) == "" ? 1 : 0

  algorithm = "ED25519"
}

locals {
  effective_ssh_public_key = trimspace(var.ssh_public_key) != "" ? var.ssh_public_key : try(tls_private_key.fleet[0].public_key_openssh, "")
}
