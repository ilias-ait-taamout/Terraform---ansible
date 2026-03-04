# 🚀 Terraform + Ansible – Deploy a Web Server on AWS

> **Project by:** Ilias AIT TAAMOUT  
> **Stack:** Terraform · Ansible · AWS EC2 · Nginx · Ubuntu  
> **Goal:** Provision infrastructure with Terraform and configure it with Ansible

---

## 📁 Project Structure

```
Terraform---ansible/
│
├── terraform/
│   ├── main.tf               # Provider, Security Group, EC2
│   ├── variables.tf          # Input variables
│   ├── outputs.tf            # Output public IP
│   └── terraform.tfvars      # Variable values (do NOT push to GitHub)
│
└── ansible/
    ├── inventory             # Target server(s)
    ├── playbook.yml          # Ansible tasks
    └── index.html            # Custom web page
```

---

## ✅ Prerequisites

Before starting, make sure you have:

- AWS account with access key configured
```bash
AWS CLI : aws configure
```
- Terraform installed → https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli
- Ansible installed
```bash
sudo apt install ansible -y
```
- SSH key pair created in AWS Console (EC2 → Key Pairs)
- `.pem` file downloaded and stored securely on your local machine

---

## 🟢 STEP 0 – Git Setup

### Link your machine to GitHub

```bash
git config --global user.name "your-username"
git config --global user.email "your-email@gmail.com"
```

### Generate a Personal Access Token (PAT)
1. GitHub → Settings → Developer Settings
2. Personal Access Tokens → Tokens (classic)
3. Generate new token → check **repo** scope
4. Copy the token immediately ⚠️(store it some where you wil need from now on)

### Save credentials permanently
```bash
git config --global credential.helper store
```

### Create and switch to a new branch
```bash
git checkout -b version1
git push origin version1
```

> ⚠️ **Common error:** `src refspec version1 does not match any`  
> **Fix:** You forgot `-b` when creating the branch. Use `git checkout -b version1` not `git checkout version1`

---

## 🟢 STEP 1 – Project Structure

### Move files into correct folders using git mv (you don't need to do this step if your files are in the correct folder)
```bash
mkdir terraform
mkdir ansible
git mv main.tf terraform/
git mv variables.tf terraform/
git mv outputs.tf terraform/
git mv terraform.tfvars terraform/
git add .
git commit -m "refactor: move terraform files into terraform/ folder"
git push origin version1
```

> ⚠️ Always use `git mv` instead of `mv` — this tells Git you moved the file, not deleted and recreated it.

---

## 🟢 STEP 2 – Terraform Code

### variables.tf
```hcl
variable "region" {
  description = "AWS region"
  type        = string
}
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}
variable "key_name" {
  description = "SSH key pair name"
  type        = string
}
```

### main.tf
```hcl
provider "aws" {
  region = var.region 
}

resource "aws_security_group" "web_sg" {
  name        = "web-security-group"
  description = "Allow SSH and HTTP"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  ami                    = "ami-0b6c6ebed2801a5cb"
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = {
    Name = "Terraform-Web-Server"
  }
}
```

### outputs.tf
```hcl
output "public_ip" {
  description = "Public IP of EC2"
  value       = aws_instance.web.public_ip
}
```

### terraform.tfvars
```hcl
region        = "us-east-1"
instance_type = "t3.micro"
key_name      = "your-key-name" # withou .pem
```

