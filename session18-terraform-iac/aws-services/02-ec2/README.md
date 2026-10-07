# 02. EC2: Elastic Compute Cloud (Compute)

## What is EC2?
EC2 provides **virtual servers (instances) in the cloud**. You choose the operating system, CPU, memory, storage and networking, launch in minutes, and pay only for the time the instance runs (per second for most Linux instances). It is the basic "rent a computer" service of AWS.

```text
AMI (template) + Instance type (size) + Key pair (login) + Security group (firewall) + EBS (disk)  =  EC2 instance
```

## Key concepts

### AMI: Amazon Machine Image
A template containing the OS and (optionally) software used to launch an instance, e.g. Amazon Linux, Ubuntu, Windows. You can create your own AMI from a configured instance to launch identical copies.

### Instance types
The "size" of the server, named like `t3.micro`: **family** (`t` = general purpose burstable, `m` = general, `c` = compute-optimized, `r` = memory-optimized, `g`/`p` = GPU), **generation** (`3`) and **size** (`micro`, `small`, `large`...). `t2.micro`/`t3.micro` are in the free tier for eligible accounts.

### Key pairs
A public/private key pair used to log in securely over **SSH** (Linux) or to decrypt the Windows admin password. AWS stores the public key; you keep the private `.pem` file, which can't be downloaded again. Never share it or commit it to git.
```bash
ssh -i mykey.pem ec2-user@<public-ip>
```

### Security groups
A **virtual firewall attached to the instance**. It has inbound rules (what may reach the instance) and outbound rules. It is **stateful** (return traffic is automatically allowed) and works with **allow rules only**. Default: all inbound blocked, all outbound allowed.
Example: allow SSH (22) from your IP only, and HTTP (80) from anywhere.

### EBS: Elastic Block Store
Network-attached **persistent disks** for instances. The root volume holds the OS; extra volumes can be attached. Data survives a stop/start. Volumes live in one Availability Zone, can be backed up as **snapshots** (stored in S3), and come in types such as `gp3` (general SSD) and `io2` (high IOPS). By default the root volume is deleted when the instance is terminated. *Instance store* is faster temporary storage that is lost when the instance stops.

### Public vs private IP
| | Private IP | Public IP |
| :--- | :--- | :--- |
| Reachable from | Inside the VPC only | The internet |
| Changes on stop/start? | No (stays the same) | Yes, unless you use an **Elastic IP** |
| Used for | Server-to-server traffic | SSH, serving websites |

An **Elastic IP** is a static public IPv4 address you own until you release it.

### Instance lifecycle
```text
pending → running ⇄ stopping → stopped → (start again → pending → running)
                 └→ shutting-down → terminated   (deleted, cannot come back)
```
- **Stop:** the instance shuts down, no compute charge, EBS keeps data (EBS storage is still billed).
- **Terminate:** the instance is deleted permanently.
- **Reboot:** restarts the OS and keeps the instance and its IPs.
- **Hibernate:** saves RAM to disk and resumes later.

Purchasing options: **On-Demand**, **Reserved/Savings Plans** (commitment discount), **Spot** (spare capacity, cheapest, can be interrupted).

## Common use cases
- Hosting websites and web applications or APIs.
- Running backend services, batch jobs and CI/CD build agents.
- Databases you manage yourself, or dev/test environments.
- Scaling groups of servers with Auto Scaling behind a load balancer.

## Launch from the CLI
```bash
aws ec2 run-instances --image-id <ami-id> --instance-type t3.micro --key-name mykey --security-group-ids <sg-id>
aws ec2 describe-instances
aws ec2 stop-instances --instance-ids <id>
aws ec2 terminate-instances --instance-ids <id>
```
