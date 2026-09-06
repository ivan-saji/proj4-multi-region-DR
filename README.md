# Azure VM Disaster Recovery with Terraform

## 📌 Project Overview

This project demonstrates how to provision an Azure Linux Virtual Machine and configure **Azure Site Recovery (ASR)** for disaster recovery using **Terraform**.

The entire infrastructure and Site Recovery configuration is managed through Infrastructure as Code.

The goal of the project is to achieve:

> **One `terraform apply` → Azure VM is created → Site Recovery is configured → VM replication starts automatically.**

The project uses two Azure regions:

* **Primary Region:** Central India
* **DR Region:** South India

The project was initially tested manually through the Azure Portal to understand and validate the Site Recovery workflow. After successfully completing the manual DR/failover test, the configuration was converted into Terraform.

---

# 🏗️ Architecture

```text
                         Azure Subscription
                                │
              ┌─────────────────┴─────────────────┐
              │                                   │
              ▼                                   ▼
       Central India                         South India
       PRIMARY REGION                        DR REGION
              │                                   │
      ┌───────┴────────┐                    ┌─────┴─────┐
      │                │                    │           │
      │  rg-primary    │                    │  rg-dr    │
      │                │                    │           │
      │  ┌──────────┐  │                    │ ┌───────┐ │
      │  │  TestVM  │  │                    │ │  RSV  │ │
      │  └────┬─────┘  │                    │ └───┬───┘ │
      │       │        │                    │     │     │
      │  ┌────▼─────┐  │                    │     │     │
      │  │    NIC    │  │                    │     │     │
      │  └───────────┘  │                    │     │     │
      │                │                    │     │     │
      │ ASR Cache      │                    │     │     │
      │ Storage Account│                    │     │     │
      └───────┬────────┘                    │     │     │
              │                             │     │     │
              │      Azure Site Recovery    │     │     │
              └────────────────────────────►│     │     │
                                            │     │     │
                                      DR Fabric  │     │
                                            │     │     │
                                      DR Container │   │
                                            │     │     │
                                            └─────┘     │
                                                      │
                                           Replication Policy
                                                      │
                                           Container Mapping
                                                      │
                                                      ▼
                                           Replicated VM
```

---

# 🎯 Project Objectives

The main objectives of this project were:

* Provision an Azure Linux VM using Terraform.
* Configure networking for the VM.
* Create separate Primary and DR resource groups.
* Create an Azure Recovery Services Vault.
* Configure Azure Site Recovery fabrics.
* Configure Site Recovery protection containers.
* Configure a replication policy.
* Map the Primary region to the DR region.
* Configure the VM for Site Recovery replication.
* Start replication automatically through Terraform.
* Perform a manual DR/failover test.
* Validate that the recovered VM can be started in the DR region.
* Convert the manually validated DR configuration into Infrastructure as Code.
* Make the entire environment reproducible using Terraform.

---

# ☁️ Azure Resources

The project creates and manages the following major resources.

## Primary Region

### Resource Group

```text
rg-primary
```

Location:

```text
Central India
```

Contains the primary VM and its networking/storage resources.

### Linux Virtual Machine

```text
TestVM
```

Configuration:

* OS: Ubuntu 20.04 LTS
* Image: Ubuntu 20.04 LTS Gen2
* VM Size: Standard_D2_v4
* OS Disk: 30 GB
* Disk Type: Standard_LRS
* Computer Name: `testvm`
* Admin Username: `testadmin`

Ubuntu 20.04 was deliberately selected because it was the configuration that successfully worked during the manual Site Recovery testing.

### Network Interface

```text
TestVM-nic
```

The NIC connects the VM to the primary virtual network/subnet.

### Site Recovery Cache Storage

A Standard StorageV2 storage account using:

```text
LRS
```

is created in the primary region for Site Recovery caching.

The storage account name uses a random suffix to avoid Azure globally unique storage-account naming conflicts.

---

# 🌎 Disaster Recovery Region

## Resource Group

```text
rg-dr
```

Location:

```text
South India
```

This resource group contains the Site Recovery management infrastructure.

