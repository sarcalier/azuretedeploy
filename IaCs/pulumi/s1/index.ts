import * as pulumi from "@pulumi/pulumi";
import * as azure from "@pulumi/azure";

const config = new pulumi.Config();
const prefix = config.get("prefix") || "RuslanG-RG";
const exampleResourceGroup = new azure.core.ResourceGroup("exampleResourceGroup", {
    name: `${prefix}-IaCs_pulumi`,
    location: "West Europe",
});
const exampleVirtualNetwork = new azure.network.VirtualNetwork("exampleVirtualNetwork", {
    name: "vnet01",
    addressSpaces: ["10.10.0.0/16"],
    location: exampleResourceGroup.location,
    resourceGroupName: exampleResourceGroup.name,
});
const exampleSubnet = new azure.network.Subnet("exampleSubnet", {
    name: "AzureBastionSubnet",
    resourceGroupName: exampleResourceGroup.name,
    virtualNetworkName: exampleVirtualNetwork.name,
    addressPrefixes: ["10.10.1.0/24"],
});
const example2 = new azure.network.Subnet("example2", {
    name: "Subnet02",
    resourceGroupName: exampleResourceGroup.name,
    virtualNetworkName: exampleVirtualNetwork.name,
    addressPrefixes: ["10.10.2.0/24"],
});
const examplePublicIp = new azure.network.PublicIp("examplePublicIp", {
    name: "pubpip",
    location: exampleResourceGroup.location,
    resourceGroupName: exampleResourceGroup.name,
    allocationMethod: "Static",
    sku: "Standard",
});
const exampleBastionHost = new azure.compute.BastionHost("exampleBastionHost", {
    name: "bastion01",
    location: exampleResourceGroup.location,
    resourceGroupName: exampleResourceGroup.name,
    ipConfiguration: {
        name: "IPconfiguration",
        subnetId: exampleSubnet.id,
        publicIpAddressId: examplePublicIp.id,
    },
});
