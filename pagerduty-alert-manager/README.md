# PagerDuty + GitHub Actions Runner on AWS (Terraform + Ansible)

This project provisions:
- **AWS S3 + DynamoDB** for Terraform remote state.
- **EC2 self-hosted GitHub Actions runner** with IAM role for state access.
- **Ansible** playbook to bootstrap the runner and register it to your GitHub repo.
- **PagerDuty IaC repo** (Terraform) with reusable runbook module + GitHub Actions workflow that runs on the self-hosted runner.

## Prerequisites
- AWS account & credentials on your local machine.
- SSH keypair (public key path for EC2).
- PagerDuty API token (store in GitHub Secrets as `PAGERDUTY_TOKEN`).
- GitHub repository to host `app/alert-infra` (and to register the runner).

## Step-by-Step

### 1) Create backend (S3 + DynamoDB)
```bash
cd infra/bootstrap-backend
terraform init
terraform apply -auto-approve \  -var='state_bucket_name=YOUR-UNIQUE-BUCKET' \  -var='aws_region=us-east-1' \  -var='lock_table_name=terraform-locks'
```
Note the **bucket name** and **table name** from outputs.

### 2) Provision EC2 Runner
Edit `infra/runner/terraform.tfbackend` and set:
```
bucket         = "YOUR-UNIQUE-BUCKET"
region         = "us-east-1"
dynamodb_table = "terraform-locks"
```
Then apply:
```bash
cd ../runner
terraform init -backend-config=terraform.tfbackend
terraform apply -auto-approve \  -var='aws_account_id=123456789012' \  -var='state_bucket_name=YOUR-UNIQUE-BUCKET' \  -var='lock_table_name=terraform-locks' \  -var='ssh_allowed_cidr=YOUR_IP/32' \  -var='ssh_public_key_path=~/.ssh/id_rsa.pub'
```
Copy the `runner_public_ip` from outputs.

### 3) Bootstrap the Runner with Ansible
Edit `ansible/inventory.ini` and set the public IP; ensure `ansible_ssh_private_key_file` points to your private key.
Edit `ansible/group_vars/runner.yml` and set:
- `github_repo`: `your-org/your-repo`
- `github_runner_token`: **Generate a runner registration token** from GitHub UI (Settings → Actions → Runners → New self-hosted runner). This token expires quickly.
- `github_runner_labels`: `ec2-pagerduty`

Run:
```bash
cd ../../ansible
ansible -i inventory.ini all -m ping
ansible-playbook -i inventory.ini playbooks/bootstrap_runner.yml
```

### 4) Prepare the PagerDuty IaC Repo
Inside `app/alert-infra`, edit `terraform.tfbackend` with your bucket/table.
Push `app/alert-infra` *as its own repo* (or use this monorepo). In that repo, add secret:
- `PAGERDUTY_TOKEN` in **Settings → Secrets and variables → Actions**.

### 5) Run the pipeline
- Create a PR → workflow runs `plan` on the **self-hosted runner** (label `ec2-pagerduty`).
- Merge to `main` → workflow runs `apply` and updates PagerDuty.

## Notes
- The EC2 instance uses an IAM role granting access only to the specified S3 bucket & DynamoDB table.
- Security Group allows SSH only from your IP (adjust as needed).
- For production, consider private subnets + SSM Session Manager and removing SSH.

## Clean up
Destroy in reverse:
```bash
cd infra/runner && terraform destroy
cd ../bootstrap-backend && terraform destroy
```
