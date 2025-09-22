# Azure Virtual Desktop (AVD) Development Environment

## Current State Overview
**Date:** 2025-09-22  
**Azure Subscription:** Microsoft Azure Sponsorship  
**VM Status:** Deallocated (Stopped)

## Infrastructure Architecture

```mermaid
graph TB
    subgraph "Azure Subscription"
        subgraph "Resource Group: RG-AVD-WORKSPACES"
            HP[Host Pool: hp-avd<br/>Type: Pooled<br/>Load Balancer: BreadthFirst]
            AG[Application Group: ag-desktop<br/>Type: Desktop]
            WS[Workspace: ws-avd]
            VM[Session Host VM<br/>evergreen-avd-jez-20250912-073347<br/>Status: Deallocated]
            Gallery[Shared Image Gallery<br/>avd_secure_gallery]
            Identity[Managed Identity<br/>avd-certificate-identity]
            
            subgraph "Gallery Images"
                IMG1[SecureVDI-TrustedLaunch<br/>v6.0.20250807]
                IMG2[SecureVDI-TrustedLaunch<br/>v7.0.20250807]
                IMG3[SecureVDI-TrustedLaunch<br/>v8.0.20250807]
            end
        end
        
        subgraph "Resource Group: RG-SECURE-DEVOPS-20250119101101"
            Bastion[Azure Bastion<br/>secure-bastion<br/>Scale Units: 2]
            DevVM[Dev VM<br/>vm-dev-uksouth<br/>Location: UK South]
        end
        
        subgraph "Resource Group: SAAS-PLATFORM-RG"
            JumpBox[test-jumpbox<br/>Location: UK South]
        end
    end
    
    HP --> AG
    AG --> WS
    HP --> VM
    Gallery --> IMG1
    Gallery --> IMG2
    Gallery --> IMG3
    VM -.->|Uses Image| Gallery
    VM -.->|Managed by| Identity
    Bastion -.->|Secure Access| VM
    Bastion -.->|Secure Access| DevVM
    Bastion -.->|Secure Access| JumpBox

    style VM fill:#f99,stroke:#333,stroke-width:2px
    style HP fill:#9ff,stroke:#333,stroke-width:2px
    style Bastion fill:#9f9,stroke:#333,stroke-width:2px
```

## AVD Build Process Flow

```mermaid
flowchart LR
    subgraph "AVD Infrastructure Build"
        Start[Start] --> CheckRG{Resource Group<br/>Exists?}
        CheckRG -->|No| CreateRG[Create RG-AVD-WORKSPACES]
        CheckRG -->|Yes| CheckGallery{Gallery<br/>Exists?}
        CreateRG --> CheckGallery
        
        CheckGallery -->|No| CreateGallery[Create Shared<br/>Image Gallery]
        CheckGallery -->|Yes| CheckImages{Images<br/>Available?}
        CreateGallery --> UploadImages[Upload/Create<br/>Gallery Images]
        UploadImages --> CheckImages
        
        CheckImages -->|Yes| CreateHP[Create Host Pool<br/>hp-avd]
        CreateHP --> ConfigHP[Configure:<br/>- Pooled Type<br/>- BreadthFirst LB<br/>- Max Sessions: 10]
        
        ConfigHP --> CreateAG[Create Application<br/>Group]
        CreateAG --> CreateWS[Create Workspace]
        CreateWS --> LinkAGWS[Link AG to<br/>Workspace]
        
        LinkAGWS --> CreateVM[Create Session<br/>Host VM]
        CreateVM --> ConfigVM[Configure VM:<br/>- Standard_B2s<br/>- Linux OS<br/>- East US]
        
        ConfigVM --> JoinHP[Join VM to<br/>Host Pool]
        JoinHP --> InstallAgent[Install AVD<br/>Agent]
        
        InstallAgent --> ConfigRDP[Configure RDP:<br/>- Clipboard: Disabled<br/>- Printers: Disabled<br/>- Audio: Disabled<br/>- USB Redirect: Enabled]
        
        ConfigRDP --> CreateIdentity[Create Managed<br/>Identity]
        CreateIdentity --> AssignRoles[Assign RBAC<br/>Roles]
        
        AssignRoles --> ConfigBastion[Configure Bastion<br/>Access]
        ConfigBastion --> Complete[AVD Ready]
    end
    
    style Start fill:#9f9
    style Complete fill:#f9f
```

## VM Configuration

### Session Host Details
- **Name:** evergreen-avd-jez-20250912-073347
- **Size:** Standard_B2s (2 vCPUs, 4 GB RAM)
- **OS:** Linux
- **Location:** East US
- **Current State:** Deallocated (VM stopped to save costs)

### Host Pool Configuration
- **Name:** hp-avd
- **Type:** Pooled (multiple users can share VMs)
- **Load Balancer:** BreadthFirst (fill first VM before using next)
- **Max Sessions:** 10 users per VM
- **Start VM on Connect:** Disabled
- **Validation Environment:** False (Production)

