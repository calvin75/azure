# Ref: 
# https://docs.microsoft.com/en-us/azure/load-balancer/load-balancer-get-started-internet-arm-ps

$Sub1 = "Your Subscription Name"

$rgName = 'TestInternetLBrg'
$location = 'East US' 
$storageType = 'StandardLRS'
$backendSubnetName = 'backend'
$backendaddressprefix = '10.4.2.0/24'
$vnetname= 'TestLB3Vnet'
$vnetaddressprefix = '10.4.0.0/16'
$frontendprivIp = '10.4.2.5'
$frontendIPname = 'LB3-FrontendIP'
$backendpoolname = 'LB3-backend'
$lbname = 'TestInternetLB'

login-AzureRmAccount
Select-AzureRmSubscription -SubscriptionName $Sub1

New-AzureRmResourceGroup -Name $rgName -location $location

$backendSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $backendSubnetName -AddressPrefix $backendaddressprefix


$vnet= New-AzureRmVirtualNetwork -Name $vnetname -ResourceGroupName $rgName -Location $location -AddressPrefix $vnetaddressprefix -Subnet $backendSubnet


$publicIP = New-AzureRmPublicIpAddress -Name PublicIp -ResourceGroupName $rgName -Location $location -AllocationMethod Static -DomainNameLabel hyukloadbalancer

$frontendIP = New-AzureRmLoadBalancerFrontendIpConfig -Name $frontendIPname -PublicIpAddress $publicIP


$beaddresspool= New-AzureRmLoadBalancerBackendAddressPoolConfig -Name $backendpoolname




$inboundNATRule1= New-AzureRmLoadBalancerInboundNatRuleConfig -Name "SSH1" -FrontendIpConfiguration $frontendIP -Protocol TCP -FrontendPort 2022 -BackendPort 22

$inboundNATRule2= New-AzureRmLoadBalancerInboundNatRuleConfig -Name "SSH2" -FrontendIpConfiguration $frontendIP -Protocol TCP -FrontendPort 3022 -BackendPort 22

$inboundNATRule3= New-AzureRmLoadBalancerInboundNatRuleConfig -Name "SSH3" -FrontendIpConfiguration $frontendIP -Protocol TCP -FrontendPort 4022 -BackendPort 22

$inboundNATRule4= New-AzureRmLoadBalancerInboundNatRuleConfig -Name "SSH4" -FrontendIpConfiguration $frontendIP -Protocol TCP -FrontendPort 5022 -BackendPort 22


$healthProbe = New-AzureRmLoadBalancerProbeConfig -Name "HealthProbe" -RequestPath "HealthProbe" -Protocol http -Port 80 -IntervalInSeconds 15 -ProbeCount 2

$lbrule = New-AzureRmLoadBalancerRuleConfig -Name "HTTP" -FrontendIpConfiguration $frontendIP -BackendAddressPool $beAddressPool -Probe $healthProbe -Protocol Tcp -FrontendPort 80 -BackendPort 80


$lb = New-AzureRmLoadBalancer -ResourceGroupName $rgName -Name $lbname -Location $location -FrontendIpConfiguration $frontendIP -InboundNatRule $inboundNATRule1,$inboundNatRule2, $inboundNATRule3,$inboundNATRule4 -LoadBalancingRule $lbrule -BackendAddressPool $beAddressPool -Probe $healthProbe


$vnet = Get-AzureRmVirtualNetwork -Name $vnetname -ResourceGroupName $rgName

$backendSubnet = Get-AzureRmVirtualNetworkSubnetConfig -Name $backendSubnetName -VirtualNetwork $vnet

$backendnic1= New-AzureRmNetworkInterface -ResourceGroupName $rgName -Name lb-nic1-be -Location $location -PrivateIpAddress 10.4.2.6 -Subnet $backendSubnet -LoadBalancerBackendAddressPool $lb.BackendAddressPools[0] -LoadBalancerInboundNatRule $lb.InboundNatRules[0]

$backendnic2= New-AzureRmNetworkInterface -ResourceGroupName $rgName -Name lb-nic2-be -Location $location -PrivateIpAddress 10.4.2.7 -Subnet $backendSubnet -LoadBalancerBackendAddressPool $lb.BackendAddressPools[0] -LoadBalancerInboundNatRule $lb.InboundNatRules[1]

$backendnic3= New-AzureRmNetworkInterface -ResourceGroupName $rgName -Name lb-nic3-be -Location $location -PrivateIpAddress 10.4.2.8 -Subnet $backendSubnet -LoadBalancerBackendAddressPool $lb.BackendAddressPools[0] -LoadBalancerInboundNatRule $lb.InboundNatRules[2]

$backendnic4= New-AzureRmNetworkInterface -ResourceGroupName $rgName -Name lb-nic4-be -Location $location -PrivateIpAddress 10.4.2.9 -Subnet $backendSubnet -LoadBalancerBackendAddressPool $lb.BackendAddressPools[0] -LoadBalancerInboundNatRule $lb.InboundNatRules[3]


$availabilitySet = New-AzureRmAvailabilitySet `
   -Location $location `
   -Name myAvailabilitySet `
   -ResourceGroupName $rgName `
   -Managed `
   -PlatformFaultDomainCount 2 `
   -PlatformUpdateDomainCount 2

# Create VMs

# Define a credential object
for ($i=1; $i -le 4; $i++)
{
    $vmname = 'myVM' + $i

	$securePassword = ConvertTo-SecureString ' ' -AsPlainText -Force
	$cred = New-Object System.Management.Automation.PSCredential ("hyuk", $securePassword)

	# Create a virtual machine configuration
	$vmConfig = New-AzureRmVMConfig -VMName $vmname -VMSize Standard_D1 -AvailabilitySetId $availabilitySet.Id | `
	Set-AzureRmVMOperatingSystem -Linux -ComputerName $vmname -Credential $cred -DisablePasswordAuthentication | `
	Set-AzureRmVMSourceImage -PublisherName Canonical -Offer UbuntuServer -Skus 14.04.2-LTS -Version latest | `
	Add-AzureRmVMNetworkInterface -Id $backendnic.Id

	# Configure SSH Keys
	$sshPublicKey = Get-Content "$env:USERPROFILE\.ssh\id_rsa.pub"
	Add-AzureRmVMSshPublicKey -VM $vmconfig -KeyData $sshPublicKey -Path "/home/hyuk/.ssh/authorized_keys"

	New-AzureRmVM -ResourceGroupName $rgname -Location $location -VM $vmConfig
}