---

# 🛡️ Recovery Services Vault

The project creates:

```text
rsv-vault
```

The Recovery Services Vault is the management boundary used by Azure Site Recovery.

It contains the Site Recovery configuration required to protect the primary VM.

Conceptually:

```text
Recovery Services Vault
│
├── Primary Fabric
│
├── DR Fabric
│
├── Primary Protection Container
│
├── DR Protection Container
│
├── Replication Policy
│
├── Protection Container Mapping
│
└── Replicated VM
```

---

# 🔄 Azure Site Recovery Configuration

## 1. Site Recovery Fabrics

Two Site Recovery fabrics are configured.

### Primary Fabric

```text
primary-fabric
```

Represents:

```text
Central India
```

### DR Fabric

```text
dr-fabric
```

Represents:

```text
South India
```

The fabrics allow Site Recovery to understand the source and target environments involved in replication.

---

# 2. Protection Containers

Two protection containers are created.

### Primary

```text
primary-container
```

### DR

```text
dr-container
```

The primary protection container represents the source-side protected environment, while the DR protection container represents the target-side recovery environment.

---

# 3. Replication Policy

The project creates:

```text
replication-policy
```

The lab configuration uses:

```text
Recovery point retention:
3 hours

Application-consistent snapshots:
Every 1 hour
```

These values were intentionally chosen for a lab environment so recovery points can be observed and tested without unnecessarily long retention periods.

The replication policy controls how Site Recovery handles recovery points for protected workloads.

---

# 4. Protection Container Mapping

The project creates:

```text
primary-to-dr
```

The mapping establishes the relationship:

```text
Central India
     │
     ▼
Primary Protection Container
     │
     │
     │ Replication Policy
     │
     ▼
DR Protection Container
     │
     ▼
South India
```

This tells Site Recovery how the source protection container corresponds to the target protection container.

---

# 5. Replicated VM

The final Site Recovery configuration explicitly protects:

```text
TestVM
```

This is the component that changes the configuration from:

> "Site Recovery infrastructure exists"

to:

> "This specific VM is protected by Site Recovery."

The Terraform configuration references the existing primary VM and associates it with the Site Recovery configuration.

Conceptually:

```text
azurerm_linux_virtual_machine.vm_primary
                    │
                    ▼
     Site Recovery Replicated VM
                    │
                    ▼
             South India
```

When Terraform creates this resource, Azure Site Recovery begins the initial replication process for the VM.

---

# 🔗 Terraform Dependency Chain

Terraform manages the resources through dependencies.

The overall dependency relationship is approximately:

```text
Resource Groups
      │
      ├───────────────┐
      ▼               ▼
   Primary VM       RSV
      │               │
      │               ├── Primary Fabric
      │               │       │
      │               │       └── Primary Container
      │               │
      │               ├── DR Fabric
      │               │       │
      │               │       └── DR Container
      │               │
      │               └── Replication Policy
      │
      └───────────────────────┐
                              ▼
                    Container Mapping
                              │
                              ▼
                       Replicated VM
                              │
                              ▼
                     Replication Starts
```

Terraform references resources instead of relying on manually entered Azure resource IDs wherever possible.

This allows Terraform to build the correct dependency graph automatically.

---

# 🚀 Deployment

## Prerequisites

Before deploying the project, ensure the following are installed:

* Azure CLI
* Terraform
* Git
* An Azure subscription

Authenticate with Azure:

```bash
az login
```

Verify the active subscription:

```bash
az account show
```

If required, select the appropriate subscription:

```bash
az account set --subscription "<SUBSCRIPTION_ID>"
```

---

# 📁 Terraform Structure

The Terraform project can be organized into logical files such as:

```text
.
├── provider.tf
├── resource_groups.tf
├── network.tf
├── vm.tf
├── storage.tf
├── recovery_services_vault.tf
├── site_recovery.tf
├── variables.tf
├── outputs.tf
└── terraform.tfvars
```

The exact filenames are not important to Terraform. They are separated this way to make the infrastructure easier to understand and maintain.

---

