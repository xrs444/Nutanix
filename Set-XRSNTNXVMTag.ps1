function Set-XRSNTNXVMTag {
  param (
  [Parameter (Mandatory = $true,HelpMessage="Address of Prism Central to query (https://...:9440")] [String]$RequestUri,
  [Parameter (Mandatory = $true,HelpMessage="Path to tag file in CSV format")] [String]$Filename,
  [Parameter (Mandatory = $true,HelpMessage="Username for request")] [String]$Username,
  [Parameter (Mandatory = $true,HelpMessage="Password in plain text for now, and yes this hurts my soul")] [String]$Password,
  [Parameter (Mandatory = $true,HelpMessage="Category to apply tags to")] [string]$Category
 )

<#
  .SYNOPSIS
  Sets tags on VMs under the specified category using a CSV file.

  .DESCRIPTION
  Calls Invoke-XRSNTNXAPICall to tag VMs by supplied CSV under a specified category.

  .PARAMETER RequestUri
  Specifies the full URI for the request, including the https:// and the :9440

  .PARAMETER $Username
  Username for the request

  .PARAMETER $Password
  Password for the request. In plaintext for now for reasons. This is not good, and when I work out how to get
  around the funkiness I will update this.

  .PARAMETER $Category
  Password for the request. In plaintext for now for reasons. This is not good, and when I work out how to get
  around the funkiness I will update this.

  .INPUTS
  There is currently no pipeline inputs configured.

  .OUTPUTS
  Tagged VMs in Nutanix!

  .EXAMPLE
  Set-XRSNTNXVMTag -RequestURI https://PrismCentralURL:9440/ -Username admin -Password 12345 -Category <DesiredCategory> -Filename <File.csv>

#>

$VMs = Import-CSV -Path $Filename

$UUIDArgs = @{
  RequestUri = $RequestUri
  Username = $Username
  Password = $Password
}

$UUIDs = Get-XRSNTNXVMUUIDLookupTable @UUIDArgs


Foreach($vm in $Vms){

$UUID = $UUIDs[$VM.Server]

# Get VM Details

  $GETAPIArgs = @{   
     RequestUri = "$($RequestUri)/api/nutanix/v3/vms/$($UUID)"
     Method = "GET"
     Username = $Username
     Password = $Password
  }

  $VMSpec = Invoke-XRSNTNXAPICall @GETAPIArgs

# Remove the Status field, and other unneeded entries:

  $VMSpec.psobject.properties.remove('status')
  $VMSpec.metadata.psobject.properties.remove('Last_Update_Time')
  $VMSpec.metadata.psobject.properties.remove('Creation_Time')

# Add tags

  $VMSpec.metadata.categories | Add-Member -MemberType NoteProperty -Name $category -Value $VM.tag

# Convert baXRS to JSON

  $Payload = ConvertTo-Json -InputObject $VMSpec -Depth 20

# Push the new config

  $PUTAPIArgs = @{   
     RequestUri = "$($RequestUri)/api/nutanix/v3/vms/$($UUID)"
     Method = "PUT"
     Username = $Username
     Password = $Password
     payload = $Payload
  }

  $Response = Invoke-XRSNTNXAPICall @PUTAPIArgs

}

Return $Response

}
  

