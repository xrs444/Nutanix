

function Get-XRSNTNXVMUUIDLookupTable{
    param (
    [Parameter (Mandatory = $true,HelpMessage="Address of Prism Central to query (https://...:9440")] [String]$RequestUri,
    [Parameter (Mandatory = $true,HelpMessage="Username for request")] [String]$Username,
    [Parameter (Mandatory = $true,HelpMessage="Password in plain text for now, and yes this hurts my soul")] [String]$Password
   )

   <#
  .SYNOPSIS
  Returns a has table of VMs and their UUIDs

  .DESCRIPTION
  Calls Invoke-XRSNTNXAPICall to provide a hash table of VMs and their UUIDs

  .PARAMETER RequestUri
  Specifies the full URI for the request, including the https:// and the :9440

  .PARAMETER $Username
  Username for the request

  .PARAMETER $Password
  Password for the request. In plaintext for now for reasons. This is not good, and when I work out how to get
  around the funkiness I will update this.

  .INPUTS
  There is currently no pipeline inputs configured.

  .OUTPUTS
  Returns the list of VMs and tags as a hashtable. 

  .EXAMPLE
  Get-XRSNTNXVMsByCategory -RequestURI https://<PrismCentralUrl>:9440/ -Username admin -Password 12345 -Category <DesiredCategory>

#>

$Count = 0
$Offset = 0
$OffsetCount = 0
$RequestUri = $RequestUri + "/api/nutanix/v3/vms/list"
$LookupTable = @{}

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

# Set the Count variable to the returned VM Count

[int]$Count = $Request.metadata.total_matches


# Build the lookuptable of VM Name to UUID for this page

    $i = 0

    do {

      $LookupTable.add( $Request.entities.spec.name[$i], $Request.entities.metadata.uuid[$i] )

      $i = $i + 1

    } While (( $i -lt 500 ) -and ($i -ne $OffsetCount))


# Set the offset for the next page

$Offset = $Offset + 500
    
$OffsetCount = $Count - $Offset

$Response = $LookupTable

}While ($Offset -lt $Count)

Return $Response

}