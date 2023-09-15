

function Get-XRSNTNXVMUUIDFromName {
    param (
    [Parameter (Mandatory = $true,HelpMessage="Address of Prism Central to query (https://...:9440")] [String]$RequestUri,
    [Parameter (Mandatory = $true,HelpMessage="VM Name")] [String]$VMName,
    [Parameter (Mandatory = $true,HelpMessage="Username for request")] [String]$Username,
    [Parameter (Mandatory = $true,HelpMessage="Password in plain text for now, and yes this hurts my soul")] [String]$Password
   )

   <#
  .SYNOPSIS
  Returns a VM and its UUID

  .DESCRIPTION
  Calls Invoke-XRSNTNXAPICall to look up a VM UUID from it's name. If you need to do this for multiple VMs consider Get-XRSNutanixVMUUIDLookupTable

  .PARAMETER RequestUri
  Specifies the full URI for the request, including the https:// and the :9440

  .PARAMETER $Username
  Username for the request

  .PARAMETER $VMName
  VM Name for the request

  .PARAMETER $Password
  Password for the request. In plaintext for now for reasons. This is not good, and when I work out how to get
  around the funkiness I will update this.

  .INPUTS
  There is currently no pipeline inputs configured.

  .OUTPUTS
  Returns the UUID for a VM

  .EXAMPLE
  Get-XRSNTNXVMsByCategory -RequestURI https://PrismCentralURL:9440/ -Username admin -Password 12345 -VMName <VMName>

#>

$Count = 0
$Offset = 0
$RequestUri = $RequestUri + "/api/nutanix/v3/vms/list"



Do{

# Set the Payload with the correct offset to page

  $Payload = '{ "kind": "vm", "offset": ' + $offset + ', "length": 500 }'

#Set the args and do the lookup
  
  $APIArgs = @{

    RequestUri = $RequestUri
    Username = $Username
    Password = $Password
    method = "POST"
    Payload = $Payload

  }

  $Request = Invoke-XRSNTNXAPICall @APIArgs

# Build a lookuptable of VM Name to UUID for this page

  $LookupTable = @{}
    $i = 0

    do {

      $LookupTable.add( $Request.entities.spec.name[$i], $Request.entities.metadata.uuid[$i] )

      $i = $i + 1

    } While (( $i -lt 500 ) -or ($i -eq [int]$Request.metadata.total_matches))

# Set the Count variable to the returned VM Count

  If ($Count -eq 0){

    [int]$Count = $Request.metadata.total_matches
  
  }

# Set the offset for the next page if not first time round

  elseif ($Count -gt 500) {

    $Offset = $Count + 500

  }

# Check the VM name in the lookup table

  $Response = $LookupTable[$VMName]

# If we get a hit, drop out the loop

  If ($null -ne $Response ){

      Break
  }

# If we get to the end of the lists. 

  If ($offset -gt $Count){

    Break
}

# Are we done? If 
}While ($Count -le $Offset)

Return $Response

}