> ⚠️ **Never push terraform.tfvars to GitHub** — it may contain sensitive values. (for me it's okey but in real world senarios you should never push tfvers, or tfstate to github : do the remote backend)  
> Instead, create a `terraform.tfvars.example` with placeholder values and add `terraform.tfvars` to `.gitignore`

---

## 🟢 STEP 3 – Run Terraform

```bash
cd terraform/
terraform init
terraform plan
terraform apply
```

After apply, copy your public IP:
```bash
terraform output
```

### ⚠️ Common Error: Duplicate Security Group
```
Error: InvalidGroup.Duplicate: The security group 'web-security-group' already exists
```
**Why:** You deleted the EC2 manually from the AWS Console but the Security Group was not deleted.  
**Fix:** Go to AWS Console → EC2 → Security Groups → delete `web-security-group` manually, then run `terraform apply` again.

> 💡 **Lesson:** Always use `terraform destroy` instead of manually deleting resources from the AWS Console. This keeps Terraform's state in sync.

### Test SSH access
```bash
ssh -i your-key.pem ubuntu@PUBLIC_IP
```

---

## 🟢 STEP 4 – Transfer .pem File to EC2

Since Ansible runs FROM the EC2, the `.pem` file must be on that machine.

**From your local Windows machine (PowerShell):**
```powershell
scp -i the_key.pem the_key.pem ubuntu@YOUR_EC2_PUBLIC_IP:~/
```

> ⚠️ Don't forget `:~/` at the end — this tells scp where to place the file on the EC2.

**Then on the EC2, set correct permissions:**
```bash
chmod 400 ~/test.pem
```

> ⚠️ Without `chmod 400`, SSH and Ansible will refuse to use the key because it's "too open".

---

## 🟢 STEP 5 – Ansible Configuration

### inventory
```ini
[web]
YOUR_PUBLIC_IP ansible_user=ubuntu ansible_ssh_private_key_file=/home/ubuntu/test.pem
```

### playbook.yml
```yaml
- name: Install and configure nginx
  hosts: web
  become: true
  tasks:
    - name: Install nginx
      apt:
        name: nginx
        state: present
        update_cache: yes

    - name: Start nginx
      service:
        name: nginx
        state: started

    - name: Copy custom index.html
      copy:
        src: index.html
        dest: /var/www/html/index.html
```

> ⚠️ Recommanded : use Ansible modules (`apt`, `service`, `copy`) instead of `shell` commands.  
> Modules are **idempotent** — they skip the task if it's already done. Shell commands run blindly every time.

---

## 🟢 STEP 6 – Run Ansible

```bash
cd ansible/
ansible-playbook -i inventory playbook.yml
```

### ⚠️ Common Error: Host Key Verification Failed
```
fatal: UNREACHABLE - Failed to connect via ssh: Host key verification failed.
```
**Fix:** SSH into the target server manually first to accept the fingerprint:
```bash
ssh -i ~/test.pem ubuntu@YOUR_PUBLIC_IP
# type yes when prompted
exit
```
Then run the playbook again.

### ✅ Expected Output
```
TASK [Gathering Facts]        → ok
TASK [Install nginx]          → changed
TASK [Start nginx]            → ok
TASK [Copy custom index.html] → changed

ok=4  changed=2  failed=0  unreachable=0
```

---

## 🌍 STEP 7 – Verify

Open your browser and go to:
```
http://YOUR_PUBLIC_IP
```

You should see your custom web page. 🎉

---

## 🔒 .gitignore Best Practices

```
.terraform/
*.tfstate
*.tfstate.backup
*.pem
terraform.tfvars
```

---

## 🧠 Key Concepts Learned

| Concept | Explanation |
|---------|-------------|
| `key_name` in Terraform | References the AWS key pair name, NOT the .pem file |
| `terraform.tfstate` | Tracks all infrastructure Terraform created — never push to GitHub |
| `hosts: web` in Ansible | Targets only servers in the `[web]` inventory group |
| `become: true` | Runs tasks with sudo privileges |
| `idempotency` | Ansible modules skip tasks that are already done |
| `terraform destroy` | Always use this instead of manually deleting AWS resources |

---

## 🚀 Next Steps (Bonus) (version 2)

- [ ] Remote Terraform backend (S3 + DynamoDB)
- [ ] Convert Ansible tasks into Roles
- [ ] CI/CD pipeline with GitHub Actions
- [ ] Separate dev and prod environments




**The professional solution to not pushing the state files in github... → Remote Backend**

Instead of storing `tfstate` locally, you store it in **AWS S3 + DynamoDB**:
```
Your Machine → terraform apply → state saved in S3 bucket
                                        ↕
                              DynamoDB locks the state
                              (prevents two people applying at same time)
