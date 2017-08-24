
# Azure Login
Login-AzureRmAccount

# Subscription ID
$subscriptionId = "87b7ed75-7074-41d6-9b53-3bf8894138bb"

# Resourcr Group of Snapshot
$resourceGroupName ="MyStorageTestRg"

# Snapshot Name
$snapshotName = "MyTestVMImage"

# Provide Shared Access Signature (SAS) expiry duration in seconds e.g. 3600.
# Know more about SAS here: https://docs.microsoft.com/en-us/azure/storage/storage-dotnet-shared-access-signature-part-1
$sasExpiryDuration = "7200"

# Remote Location - Storage Account
$storageAccountName = "hyuksnapshotstore"

# Remote Location - Storage Account's Container
$storageContainerName = "snapshot"

# Remote Location - Storage Account Access Key
$storageAccountKey = '6uttjKxbgX7WLDWnGUcO/HtdaSgt/pJnVW5nyQ3mhAZugPwaGvoi68fMB4mmC3ZtrEPVkb3piZ5l1VuLvPPhNA=='

# Remote Location - Storage Account's page blob filename
$destinationVHDFileName = "copiedsnapshot.vhd"
# Set the context to the subscription Id where Snapshot is created
Select-AzureRmSubscription -SubscriptionId $SubscriptionId

# Generate the SAS for the snapshot
$sas = Grant-AzureRmSnapshotAccess -ResourceGroupName $ResourceGroupName -SnapshotName $SnapshotName -DurationInSecond $sasExpiryDuration -Access Read
 
# Create the context for the storage account which will be used to copy Snapshot to the Storage Account
$destinationContext = New-AzureStorageContext –StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey 

# Copy the Snapshot(VHD) to the Storage Account
# https://docs.microsoft.com/en-us/powershell/module/azure.storage/start-azurestorageblobcopy?view=azurermps-4.3.1
# Start-AzureStorageBlobCopy -AbsoluteUri $sas.AccessSAS -DestContainer $storageContainerName -DestContext $destinationContext -DestBlob $destinationVHDFileName
Start-AzureStorageBlobCopy -ConcurrentTaskCount 4 -AbsoluteUri $sas.AccessSAS -DestContainer $storageContainerName -DestContext $destinationContext -DestBlob $destinationVHDFileName

# Gets the copy status of an Azure Storage blob
# https://docs.microsoft.com/en-us/powershell/module/azure.storage/get-azurestorageblobcopystate?view=azurermps-4.3.1
Get-AzureStorageBlobCopyState -Container $storageContainerName -Blob $destinationVHDFileName -Context $destinationContext -WaitForComplete

