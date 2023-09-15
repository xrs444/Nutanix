

function Get-XRSNTNXVMsByCategory{
    param (
    [Parameter (Mandatory = $true,HelpMessage="Address of Prism Central to query https://...:9440")] [String]$RequestUri,
    [Parameter (Mandatory = $true,HelpMessage="Username for request")] [String]$Username,
    [Parameter (Mandatory = $true,HelpMessage="Password in plain text for now, and yes this hurts my soul")] [String]$Password,
    [Parameter (Mandatory = $true,HelpMessage="Category to search for")] [string]$Category,
    [Parameter (Mandatory = $false,HelpMessage='Set $True to return hash table rather than array, useful for lookups')] [string]$ReturnHash = $false
   )

<#
  .SYNOPSIS
  Returns a list of VMs with Values under the specified category

  .DESCRIPTION
  Calls Invoke-XRSNutanixAPICall to provide a list of VMs tagged with values under a specified category.

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

  .PARAMETER $ReturnHash
  Normally the function returns an array of VMs and Tags, selecting this returns a hash table instead. Useful for working with individual machines.

  .INPUTS
  There is currently no pipeline inputs configured.

  .OUTPUTS
  Returns the list of VMs and tags as an arry, or if ReturnHash is set, a hashtable. 

  .EXAMPLE
  Get-XRSNTNXVMsByCategory -RequestURI https://<PrismCentralURL:9440/ -Username admin -Password 12345 -Category <DesiredCategory>

#>

$Count = 0
$Offset = 0
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

# Add all VMs with the category to the hash table for output.

    $LookupTable = @{}
    $i = 0

    do {

        $LookupTable.add( $Request.entities.spec.name[$i], $Request.entities.metadata.categories.$category[$i] )

        $i = $i + 1

    } While (( $i -lt 500 ) -or ($i -eq [int]$Request.metadata.total_matches))
    
# Scrub entries without a value for the category we're looking for.
# Using GetEnumerator to allow iteration through the hashtable.
    
    ($LookupTable.GetEnumerator() | Where-Object { -not $_.Value }) | foreach {$LookupTable.Remove($_.name)}
 
# Set the Count variable to the returned VM Count
  
    If ($Count -eq 0){
  
      [int]$Count = $Request.metadata.total_matches
    
    }
  
  # Set the offset for the next page if not first time round
  
    elseif ($Count -gt 500) {
  
      $Offset = $Count + 500
  
    }

# If the offset is bigger than the count, it's time to stop.

    If ($offset -gt $Count){
  
      Break
  }
  
  }While ($Count -le $Offset)
  
# If hashtable requested as output send it.

     If($ReturnHash -eq $True){

        $Response = $Lookuptable

# Otherwise convert the hash table to an array

    }Else{

        [string[]]$Response = ($LookupTable | Out-String -Stream) -ne '' | Select-Object -Skip 2

    }

  Return $Response

}