### Custom RDP Properties
```
drivestoredirect:s:;
usbdevicestoredirect:s:;
redirectclipboard:i:0;        # Clipboard disabled
redirectprinters:i:0;          # Printers disabled
audiomode:i:0;                 # Audio disabled
videoplaybackmode:i:1;         # Video playback enabled
devicestoredirect:s:*;         # All devices redirect
redirectcomports:i:1;          # COM ports enabled
redirectsmartcards:i:1;        # Smart cards enabled
enablecredsspsupport:i:1;      # CredSSP enabled
redirectwebauthn:i:1;          # WebAuthn enabled
use multimon:i:1;              # Multi-monitor enabled
```

## Network Architecture

```mermaid
graph TB
    subgraph "Internet"
        User[User/Developer]
    end
    
    subgraph "Azure Network"
        subgraph "Bastion Subnet"
            Bastion[Azure Bastion<br/>bst-d39ff422-9aaf-4c8e-a15b-48f4721fa346<br/>IP Connect: Enabled<br/>Tunneling: Enabled]
        end
        
        subgraph "AVD Subnet"
            AVDVM[AVD Session Host<br/>Private IP Only]
        end
        
        subgraph "Dev Subnet"
            DevVM[Development VM<br/>vm-dev-uksouth]
            JumpBox[Jump Box<br/>test-jumpbox]
        end
    end
    
    User -->|HTTPS/443| Bastion
    Bastion -->|RDP/SSH| AVDVM
    Bastion -->|RDP/SSH| DevVM
    Bastion -->|RDP/SSH| JumpBox
    
    style Bastion fill:#9f9,stroke:#333,stroke-width:2px
    style AVDVM fill:#f99,stroke:#333,stroke-width:2px
```

## Image Gallery

### Shared Image Gallery: avd_secure_gallery
**Location:** UK South

**Available Images:**
1. **SecureVDI-TrustedLaunch v6.0.20250807**
2. **SecureVDI-TrustedLaunch v7.0.20250807**
3. **SecureVDI-TrustedLaunch v8.0.20250807**

All images are configured with Trusted Launch for enhanced security.

## Access Methods

### 1. Azure Bastion Access
- **Bastion Host:** secure-bastion
- **DNS:** bst-d39ff422-9aaf-4c8e-a15b-48f4721fa346.bastion.azure.com
- **Features:**
  - IP Connect: Enabled
  - Tunneling: Enabled
  - File Copy: Disabled
  - Copy/Paste: Disabled
  - Scale Units: 2

### 2. AVD Client Access
- Connect via AVD client application
- Workspace: ws-avd
- Application Group: ag-desktop

## Security Configuration

### Managed Identity
- **Name:** avd-certificate-identity
- **Location:** UK South
- **Purpose:** Certificate management and authentication

### Security Features
- Trusted Launch VMs
- Managed Identity for authentication
- Bastion for secure access (no public IPs)
- Disabled clipboard and printer redirection
- WebAuthn support for passwordless auth

## Current Issues & Status

### VM State
- **Current Status:** Deallocated (Stopped)
- **Action Required:** Start VM before connecting
- **Command to Start:**
  ```bash
  az vm start -n evergreen-avd-jez-20250912-073347 -g RG-AVD-WORKSPACES
  ```

### Cost Optimization
- VM is currently deallocated to save costs
- Standard_B2s is a burstable instance type
- Consider enabling "Start VM on Connect" for automatic startup

## Management Commands

### Start AVD VM
```bash
az vm start -n evergreen-avd-jez-20250912-073347 -g RG-AVD-WORKSPACES
```

### Stop AVD VM
```bash
az vm deallocate -n evergreen-avd-jez-20250912-073347 -g RG-AVD-WORKSPACES
```

### Check VM Status
```bash
az vm get-instance-view -n evergreen-avd-jez-20250912-073347 -g RG-AVD-WORKSPACES --query 'instanceView.statuses[].displayStatus' -o tsv
```

### Connect via Bastion
```bash
az network bastion ssh -n secure-bastion -g rg-secure-devops-20250119101101 --target-resource-id /subscriptions/80265df9-bba2-4ad2-88af-e002fd2ca230/resourceGroups/RG-AVD-WORKSPACES/providers/Microsoft.Compute/virtualMachines/evergreen-avd-jez-20250912-073347 --auth-type ssh-key --ssh-key ~/.ssh/id_rsa --username azureuser
```

## Next Steps

1. **Start the VM** if you need to access the AVD environment
2. **Configure user assignments** in the Application Group
3. **Install applications** on the session host
4. **Configure FSLogix** for user profile management (if needed)
5. **Set up monitoring** with Azure Monitor/Log Analytics