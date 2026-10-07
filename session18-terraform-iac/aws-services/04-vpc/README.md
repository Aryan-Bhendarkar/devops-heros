# 04. VPC: Virtual Private Cloud (Networking)

## What is a VPC?
A VPC is your own **logically isolated private network** inside AWS. You choose its IP range, split it into subnets, control routing and decide what is reachable from the internet. EC2, RDS, load balancers and most other resources are launched *inside* a VPC. A VPC belongs to one region and spans all its Availability Zones.

```text
Region
└── VPC 10.0.0.0/16
    ├── Public subnet  10.0.1.0/24 (AZ-a) ── route: 0.0.0.0/0 → Internet Gateway
    └── Private subnet 10.0.2.0/24 (AZ-a) ── route: 0.0.0.0/0 → NAT Gateway
```

## CIDR
**CIDR** notation describes an IP range as `address/prefix`. The prefix is how many bits are fixed. Bigger prefix = fewer addresses.

| CIDR | Addresses | Typical use |
| :--- | :--- | :--- |
| `10.0.0.0/16` | 65,536 | A whole VPC |
| `10.0.1.0/24` | 256 | One subnet (AWS reserves 5 addresses per subnet, so 251 usable) |
| `10.0.1.5/32` | 1 | A single IP (used in firewall rules) |

Use private ranges (`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`), and don't let VPC ranges overlap if you plan to connect them.

## Subnets
A subnet is a **slice of the VPC's range inside one Availability Zone**. Resources in a subnet get IPs from its CIDR. Use several subnets across AZs for high availability.

## Route tables
Rules that decide where network traffic goes. Each subnet is associated with one route table. Every table has a `local` route (traffic within the VPC). Example routes:
```text
10.0.0.0/16   → local
0.0.0.0/0     → igw-xxxx     (public subnet: internet via Internet Gateway)
0.0.0.0/0     → nat-xxxx     (private subnet: outbound-only internet via NAT)
```

## Internet Gateway (IGW)
A horizontally scaled gateway attached to the VPC that allows **two-way** traffic between the VPC and the internet. A subnet is "public" when its route table sends `0.0.0.0/0` to an IGW *and* the instance has a public IP.

## NAT Gateway
Lets instances in a **private subnet reach the internet outbound** (for updates, API calls) **without being reachable from the internet**. It sits in a *public* subnet with an Elastic IP. It is billed hourly plus per GB, so it's a common source of surprise bills.

## Security Groups vs Network ACLs
| | Security Group | Network ACL |
| :--- | :--- | :--- |
| Level | Instance (network interface) | Subnet |
| State | **Stateful**: return traffic automatically allowed | **Stateless**: need rules for both directions |
| Rules | Allow only | Allow and Deny, evaluated in number order |
| Default | Deny inbound, allow outbound | Default NACL allows all |
| Use | Primary day-to-day firewall | Extra subnet-level guard, blocking specific IPs |

## Public vs private subnet
| | Public subnet | Private subnet |
| :--- | :--- | :--- |
| Route to internet | Via Internet Gateway | None, or via NAT Gateway (outbound only) |
| Instances have public IP | Yes (if assigned) | No |
| Typical contents | Load balancers, bastion hosts, web servers | Application servers, databases |

Common pattern: load balancer in public subnets, application and database in private subnets.

## Other related pieces
- **VPC endpoints:** reach AWS services (like S3) privately without the internet.
- **VPC peering / Transit Gateway:** connect VPCs together.
- **VPN / Direct Connect:** connect to an on-premises network.
- **Flow logs:** record network traffic for troubleshooting.
