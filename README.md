

# 🚀 AWS Cost Audit Toolkit

Take control of your AWS spending with this powerful suite of audit scripts! Instantly uncover hidden costs, optimize resources, and ensure your cloud environment is running efficiently.

## 🔍 What Does This Toolkit Check?

- **Untagged Resources:** No tags = no visibility. Identify resources missing tags for better management.
- **Idle & Oversized EC2 Instances:** Stop wasting budget! Find underutilized or oversized EC2s and get right-sizing tips via [AWS Compute Optimizer](https://aws.amazon.com/compute-optimizer/).
- **Missing Budgets & Alerts:** Avoid billing surprises. Ensure budgets and alerts are set up for proactive cost control.
- **S3 Buckets Without Lifecycle Policies:** Prevent log/data pileup. Detect buckets lacking auto-delete rules and set expiration policies.
- **Old RDS Snapshots:** Hidden costs can lurk in old backups. Keep only what you need for compliance or recovery.
- **Forgotten EBS Volumes:** Unattached EBS volumes still cost money! Find and clean up unused storage.
- **Data Transfer Charges:** Spot cross-AZ traffic and public IP usage. Get recommendations for VPC endpoints and cost-saving designs.
- **On-Demand vs. Reserved/Savings Plans:** Identify workloads that could save with Reserved Instances or Savings Plans.
- **Idle Load Balancers:** Detect load balancers with zero traffic and shut them down to save.

---

## ▶️ How to Run the Audit

Run the main audit script with:

```bash
./main.sh
```

You'll see progress in your terminal and get a detailed `audit_log` output file:

![](../img/aws_audit_output.png)

> ⚠️ **Note:** These scripts audit one AWS account in one region at a time. For multi-account or multi-region coverage, run separately for each.

---

## 🗂️ Script Overview

The toolkit is modular. `main.sh` launches the audit, while `utils.sh` handles AWS account ID and log formatting.

```bash
.
├── check_budgets.sh
├── check_data_transfer_risks.sh
├── check_forgotten_ebs.sh
├── check_idle_ec2.sh
├── check_idle_load_balancers.sh
├── check_old_rds_snapshots.sh
├── check_on_demand_instances.sh
├── check_s3_lifecycle.sh
├── check_untagged_resources.sh
├── main.sh
└── utils.sh
```

---

## 📊 Script Details

### AWS Budgets
`check_budgets.sh` lists all AWS budgets, checks for notifications, and logs results. [Learn more](https://aws.amazon.com/aws-cost-management/aws-budgets/)

### Idle EC2 & Oversized Instances
`check_idle_ec2.sh`:
1. Lists all running EC2s
2. Retrieves instance type & average CPU usage
3. Flags "idle" (<10% CPU) or "active" instances
4. Logs results and suggests optimization

### S3 Buckets Without Lifecycle Policies
**Required IAM permissions:**
- `s3:ListAllMyBuckets`
- `s3:GetBucketLifecycleConfiguration`

`check_s3_lifecycle.sh`:
- Lists all S3 buckets
- Checks for lifecycle policies
- Logs results and details (ID, Prefix, Status) using `jq`

### Old RDS Snapshots
**Required IAM permission:**
- `rds:DescribeDBSnapshots`

`check_old_rds_snapshots.sh`:
- Flags RDS snapshots older than 30 days
- Logs identifier, instance, creation time, and type

### Forgotten EBS Volumes
`check_forgotten_ebs.sh`:
- Finds unattached ("available") EBS volumes
- Logs ID, size, creation time, and tags

### Data Transfer Risks
`check_data_transfer_risks.sh`:
- Finds EC2s with public IPs
- Detects unused Elastic IPs
- Flags subnets in different AZs
- Checks for S3 & DynamoDB VPC endpoints
- (Add more endpoints as needed)
[Learn more](https://docs.aws.amazon.com/vpc/latest/privatelink/create-interface-endpoint.html)

### On-Demand EC2 Instances
`check_on_demand_instances.sh`:
- Counts on-demand EC2s
- Suggests Reserved Instances/Savings Plans for savings
[EC2 pricing](https://aws.amazon.com/ec2/pricing/)

### Load Balancers Without Traffic
`check_idle_load_balancers.sh`:
- Lists ALBs & NLBs
- Checks CloudWatch metrics (RequestCount, ActiveFlowCount, ProcessedBytes)
- Flags any with zero average traffic (e.g., past 3 days)