# 🔍 Initialize Terraform

From the project directory:

```bash
terraform init
```

This downloads the required Terraform providers and initializes the working directory.

---

# ✅ Validate Configuration

Run:

```bash
terraform validate
```

Expected result:

```text
Success! The configuration is valid.
```

---

# 📋 Review the Execution Plan

Before applying infrastructure changes:

```bash
terraform plan
```

This is an important step.

Terraform compares:

```text
Terraform Configuration
        +
Terraform State
        +
Current Azure Infrastructure
```

and determines what needs to be created, modified, or destroyed.

The plan should always be reviewed before applying infrastructure changes.

---

# 🚀 Deploy Everything

Run:

```bash
terraform apply
```

Confirm the deployment when Terraform asks:

```text
yes
```

Terraform then provisions the infrastructure and configures Site Recovery.

The intended result is:

```text
terraform apply
       │
       ▼
Resource Groups
       │
       ▼
Networking
       │
       ▼
TestVM
       │
       ▼
Recovery Services Vault
       │
       ▼
Site Recovery Configuration
       │
       ├── Fabrics
       ├── Containers
       ├── Policy
       └── Mapping
       │
       ▼
TestVM Protection
       │
       ▼
Initial Replication
       │
       ▼
Continuous Replication
```

---

# 🔎 Verify the VM

After deployment:

```bash
az vm show \
  --name TestVM \
  --resource-group rg-primary \
  -o table
```

---

# 🔎 Verify Site Recovery

The Site Recovery configuration can be checked through:

* Azure Portal
* Recovery Services Vault
* Site Recovery
* Replicated items

The protected VM should eventually show a healthy replication state after the initial synchronization completes.

Initial replication can take some time depending on:

* VM disk size
* Amount of data on the disk
* Azure infrastructure
* Network conditions
* Replication backlog

Therefore, `terraform apply` completing does not necessarily mean the VM has already finished its initial synchronization.

---

# 🧪 Disaster Recovery Testing

Before converting the configuration to Terraform, Site Recovery was tested manually.

The testing process included:

1. Creating the primary VM.
2. Configuring Site Recovery.
3. Installing/using the required Mobility Service.
4. Encountering Mobility Agent compatibility/configuration issues.
5. Changing the VM operating system configuration to Ubuntu 20.04 LTS.
6. Successfully configuring replication.
7. Performing a test failover.
8. Validating the recovered VM in the DR region.
9. Confirming the DR environment worked correctly.
10. Recreating the configuration through Terraform.

Ubuntu 20.04 became the final VM OS configuration because it was the version that successfully completed the manual Site Recovery testing.

---

# 🔥 Test Failover

A test failover is used to validate the DR configuration without performing an actual production disaster.

The general flow is:

```text
Primary VM
    │
    │ Replication
    ▼
Site Recovery
    │
    ▼
DR Region
    │
    ▼
Test Failover
    │
    ▼
Temporary Recovery VM
```

The purpose is to verify that the VM can be recovered successfully in the target region.

---

# 🚨 Failover

A production failover represents an actual disaster recovery event.

Conceptually:

```text
PRIMARY FAILURE
      │
      ▼
Site Recovery
      │
      ▼
South India
      │
      ▼
Recovered VM
```

The exact failover procedure should be performed through Azure Site Recovery according to the organization's DR/runbook requirements.

This Terraform project **configures replication**; it does not automatically trigger a production failover.

---

# 🔁 Replication Lifecycle

Once Site Recovery protection is enabled:

```text
Primary VM
    │
    ▼
Initial Replication
    │
    ▼
Recovery Point Creation
    │
    ▼
Continuous Replication
    │
    ▼
Healthy Protected State
```

The initial replication copies the required VM data to the DR environment.

After synchronization, Site Recovery continuously maintains replicated recovery data.

---

# 🧠 Important Terraform Concept

The VM itself is created with:

```text
azurerm_linux_virtual_machine
```

Site Recovery protection is configured separately.

Therefore:

```text
VM creation
      ≠
VM replication
```

The VM resource creates the workload.

