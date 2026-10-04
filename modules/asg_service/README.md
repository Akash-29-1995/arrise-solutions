# Auto Scaling Service Module

This module is an architectural extension for production-style compute.

The assignment asks for five individually configured EC2 instances, so `modules/ec2_fleet` is the required implementation. If the real requirement becomes hundreds of similar application servers, I would use this pattern instead:

- Launch Template for immutable instance configuration.
- Auto Scaling Group spread across multiple subnets/AZs.
- ELB health checks when target groups are attached.
- Rolling instance refresh when AMI, user data, or launch template changes.
- Target tracking scaling for CPU-based capacity adjustment.

This provides self-healing because unhealthy instances are replaced automatically, and scaling because capacity is controlled by min/desired/max values rather than manually adding EC2 resources.

