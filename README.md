# terraform-azure-acr-aks

# Private ACR + Private AKS — Terraform Modules & Azure DevOps CI/CD

![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![Azure](https://img.shields.io/badge/Microsoft_Azure-0078D4?style=for-the-badge&logo=microsoft-azure&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![Azure DevOps](https://img.shields.io/badge/Azure_DevOps-0078D7?style=for-the-badge&logo=azure-devops&logoColor=white)

Terraform modules for provisioning a **private Azure Container Registry (ACR)** and a **private Azure Kubernetes Service (AKS)** cluster, together with Azure DevOps YAML pipelines that build Docker images (CI) and deploy them to AKS pods (CD). All pipelines run on **self-hosted ADO agents** that live inside the same virtual network, ensuring end-to-end private connectivity.

> **Repository**: [github.com/rajdip-chakraborty-dev/terraform-azure-acr-aks](https://github.com/rajdip-chakraborty-dev/terraform-azure-acr-aks)

---

## Architecture Overview

**Infrastructure Layout**

```
┌──────────────────────────────────────────────────────────────────────────┐
│  Azure Resource Group                                                    │
│                                                                          │
│  ┌── Virtual Network  10.0.0.0/8 ──────────────────────────────────┐    │
│  │                                                                  │    │
│  │  ┌─────────────────────────┐   ┌─────────────────────────────┐  │    │
│  │  │  subnet-aks             │   │  subnet-acr-pe              │  │    │
│  │  │  10.240.0.0/16          │   │  10.241.0.0/24              │  │    │
│  │  │                         │   │                             │  │    │
│  │  │  ┌───────────────────┐  │   │  ┌─────────────────────┐   │  │    │
│  │  │  │  AKS Cluster      │  │   │  │  ACR               │   │  │    │
│  │  │  │  (private API     │  │   │  │  Private Endpoint   │   │  │    │
│  │  │  │   server)         │  │   │  └─────────────────────┘   │  │    │
│  │  │  └───────────────────┘  │   └─────────────────────────────┘  │    │
│  │  └─────────────────────────┘                                     │    │
│  │                                                                  │    │
│  │  ┌──────────────────────────────────────────────────────────┐   │    │
│  │  │  subnet-ado-agents  10.242.0.0/24                        │   │    │
│  │  │                                                          │   │    │
│  │  │  ┌────────────────────────────────────────────────────┐  │   │    │
│  │  │  │  Self-hosted ADO Agents                            │  │   │    │
│  │  │  │  • Reaches ACR via private endpoint                │  │   │    │
│  │  │  │  • Reaches AKS via private API server              │  │   │    │
│  │  │  └────────────────────────────────────────────────────┘  │   │    │
│  │  └──────────────────────────────────────────────────────────┘   │    │
│  │                                                                  │    │
│  │  Private DNS: privatelink.azurecr.io  →  ACR private IP         │    │
│  └──────────────────────────────────────────────────────────────────┘    │
│                                                                          │
│  ACR  (Premium SKU · public access disabled · AcrPull via kubelet MI)   │
└──────────────────────────────────────────────────────────────────────────┘
```

**CI/CD Flow**

```
  Developer push to main
         │
         ▼
  ┌─────────────────────────────────────────┐
  │  CI Pipeline  (self-hosted ADO agent)   │
  │                                         │
  │  1. docker build                        │
  │  2. docker push  ──────────────────────────────► Private ACR
  │  3. publish build metadata              │
  └──────────────────┬──────────────────────┘
                     │  triggers on CI success
                     ▼
  ┌─────────────────────────────────────────┐
  │  CD Pipeline  (self-hosted ADO agent)   │
  │                                         │
  │  Stage: Deploy → Dev                    │
  │  1. Substitute image tag in manifest    │
  │  2. kubectl apply ─────────────────────────────► Private AKS (dev)
  │  3. kubectl rollout status              │
  └──────────────────┬──────────────────────┘
                     │  manual approval gate
                     ▼
  ┌─────────────────────────────────────────┐
  │  CD Pipeline  (self-hosted ADO agent)   │
  │                                         │
  │  Stage: Deploy → Prod                   │
  │  1. Substitute image tag in manifest    │
  │  2. kubectl apply ─────────────────────────────► Private AKS (prod)
  │  3. kubectl rollout status              │
  └─────────────────────────────────────────┘
```

### Key Design Decisions

| Concern | Decision | Reason |
|---------|----------|--------|
| ACR visibility | Public access disabled + private endpoint | Images accessible only within the VNet |
| AKS API server | `private_cluster_enabled = true` | Kubernetes API is not exposed to the internet |
| AKS identity | System-assigned managed identity | No credentials to rotate; native to the cluster lifecycle |
| ACR authentication from AKS | AcrPull role on kubelet identity | No `imagePullSecrets` needed in manifests |
| Network plugin | Azure CNI | Required for VNet-native pod IPs and network policies |
| ADO agents | Self-hosted, in `subnet-ado-agents` | Only agents inside the VNet can reach private ACR and AKS |
| Secrets | Zero hardcoded secrets | All credentials flow through ADO service connections and Azure MI |

---

## Project Structure

```
terraform-azure-acr-aks/
├── main.tf                        # Root module — wires all sub-modules together
├── variables.tf                   # All input variables with descriptions and defaults
├── outputs.tf                     # Key outputs (ACR login server, AKS name, etc.)
├── terraform.tfvars.example       # Copy to terraform.tfvars and fill in values
│
├── modules/
│   ├── resource_group/            # Azure Resource Group
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── network/                   # VNet, subnets, NSGs, private DNS zone for ACR
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── acr/                       # Private ACR + private endpoint
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── aks/                       # Private AKS cluster + AcrPull role assignment
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── pipelines/
│   ├── ci-pipeline.yml            # ADO CI — build Docker image, push to private ACR
│   └── cd-pipeline.yml            # ADO CD — deploy from ACR to private AKS
│
└── k8s/
    ├── deployment.yaml            # Kubernetes Deployment (image placeholder substituted by CD)
    └── service.yaml               # Kubernetes Service (ClusterIP)
```

---

## Prerequisites

| Tool | Minimum Version | Purpose |
|------|----------------|---------|
| Terraform | >= 1.5 | Infrastructure provisioning |
| Azure CLI | >= 2.50 | Authentication and AKS credential retrieval |
| kubectl | >= 1.27 | Applied by the CD pipeline via ADO task |
| Docker | >= 20.x | Used by the CI pipeline on self-hosted agents |

### Azure permissions required for the identity running Terraform

- `Contributor` on the target Azure Subscription (or Resource Group)
- `User Access Administrator` on the target scope (needed to create the AcrPull role assignment for AKS)

---

## Step 1 — Authenticate Terraform to Azure

Terraform reads Azure credentials from environment variables. Choose one of the following approaches:

### Option A — Service Principal (recommended for CI/CD)

Create a service principal and export its credentials as environment variables **before running Terraform**:

```bash
# Create a service principal with Contributor role
az ad sp create-for-rbac \
  --name "sp-terraform-acr-aks" \
  --role Contributor \
  --scopes /subscriptions/<SUBSCRIPTION_ID> \
  --sdk-auth

# Export the credentials (values come from the JSON output above)
export ARM_CLIENT_ID="<appId>"
export ARM_CLIENT_SECRET="<password>"
export ARM_TENANT_ID="<tenant>"
export ARM_SUBSCRIPTION_ID="<subscriptionId>"
```

> Store these values in your CI/CD secret store (e.g., Azure Key Vault, ADO Variable Group as secret variables) — never commit them to source control.

### Option B — Interactive login (local development only)

```bash
az login
az account set --subscription "<SUBSCRIPTION_ID>"
```

Terraform will use the credentials from your active Azure CLI session.

---

## Step 2 — Deploy Infrastructure with Terraform

```bash
# 1. Clone this repository and navigate into it
git clone https://github.com/rajdip-chakraborty-dev/terraform-azure-acr-aks.git
cd terraform-azure-acr-aks

# 2. Copy and configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — at minimum update: resource_group_name, location, acr_name

# 3. Initialize Terraform (downloads providers and modules)
terraform init

# 4. Preview the changes
terraform plan -out=tfplan

# 5. Apply the infrastructure
terraform apply tfplan

# 6. Capture outputs needed for the ADO Variable Group
terraform output acr_login_server
terraform output aks_cluster_name
terraform output resource_group_name
```

> **Remote state (recommended for teams):** Uncomment the `backend "azurerm"` block in `main.tf` and create the storage account/container beforehand:
> ```bash
> az group create --name rg-terraform-state --location eastus
> az storage account create --name <unique-name> --resource-group rg-terraform-state --sku Standard_LRS
> az storage container create --name tfstate --account-name <unique-name>
> ```

---

## Step 3 — Provision Self-Hosted ADO Agents in the VNet

The self-hosted agents must run **inside `subnet-ado-agents`** to reach both the private ACR endpoint and the private AKS API server.

### Recommended approach — Azure VM Scale Set agent pool

```bash
# Create a VM Scale Set in the agents subnet (replace placeholders)
az vmss create \
  --name vmss-ado-agents \
  --resource-group <RESOURCE_GROUP> \
  --image Ubuntu2204 \
  --subnet <AGENTS_SUBNET_ID> \
  --instance-count 2 \
  --public-ip-address "" \
  --lb ""
```

Then in Azure DevOps:
1. **Project Settings → Agent pools → Add pool**
2. Select **Azure Virtual Machine Scale Set**
3. Choose the VMSS created above
4. Note the **pool name** — it becomes the `adoAgentPoolName` variable

Install required tools (Docker, kubectl, Azure CLI) via a cloud-init script or VMSS custom script extension before registering agents.

---

## Step 4 — Configure Azure DevOps Service Connections

Navigate to **Project Settings → Service Connections** and create the following:

### 4a — Azure Resource Manager Service Connection

Used by the CD pipeline to retrieve AKS credentials and run `kubectl`.

| Field | Value |
|-------|-------|
| Type | Azure Resource Manager |
| Authentication | Service Principal (use the same SP from Step 1, or a dedicated one) |
| Scope | Subscription or Resource Group |
| Name | `azure-acr-aks-sc` *(becomes `azureServiceConnection` in the variable group)* |

Assign the SP the **Azure Kubernetes Service Cluster User Role** on the AKS cluster resource.

### 4b — Docker Registry Service Connection

Used by the CI pipeline to authenticate `docker push` to the private ACR.

| Field | Value |
|-------|-------|
| Type | Docker Registry → Azure Container Registry |
| Authentication | Service Principal |
| Registry | Select the ACR created by Terraform |
| Name | `acr-docker-sc` *(becomes `acrServiceConnection` in the variable group)* |

---

## Step 5 — Create the ADO Variable Group

In Azure DevOps: **Pipelines → Library → + Variable group**

Name the group exactly: **`acr-aks-variables`**

| Variable | Example value | Secret? |
|----------|---------------|---------|
| `adoAgentPoolName` | `vmss-ado-agents` | No |
| `azureServiceConnection` | `azure-acr-aks-sc` | No |
| `acrServiceConnection` | `acr-docker-sc` | No |
| `acrLoginServer` | `acrmycompanyprod001.azurecr.io` | No |
| `resourceGroupName` | `rg-acr-aks-prod` | No |
| `aksClusterName` | `aks-prod` | No |

> The values for `acrLoginServer`, `resourceGroupName`, and `aksClusterName` come from `terraform output` in Step 2.

---

## Step 6 — Create ADO Pipelines

### CI Pipeline

1. Go to **Pipelines → New pipeline**
2. Connect to your repository
3. Select **Existing Azure Pipelines YAML file**
4. Path: `pipelines/ci-pipeline.yml`
5. Rename the pipeline to: **`CI - Build and Push Image`** (the CD pipeline references this exact name)
6. Link the `acr-aks-variables` variable group under **Variables → Variable groups**

### CD Pipeline

1. Repeat the steps above with path: `pipelines/cd-pipeline.yml`
2. Create two ADO **Environments**:
   - `aks-dev` — no gates required (auto-deploys on CI success)
   - `aks-prod` — add a **manual approval** gate (Environments → Approvals and checks)
3. Link the `acr-aks-variables` variable group

---

## Step 7 — Customise the Application Manifests

Edit `k8s/deployment.yaml` and `k8s/service.yaml` for your application:

- **Deployment**: Update `containerPort`, health check paths, resource requests/limits, and replica count.
- **Service**: Change `type` to `LoadBalancer` if you need external access, or wire up an Ingress controller.

The string `REPLACE_ACR_IMAGE` in `deployment.yaml` is replaced at deploy time by the CD pipeline — do not change it manually.

---


---

## Terraform Modules Reference

### module `resource_group`

| Input | Description | Default |
|-------|-------------|---------|
| `name` | Resource group name | — |
| `location` | Azure region | — |
| `tags` | Resource tags | `{}` |

### module `network`

| Input | Description | Default |
|-------|-------------|---------|
| `vnet_name` | VNet name | — |
| `vnet_address_space` | VNet CIDR list | — |
| `aks_subnet_prefix` | AKS subnet CIDR | — |
| `acr_subnet_prefix` | ACR PE subnet CIDR | — |
| `agents_subnet_prefix` | ADO agents subnet CIDR | — |

Key outputs: `vnet_id`, `aks_subnet_id`, `acr_subnet_id`, `agents_subnet_id`, `acr_private_dns_zone_id`

### module `acr`

| Input | Description | Default |
|-------|-------------|---------|
| `acr_name` | Registry name (globally unique) | — |
| `sku` | Must be `Premium` | `"Premium"` |
| `acr_subnet_id` | Private endpoint subnet | — |
| `acr_private_dns_zone_id` | DNS zone for resolution | — |

Key outputs: `acr_id`, `acr_name`, `login_server`

### module `aks`

| Input | Description | Default |
|-------|-------------|---------|
| `cluster_name` | AKS cluster name | — |
| `kubernetes_version` | K8s version (`null` = latest) | `null` |
| `node_count` | Default node pool size | `2` |
| `vm_size` | Node VM SKU | `Standard_DS2_v2` |
| `acr_id` | ACR resource ID for AcrPull | — |
| `service_cidr` | Kubernetes service CIDR | `192.168.0.0/16` |

Key outputs: `cluster_id`, `cluster_name`, `private_fqdn`, `kube_config_raw` (sensitive)

---

## Destroy Infrastructure

```bash
cd terraform-azure-acr-aks
terraform destroy
```

> Private endpoints and private DNS zone links must be removed before the VNet can be deleted. `terraform destroy` handles this in the correct order automatically.

---

## Security Notes

- **No admin credentials on ACR** — `admin_enabled = false`; authentication is via managed identity (AKS) and service principal (ADO)
- **No public ACR endpoint** — `public_network_access_enabled = false`; registry is only reachable via private endpoint
- **Private AKS API server** — `private_cluster_enabled = true`; the Kubernetes API is not exposed to the internet
- **AcrPull via managed identity** — AKS kubelet identity has the `AcrPull` role; no `imagePullSecrets` are needed in manifests
- **ADO agents isolated** — agents subnet has an NSG blocking inbound internet traffic
- **State file** — use the remote backend (`backend "azurerm"`) in team environments; never commit `terraform.tfstate` to source control

---

## Author

**Rajdip Chakraborty**
- **GitHub**: [@rajdip-chakraborty-dev](https://github.com/rajdip-chakraborty-dev)
- **LinkedIn**: [Rajdip Chakraborty](https://www.linkedin.com/in/rajdip-chakraborty-2899bb215)