The Site Recovery replicated-VM resource tells Azure:

> Protect this workload using Site Recovery.

This separation is important when designing infrastructure as code.

---

# 🧹 Destroying the Lab

Because this is a test/lab environment, the infrastructure should be destroyed when it is no longer required.

Run:

```bash
terraform destroy
```

Review the destruction plan carefully and confirm:

```text
yes
```

Terraform will remove the Terraform-managed Azure resources.

---

# ⚠️ Important Cleanup Considerations

The Azure Resource Groups contain the infrastructure managed by Terraform.

However, not every Azure object necessarily belongs to those resource groups.

For example:

* Microsoft Entra App Registrations
* Service Principals
* Federated Identity Credentials
* Subscription/RG-level RBAC assignments

may be managed separately depending on how the project is configured.

Therefore, after destroying the infrastructure, verify that no unwanted Azure resources remain.

---

# 💰 Cost Management

This project uses Azure resources that can generate charges.

Particularly:

* VM
* Managed Disk
* Storage Account
* App Service/other supporting resources if present
* Site Recovery
* Replicated storage/data

For a temporary lab, destroy the environment when it is not being used:

```bash
terraform destroy
```

If the project uses a dedicated disposable resource group, deleting the resource group can also remove the Azure resources contained within it.

However, always verify the result rather than assuming everything has been removed.

---

# 🚫 Intentionally Skipped Components

Two areas were intentionally not implemented in this project:

## Azure NetApp Files (ANF)

ANF was not included.

Reason:

The primary objective of this project was to understand and automate VM-level disaster recovery using Azure Site Recovery.

ANF introduces additional storage architecture and is outside the scope of the completed lab.

---

## Azure Files / File Shares

Azure Files/file-share configuration was also skipped.

The project therefore focuses on:

```text
VM
+
Networking
+
Storage required for ASR
+
Recovery Services Vault
+
Azure Site Recovery
+
VM Replication
```

rather than building a complete application/file-share DR architecture.

These can be added later as separate extensions to the project.

---

# 📌 What This Project Demonstrates

This project demonstrates several important real-world infrastructure concepts.

### Infrastructure as Code

Instead of manually creating resources:

```text
Portal → Click → Configure → Repeat
```

the infrastructure is defined declaratively:

```text
Terraform Configuration
        │
        ▼
terraform plan
        │
        ▼
terraform apply
        │
        ▼
Azure Infrastructure
```

---

### Declarative Infrastructure

Terraform describes the desired state.

For example:

```text
I want:

1 VM
1 NIC
1 RSV
2 ASR fabrics
2 protection containers
1 replication policy
1 container mapping
1 protected VM
```

Terraform determines how to reach that state.

---

### Infrastructure Dependencies

The project demonstrates how Terraform resource references create dependencies.

For example:

```text
VM
 │
 └── Site Recovery protection
        │
        ├── Protection Container
        ├── Mapping
        └── Replication Policy
```

---

### Disaster Recovery

The project demonstrates the basic Azure DR architecture:

```text
Primary Region
      │
      │ Continuous Replication
      ▼
DR Region
```

---

### Recovery Services Vault

The project demonstrates the role of an RSV as the management boundary for Azure Site Recovery.

---

### Replication Policy

The project demonstrates how recovery-point retention and application-consistent snapshots influence Site Recovery.

---

### Test Failover

The project demonstrates why DR should be tested rather than merely configured.

A configuration that exists in the Portal is not enough.

The DR process must actually be validated.

---

# 🧩 Project Evolution

The project was developed incrementally.

### Phase 1 — Primary Infrastructure

```text
Resource Group
     │
     ├── VNet/Subnet
     ├── NIC
     ├── VM
     └── Storage
```

### Phase 2 — Manual Site Recovery

Site Recovery was configured manually to understand the Azure workflow.

### Phase 3 — Troubleshooting

Mobility Service/Agent issues were encountered.

The VM OS configuration was changed to:

```text
Ubuntu 20.04 LTS Gen2
```

This successfully resolved the compatibility/configuration problem during testing.

