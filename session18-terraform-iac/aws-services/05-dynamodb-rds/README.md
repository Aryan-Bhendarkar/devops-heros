# 05. DynamoDB & RDS: Database Services

AWS offers managed databases so you don't patch servers or run backups yourself. The two classic choices are **DynamoDB** (NoSQL, key-value/document) and **RDS** (managed relational SQL).

---

## Part A: DynamoDB

### What is it?
A fully managed, serverless **NoSQL** database with single-digit-millisecond performance at any scale. There are no servers to manage and no fixed schema, and it scales automatically. It is built for key-based access, not complex joins.

### NoSQL
"Not only SQL": non-relational data models (key-value, document, graph...). Data is usually accessed by key, so it scales horizontally by spreading data across many partitions. Trade-off: no joins and limited ad-hoc queries compared with SQL.

### Data model
| Term | Meaning | Relational analogy |
| :--- | :--- | :--- |
| **Table** | A collection of items | Table |
| **Item** | One record (up to 400 KB) | Row |
| **Attribute** | A field of an item (string, number, list, map...). Items in one table can have different attributes | Column (but flexible) |
| **Partition key** | Required. Its value is hashed to decide **which partition stores the item** | Primary key (part 1) |
| **Sort key** | Optional. Orders items that share the same partition key | Primary key (part 2) |

The primary key is either the partition key alone, or **partition key + sort key** (must be unique together).

```text
Table: Orders
 partition key = CustomerId    sort key = OrderDate
 {"CustomerId":"C1","OrderDate":"2026-10-01","Total":450,"Items":["pen","book"]}
 {"CustomerId":"C1","OrderDate":"2026-10-05","Total":90}
```
Query: "all orders of customer C1 in October" is fast because they share a partition key and are sorted by date.

Other features: secondary indexes (GSI/LSI) for other access patterns, on-demand or provisioned capacity, TTL (auto-expire items), streams (change events), global tables (multi-region), point-in-time recovery.

### Use cases
Shopping carts and user sessions, gaming leaderboards, IoT/event data, serverless backends (with Lambda), any workload needing very high scale and low latency with simple access patterns.

```bash
aws dynamodb create-table --table-name Orders \
  --attribute-definitions AttributeName=CustomerId,AttributeType=S AttributeName=OrderDate,AttributeType=S \
  --key-schema AttributeName=CustomerId,KeyType=HASH AttributeName=OrderDate,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST
```

---

## Part B: RDS (Relational Database Service)

### What is it?
A managed service for **relational (SQL) databases**: tables with rows and columns, a fixed schema, relationships and **joins**, and ACID transactions. AWS handles provisioning, OS and engine patching, backups and failover; you manage schema and queries.

### Supported engines
MySQL, PostgreSQL, MariaDB, Oracle, Microsoft SQL Server, IBM Db2, and **Amazon Aurora** (AWS's MySQL/PostgreSQL-compatible engine, faster and more scalable).

### DB instances
A **DB instance** is the managed database server. You pick the engine and version, instance class (e.g. `db.t3.micro`), storage type and size (can autoscale), and a subnet group in your VPC. A **DB cluster** (Aurora) is a group of instances sharing storage.

### Security
- Run it in **private subnets** and don't make it publicly accessible.
- **Security groups** allow the database port (3306/5432) only from the application's security group.
- **Encryption at rest** (KMS) and **in transit** (TLS/SSL).
- **IAM** for who can manage it, plus database users/passwords, ideally in **Secrets Manager**.

### Backups
- **Automated backups:** daily snapshot plus transaction logs, kept 1-35 days, enabling **point-in-time restore**.
- **Manual snapshots:** kept until you delete them.
- Restores always create a *new* instance.

### Multi-AZ
Keeps a **standby copy in another Availability Zone** with synchronous replication. If the primary fails (or during maintenance), RDS **fails over automatically** (typically 1-2 minutes). It is for **high availability**, and the standby doesn't serve reads (except in the Multi-AZ *cluster* option).

### Read replicas
Asynchronous copies of the database used to **scale reads** and reduce load on the primary (reports, read-heavy apps). They can be in another region and can be promoted to standalone databases. This is for **performance**, not automatic failover.

| | Multi-AZ | Read replica |
| :--- | :--- | :--- |
| Purpose | High availability / failover | Read scaling |
| Replication | Synchronous | Asynchronous |
| Serves traffic | No (standby) | Yes, reads |
| Failover | Automatic | Manual promotion |

### Use cases
Business and e-commerce applications with structured data and relationships (orders, customers, payments), CMS/WordPress backends, anything that needs SQL, joins and transactions.

---

## DynamoDB vs RDS

| | DynamoDB | RDS |
| :--- | :--- | :--- |
| Model | NoSQL key-value / document | Relational SQL |
| Schema | Flexible | Fixed |
| Scaling | Automatic, virtually unlimited | Vertical, plus read replicas |
| Queries | By key (+ indexes) | Complex SQL and joins |
| Management | Serverless | Managed instances (choose size) |
| Best for | Massive scale, simple access patterns | Structured data, relationships, transactions |
