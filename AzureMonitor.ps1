# Prompt for Subscription ID or Name
$subscriptionIdOrName = Read-Host "Please enter the Subscription ID or Name"

# Attempt to set the context to the specified subscription
try {
    $context = Set-AzContext -SubscriptionId $subscriptionIdOrName -ErrorAction Stop
    Write-Output "Successfully switched to subscription: $($context.Subscription.Name)"
} catch {
    Write-Error "Failed to set Azure context. Check the Subscription ID or Name and try again."
    exit
}

# Get all virtual machine resources in the current subscription
try {
    $vms = Get-AzVM
    if ($vms) {
        Write-Output "Listing all VMs in the subscription:"
        $results = foreach ($vm in $vms) {
            # Attempt to retrieve diagnostic settings for each VM
            $diagSettings = Get-AzDiagnosticSetting -ResourceId $vm.Id -ErrorAction SilentlyContinue
            $monitoringStatus = if ($diagSettings -and $diagSettings.Count -gt 0) { 'Enabled' } else { 'Disabled' }

            # Output VM details along with monitoring status
            [PSCustomObject]@{
                VMName = $vm.Name
                ResourceGroupName = $vm.ResourceGroupName
                Location = $vm.Location
                OsType = $vm.StorageProfile.OsDisk.OsType
                MonitoringStatus = $monitoringStatus
            }
        }

        # Display results in the console
        $results | Format-Table -AutoSize

        # Export results to a CSV file in the current directory
        $csvFileName = "VMs_Monitoring_Status_$($context.Subscription.Id).csv"
        $results | Export-Csv -Path $csvFileName -NoTypeInformation
        Write-Output "VM details along with monitoring status have been exported to CSV at: $csvFileName"
    } else {
        Write-Output "No VMs found in the subscription."
    }
} catch {
    Write-Error "Failed to retrieve VMs or their diagnostic settings. Please check your permissions and network connectivity."
}