### Phase 4 — Manual DR Validation

A test failover was performed and the DR environment was validated.

### Phase 5 — Terraform Automation

The successful manual Site Recovery configuration was converted into Terraform.

### Phase 6 — Final State

The project reached the desired state:

```text
terraform apply
       │
       ▼
Primary VM Created
       │
       ▼
Site Recovery Configured
       │
       ▼
VM Protection Enabled
       │
       ▼
Replication Starts
```

---

# 🎓 Key Learnings

## 1. DR should be tested before being automated

The manual Site Recovery exercise was valuable because it exposed problems that would have been difficult to understand from Terraform alone.

---

## 2. OS compatibility matters

The Mobility Service is an important component of Azure Site Recovery.

The project initially encountered Mobility Agent issues.

Using Ubuntu 20.04 LTS resulted in a working configuration.

This highlights the importance of checking workload/OS compatibility when designing DR solutions.

---

## 3. Creating an RSV doesn't create DR

Creating:

```text
Recovery Services Vault
```

is only the beginning.

A working ASR configuration requires multiple components:

```text
RSV
 │
 ├── Fabrics
 ├── Protection Containers
 ├── Replication Policy
 ├── Container Mapping
 └── Replicated VM
```

---

## 4. The replicated VM is the actual protection configuration

The VM must explicitly be associated with Site Recovery.

This is what makes the difference between:

```text
ASR infrastructure exists
```

and:

```text
TestVM is protected by ASR
```

---

## 5. Terraform state matters

Terraform doesn't simply look at the `.tf` files.

It maintains state describing the infrastructure it manages.

Therefore, when bringing manually created infrastructure under Terraform, resources may need to be imported/reconciled rather than blindly recreated.

---

## 6. Always use `terraform plan`

A safe Terraform workflow is:

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

Not:

```bash
terraform apply
```

without reviewing what Terraform intends to change.

---

# 🛠️ Useful Terraform Commands

Initialize:

```bash
terraform init
```

Validate:

```bash
terraform validate
```

Format:

```bash
terraform fmt
```

Preview changes:

```bash
terraform plan
```

Apply:

```bash
terraform apply
```

Show state:

```bash
terraform state list
```

Inspect a resource:

```bash
terraform state show <RESOURCE_ADDRESS>
```

Destroy:

```bash
terraform destroy
```

---

# 📚 Possible Future Enhancements

The project can be extended with:

* Azure NetApp Files
* Azure Files
* File-share replication/DR
* Additional VMs
* Multiple VM protection configurations
* Terraform-managed Entra App Registration
* Terraform-managed Service Principal
* Terraform-managed Federated Identity Credential
* Terraform-managed Azure RBAC
* GitHub Actions deployment
* Automated DR testing
* Recovery plans
* Azure Monitor integration
* Alerts for replication health
* Automated failover runbooks
* Infrastructure validation tests
* Remote Terraform state
* Separate Terraform environments for development/staging/production

---

# 🏁 Final Project State

The completed project provides an automated Azure VM disaster recovery environment.

### Primary

```text
Central India
│
└── rg-primary
      │
      ├── VNet
      ├── Subnet
      ├── TestVM NIC
      ├── TestVM
      │     └── Ubuntu 20.04 LTS
      │
      └── ASR Cache Storage
```

### Disaster Recovery

```text
South India
│
└── rg-dr
      │
      └── rsv-vault
            │
            ├── primary-fabric
            │     └── primary-container
            │
            ├── dr-fabric
            │     └── dr-container
            │
            ├── replication-policy
            │
            ├── primary-to-dr mapping
            │
            └── TestVM replication
```

### Deployment

```text
terraform apply
      │
      ▼
Azure Infrastructure
      │
      ▼
TestVM
      │
      ▼
Azure Site Recovery
      │
      ▼
Replication Enabled
      │
      ▼
DR Ready
```

The final objective of the project is therefore achieved:

> **The primary VM and its Site Recovery configuration can be deployed reproducibly through Terraform, with replication beginning as part of the Terraform deployment rather than requiring manual Portal configuration.**
