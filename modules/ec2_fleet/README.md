# EC2 Fleet Module

Provisions heterogeneous EC2 instances from **one input map** using `for_each`.

## Why two `aws_instance` resources?

Terraform `lifecycle.prevent_destroy` cannot be conditional per `for_each` key. Protected instances (`protected = true`) use a second resource with `prevent_destroy`. Both are still driven by the same map — the assignment’s “single input variable” requirement is preserved.

## Validations

- At least one `io1`/`io2` root volume (with `root_iops`)
- At least one protected instance
- No `sc1`/`st1` root volumes (not bootable in AWS)
- Distinct `instance_type`, `root_volume_type`, `root_volume_size`, and `key_name`

## Scaling note

For cattle (hundreds of identical nodes), prefer `modules/asg_service` rather than growing this inventory indefinitely.
