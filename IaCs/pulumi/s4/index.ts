import * as pulumi from "@pulumi/pulumi";
import * as azure from "@pulumi/azure";
import * as random from "@pulumi/random";

const config = new pulumi.Config();
//const prefix = config.requireObject("prefix");
const prefix = config.get("prefix") || "iacrg";
const adminUserName = config.get("adminUserName") || "tstadmin";
const mainResourceGroup = new azure.core.ResourceGroup("mainResourceGroup", {
    name: `${prefix}-IaCs-pl-s04`,
    location: "West Europe",
});
const pass1 = new random.RandomString("pass1", {
    length: 16,
    upper: true,
    lower: true,
    number: true,
    special: true,
});
const hash = new random.RandomString("hash", {
    length: 5,
    upper: false,
    lower: true,
    number: true,
    special: false,
});
const mainAnalyticsWorkspace = new azure.operationalinsights.AnalyticsWorkspace("mainAnalyticsWorkspace", {
    name: pulumi.interpolate`logs-01-${hash.result}`,
    location: mainResourceGroup.location,
    resourceGroupName: mainResourceGroup.name,
    sku: "PerGB2018",
    retentionInDays: 30,
    dailyQuotaGb: 5,
});
const mainActionGroup = new azure.monitoring.ActionGroup("mainActionGroup", {
    name: "CriticalAlertsAction",
    resourceGroupName: mainResourceGroup.name,
    shortName: "p0action",
    emailReceivers: [{
        name: "sendtodevops",
        emailAddress: "devops@contoso.com",
        useCommonAlertSchema: true,
    }],
});
const mainScheduledQueryRulesAlert = new azure.monitoring.ScheduledQueryRulesAlert("mainScheduledQueryRulesAlert", {
    name: `${prefix}-queryrule1`,
    location: mainResourceGroup.location,
    resourceGroupName: mainResourceGroup.name,
    action: {
        actionGroups: [mainActionGroup.id],
    },
    dataSourceId: mainAnalyticsWorkspace.id,
    description: "Alert when total results cross threshold",
    enabled: true,
    query: `Heartbeat
| where Computer contains "vm01"
`,
    severity: 1,
    frequency: 5,
    timeWindow: 5,
    trigger: {
        operator: "LessThan",
        threshold: 1,
    },
});
const main2ScheduledQueryRulesAlert = new azure.monitoring.ScheduledQueryRulesAlert("main2ScheduledQueryRulesAlert", {
    name: `${prefix}-queryrule2`,
    location: mainResourceGroup.location,
    resourceGroupName: mainResourceGroup.name,
    action: {
        actionGroups: [mainActionGroup.id],
    },
    dataSourceId: mainAnalyticsWorkspace.id,
    description: "Alert when total results cross threshold",
    enabled: true,
    query: `Heartbeat
| where Computer contains "vm02"
`,
    severity: 1,
    frequency: 5,
    timeWindow: 5,
    trigger: {
        operator: "LessThan",
        threshold: 1,
    },
});
const mainVirtualNetwork = new azure.network.VirtualNetwork("mainVirtualNetwork", {
    name: "vpc01",
    addressSpaces: ["10.10.0.0/16"],
    location: mainResourceGroup.location,
    resourceGroupName: mainResourceGroup.name,
});
const sub01 = new azure.network.Subnet("sub01", {
    name: "subnet01",
    resourceGroupName: mainResourceGroup.name,
    virtualNetworkName: mainVirtualNetwork.name,
    addressPrefixes: ["10.10.4.0/24"],
    serviceEndpoints: ["Microsoft.Sql"],
});
const sub02 = new azure.network.Subnet("sub02", {
    name: "subnet02",
    resourceGroupName: mainResourceGroup.name,
    virtualNetworkName: mainVirtualNetwork.name,
    addressPrefixes: ["10.10.5.0/24"],
    serviceEndpoints: ["Microsoft.Sql"],
});
const bas01 = new azure.network.Subnet("bas01", {
    name: "AzureBastionSubnet",
    resourceGroupName: mainResourceGroup.name,
    virtualNetworkName: mainVirtualNetwork.name,
    addressPrefixes: ["10.10.6.0/27"],
});
const mainPublicIp = new azure.network.PublicIp("mainPublicIp", {
    name: "pubpip",
    location: mainResourceGroup.location,
    resourceGroupName: mainResourceGroup.name,
    allocationMethod: "Static",
    sku: "Standard",
});
const mainLoadBalancer = new azure.lb.LoadBalancer("mainLoadBalancer", {
    name: "web-lb",
    location: mainResourceGroup.location,
    resourceGroupName: mainResourceGroup.name,
    sku: "Standard",
    frontendIpConfigurations: [{
        name: "PublicIPAddress",
        publicIpAddressId: mainPublicIp.id,
    }],
});
const bpepool = new azure.lb.BackendAddressPool("bpepool", {
    resourceGroupName: mainResourceGroup.name,
    loadbalancerId: mainLoadBalancer.id,
    name: "BackEndAddressPool01",
});
const bpepool2 = new azure.lb.BackendAddressPool("bpepool2", {
    resourceGroupName: mainResourceGroup.name,
    loadbalancerId: mainLoadBalancer.id,
    name: "BackEndAddressPool02",
});
const mainProbe = new azure.lb.Probe("mainProbe", {
    resourceGroupName: mainResourceGroup.name,
    loadbalancerId: mainLoadBalancer.id,
    name: "http-running-probe",
    port: 80,
});
const lbnatrulehttp = new azure.lb.Rule("lbnatrulehttp", {
    resourceGroupName: mainResourceGroup.name,
    loadbalancerId: mainLoadBalancer.id,
    name: "http",
    protocol: "Tcp",
    frontendPort: 80,
    backendPort: 80,
    backendAddressPoolId: bpepool.id,
    frontendIpConfigurationName: "PublicIPAddress",
    probeId: mainProbe.id,
});
const lbnatrulessh = new azure.lb.Rule("lbnatrulessh", {
    resourceGroupName: mainResourceGroup.name,
    loadbalancerId: mainLoadBalancer.id,
    name: "ssh",
    protocol: "Tcp",
    frontendPort: 22,
    backendPort: 22,
    backendAddressPoolId: bpepool.id,
    frontendIpConfigurationName: "PublicIPAddress",
});
//probe_id                       = azurerm_lb_probe.vmsspatch.id
const mainNetworkSecurityGroup = new azure.network.NetworkSecurityGroup("mainNetworkSecurityGroup", {
    name: `${prefix}-NSG`,
    location: mainResourceGroup.location,
    resourceGroupName: mainResourceGroup.name,
    securityRules: [
        {
            name: "SSH",
            priority: 1001,
            direction: "Inbound",
            access: "Allow",
            protocol: "Tcp",
            sourcePortRange: "*",
            destinationPortRange: "22",
            sourceAddressPrefix: "*",
            destinationAddressPrefix: "*",
        },
        {
            name: "HTTP",
            priority: 1002,
            direction: "Inbound",
            access: "Allow",
            protocol: "Tcp",
            sourcePortRange: "*",
            destinationPortRange: "80",
            sourceAddressPrefix: "*",
            destinationAddressPrefix: "*",
        },
    ],
});
const nsg1 = new azure.network.SubnetNetworkSecurityGroupAssociation("nsg1", {
    subnetId: sub01.id,
    networkSecurityGroupId: mainNetworkSecurityGroup.id,
});
const nsg2 = new azure.network.SubnetNetworkSecurityGroupAssociation("nsg2", {
    subnetId: sub02.id,
    networkSecurityGroupId: mainNetworkSecurityGroup.id,
});
const mainNetworkInterface = new azure.network.NetworkInterface("mainNetworkInterface", {
    name: `${prefix}-nic`,
    location: mainResourceGroup.location,
    resourceGroupName: mainResourceGroup.name,
    ipConfigurations: [{
        name: "testconfiguration1",
        subnetId: sub01.id,
        privateIpAddressAllocation: "Dynamic",
    }],
});
const main2NetworkInterface = new azure.network.NetworkInterface("main2NetworkInterface", {
    name: `${prefix}-nic2`,
    location: mainResourceGroup.location,
    resourceGroupName: mainResourceGroup.name,
    ipConfigurations: [{
        name: "testconfiguration2",
        subnetId: sub02.id,
        privateIpAddressAllocation: "Dynamic",
    }],
});
const asso1 = new azure.network.NetworkInterfaceBackendAddressPoolAssociation("asso1", {
    networkInterfaceId: mainNetworkInterface.id,
    ipConfigurationName: "testconfiguration1",
    backendAddressPoolId: bpepool.id,
});
const asso2 = new azure.network.NetworkInterfaceBackendAddressPoolAssociation("asso2", {
    networkInterfaceId: main2NetworkInterface.id,
    ipConfigurationName: "testconfiguration2",
    backendAddressPoolId: bpepool.id,
});
const basIp = new azure.network.PublicIp("basIp", {
    name: "basip",
    location: mainResourceGroup.location,
    resourceGroupName: mainResourceGroup.name,
    allocationMethod: "Static",
    sku: "Standard",
});
const mainBastionHost = new azure.compute.BastionHost("mainBastionHost", {
    name: "bastion01",
    location: mainResourceGroup.location,
    resourceGroupName: mainResourceGroup.name,
    ipConfiguration: {
        name: "IPconfiguration",
        subnetId: bas01.id,
        publicIpAddressId: basIp.id,
    },
});
const sqlserver1 = new azure.sql.SqlServer("sqlserver1", {
    name: pulumi.interpolate`azuresqlserver1-${hash.result}`,
    resourceGroupName: mainResourceGroup.name,
    location: mainResourceGroup.location,
    version: "12.0",
    administratorLogin: "4dm1n157r470r",
    administratorLoginPassword: pass1.result,
});
const sqlserver2 = new azure.sql.SqlServer("sqlserver2", {
    name: pulumi.interpolate`azuresqlserver2-${hash.result}`,
    resourceGroupName: mainResourceGroup.name,
    location: mainResourceGroup.location,
    version: "12.0",
    administratorLogin: "4dm1n157r470r",
    administratorLoginPassword: pass1.result,
});
const sqlvnetrule1 = new azure.sql.VirtualNetworkRule("sqlvnetrule1", {
    name: "sql-vnet-rule",
    resourceGroupName: mainResourceGroup.name,
    serverName: sqlserver1.name,
    subnetId: sub01.id,
});
const sqlvnetrule2 = new azure.sql.VirtualNetworkRule("sqlvnetrule2", {
    name: "sql-vnet-rule2",
    resourceGroupName: mainResourceGroup.name,
    serverName: sqlserver2.name,
    subnetId: sub02.id,
});
//const lbIp = pulumi.all([mainPublicIp.name, mainResourceGroup.name]).apply(([mainPublicIpName, mainResourceGroupName]) => azure.network.getPublicIP({
//    name: mainPublicIpName,
//    resourceGroupName: mainResourceGroupName,
//}));
//export const lbPublicIP = lbIp.ipAddress;
export const vMResourceGroup = mainResourceGroup.name;
export const vMAdminUserName = adminUserName;
export const vMAdminPassword = pass1.result;
const mainVirtualMachine = new azure.compute.VirtualMachine("mainVirtualMachine", {
    name: `${prefix}-vm01`,
    location: mainResourceGroup.location,
    resourceGroupName: mainResourceGroup.name,
    networkInterfaceIds: [mainNetworkInterface.id],
    vmSize: "Standard_DS1_v2",
    zones: "1",
    storageImageReference: {
        publisher: "Canonical",
        offer: "UbuntuServer",
        sku: "18.04-LTS",
        version: "latest",
    },
    storageOsDisk: {
        name: "myosdisk1",
        caching: "ReadWrite",
        createOption: "FromImage",
        managedDiskType: "Standard_LRS",
    },
    osProfile: {
        computerName: "vm01",
        adminUsername: adminUserName,
        adminPassword: pass1.result,
    },
    osProfileLinuxConfig: {
        disablePasswordAuthentication: false,
    },
    tags: {
        environment: "staging",
    },
});
const mainExtension = new azure.compute.Extension("mainExtension", {
    name: "nginx",
    virtualMachineId: mainVirtualMachine.id,
    publisher: "Microsoft.Azure.Extensions",
    type: "CustomScript",
    typeHandlerVersion: "2.0",
    settings: `    {
        "commandToExecute": "apt-get update && apt-get install -y nginx "
    }
`,
});
const main2VirtualMachine = new azure.compute.VirtualMachine("main2VirtualMachine", {
    name: `${prefix}-vm02`,
    location: mainResourceGroup.location,
    resourceGroupName: mainResourceGroup.name,
    networkInterfaceIds: [main2NetworkInterface.id],
    vmSize: "Standard_DS1_v2",
    zones: "2",
    storageImageReference: {
        publisher: "Canonical",
        offer: "UbuntuServer",
        sku: "18.04-LTS",
        version: "latest",
    },
    storageOsDisk: {
        name: "myosdisk2",
        caching: "ReadWrite",
        createOption: "FromImage",
        managedDiskType: "Standard_LRS",
    },
    osProfile: {
        computerName: "vm02",
        adminUsername: adminUserName,
        adminPassword: pass1.result,
    },
    osProfileLinuxConfig: {
        disablePasswordAuthentication: false,
    },
    tags: {
        environment: "staging",
    },
});
const main2Extension = new azure.compute.Extension("main2Extension", {
    name: "nginx",
    virtualMachineId: main2VirtualMachine.id,
    publisher: "Microsoft.Azure.Extensions",
    type: "CustomScript",
    typeHandlerVersion: "2.0",
    settings: `    {
        "commandToExecute": "apt-get update && apt-get install -y nginx "
    }
`,
});
const omsMma1 = new azure.compute.Extension("omsMma1", {
    name: `${prefix}-OMSExtension1`,
    virtualMachineId: mainVirtualMachine.id,
    publisher: "Microsoft.EnterpriseCloud.Monitoring",
    type: "OmsAgentForLinux",
    typeHandlerVersion: "1.8",
    autoUpgradeMinorVersion: true,
    settings: pulumi.interpolate`    {
      "workspaceId" :  "${mainAnalyticsWorkspace.workspaceId}"
    }
`,
    protectedSettings: pulumi.interpolate`    {
      "workspaceKey" : "${mainAnalyticsWorkspace.primarySharedKey}"
    }
`,
});
const omsMma2 = new azure.compute.Extension("omsMma2", {
    name: `${prefix}-OMSExtension2`,
    virtualMachineId: main2VirtualMachine.id,
    publisher: "Microsoft.EnterpriseCloud.Monitoring",
    type: "OmsAgentForLinux",
    typeHandlerVersion: "1.8",
    autoUpgradeMinorVersion: true,
    settings: pulumi.interpolate`    {
      "workspaceId" :  "${mainAnalyticsWorkspace.workspaceId}"
    }
`,
    protectedSettings: pulumi.interpolate`    {
      "workspaceKey" : "${mainAnalyticsWorkspace.primarySharedKey}"
    }
`,
});
