# Path to the CSV file and log file
$CsvFile = "$PSScriptRoot\VM-Config.csv"
$LogFile = "$PSScriptRoot\Log.txt"

# Function to log messages
function New-LogEntry {
    param (
        [string]$Message
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "$Timestamp - $Message"
    Add-Content -Path $LogFile -Value $LogEntry
    Write-Output $LogEntry
}

# Import the CSV file with semicolon delimiter
try {
    $VmConfigs = Import-Csv -Path $CsvFile -Delimiter ';'
    New-LogEntry "CSV file imported successfully."
} catch {
    New-LogEntry "Error importing CSV file: $_"
    exit
}

# Iterate through each VM configuration and create the VM
foreach ($VmConfig in $VmConfigs) {
    $VMName = $VmConfig.Name
    $Memory = $VmConfig.Memory
    $Processors = $VmConfig.Processors
    $DiskSize = $VmConfig.DiskSize

    New-LogEntry "Starting creation of VM: $VMName"

    try {
        # Create a new VM
        New-VM -Name $VMName -MemoryStartupBytes $Memory -Generation 2
        New-LogEntry "VM '$VMName' created with $Memory memory and $Processors processors."
    } catch {
        New-LogEntry "Error creating VM '$VMName': $_"
        continue
    }

    try {
        # Set the number of processors
        Set-VMProcessor -VMName $VMName -Count $Processors
        New-LogEntry "VM '$VMName' processor count set to $Processors."
    } catch {
        New-LogEntry "Error setting processors for VM '$VMName': $_"
        continue
    }

    try {
        # Create and add a new virtual hard disk
        $VhdPath = "C:\path\to\vhds\$VMName.vhdx"
        New-VHD -Path $VhdPath -SizeBytes $DiskSize -Dynamic
        Add-VMHardDiskDrive -VMName $VMName -Path $VhdPath
        New-LogEntry "Virtual hard disk '$VhdPath' added to VM '$VMName' with size $DiskSize."
    } catch {
        New-LogEntry "Error creating virtual hard disk for VM '$VMName': $_"
        continue
    }

    try {
        # Ensure the VM has only one network adapter and connect it to the External Switch
        Get-VMNetworkAdapter -VMName $VMName | Remove-VMNetworkAdapter -Confirm:$false
        Add-VMNetworkAdapter -VMName $VMName -SwitchName "External Switch"
        New-LogEntry "Network adapter added to VM '$VMName' connected to 'External Switch'."
    } catch {
        New-LogEntry "Error setting network adapter for VM '$VMName': $_"
        continue
    }

    New-LogEntry "VM '$VMName' created successfully."
}
