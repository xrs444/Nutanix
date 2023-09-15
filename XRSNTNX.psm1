# Functions for the XRSNTNX module.


function Invoke-XRSNTNXAPICall {
  param (
    [Parameter (Mandatory = $true,HelpMessage="Full request URI including port")] [String]$RequestUri,
    [Parameter (Mandatory = $false,HelpMessage="Body of the request")] $Payload, 
    [Parameter (Mandatory = $true,HelpMessage="REST call Method GET/PUT/ETC")] [String]$Method,
    [Parameter (Mandatory = $false,HelpMessage="Do not convert the native JSON output")] [bool]$DoNotConvert = $false,
    [Parameter (Mandatory = $false,HelpMessage="Convert the Payload to JSON if you don't want to")] [bool]$ConvertPayloadToJson =$false, 
    [Parameter (Mandatory = $true,HelpMessage="Username for request")] [String]$Username,
    [Parameter (Mandatory = $true,HelpMessage="Password in plain text for now, and yes this hurts my soul")] [String]$Password
  )


<#
  .SYNOPSIS
  Sends a Nutanix API request using the supplied parameters

  .DESCRIPTION
  Builds a REST API request from the given data and submits it to the specifed URI, and returns the response. 

  .PARAMETER RequestUri
  Specifies the full URI for the request, including the https:// and the :9440

  .PARAMETER Payload
  Specifies the body of the request. This is not needed for GET requests, and if specified will be ignored.

  .PARAMETER $Method
  Specifies the REST API Call method, GET/PUT/POST/SET/DELETE

  .PARAMETER $DoNotConvert
  If this is set to true, the output is in the raw JSON, rather than a nice object you can select items from.

  .PARAMETER $Username
  Username for the request

  .PARAMETER $Password
  Password for the request. In plaintext for now for reasons. This is not good, and when I work out how to get
  around the funkiness I will update this.

  .INPUTS
  There are no pipeline inputs currently configured.  

  .OUTPUTS
  Returns the response from the server converted from JSON (Or not, if DoNotConvert is set to true)

  .EXAMPLE
  Invoke-XRSNutanixAPICall -RequestURI https://PrismCentralURL:9440/api/nutanixv3/vms/<UUID> -Method GET -Username admin -Password 12345

#>

# create the HTTP Basic Authorization header
$pair = $Username + ":" + $Password
$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
$base64 = [System.Convert]::ToBase64String($bytes)
$basicAuthValue = "Basic $base64"

# setup the request headers
$Headers = @{
  'Accept' = 'application/json'
  'Authorization' = $basicAuthValue
  'Content-Type' = 'application/json'
}

# If JSON conversion specified, then do it!

if ($ConvertPayloadToJson -eq $true){

  $payload = ConvertTo-Json -InputObject $Payload -depth 20

}

# If it's a GET, don't send a body

if ($Payload -eq "GET"){

# Submit the request
  $APIArgs = @{ 

    Uri = $RequestUri
    Headers = $Headers 
    Method = $Method
    TimeoutSec = '10'
    UseBasicParsing = $true
    DisableKeepAlive = $true
  }

  $Response = Invoke-WebRequest @APIArgs

# If it's PUT/SET/ETC

}
else{

# Submit the request
  $APIArgs = @{ 

    Uri = $RequestUri
    Headers = $Headers 
    Method = $Method
    Body = $Payload 
    TimeoutSec = '10'
    UseBasicParsing = $true
    DisableKeepAlive = $true
  
  }
  
  $Response = Invoke-WebRequest @APIArgs

}

If ($DoNotConvert -eq "True"){

  Return $Response

}

else{

  $Response = ConvertFrom-Json -InputObject $Response
  Return $response  

}

}

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
  Get-XRSNTNXVMsByCategory -RequestURI https://<PrismCentralURL>:9440/ -Username admin -Password 12345 -VMName <VMName>

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

# CheXRS the VM name in the lookup table

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
  Calls Invoke-XRSNutanixAPICall to provide a hash table of VMs and their UUIDs

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
  Get-XRSNTNXVMsByCategory -RequestURI https://<PrismCentralURL>:9440/ -Username admin -Password 12345 -Category <DesiredCategory>

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
  Get-XRSNutanixVMsByCategory -RequestURI https://<PrismCentralURL>:9440/ -Username admin -Password 12345 -Category <DesiredCategory>

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
    Set-XRSNTNXVMTag -RequestURI https://<PrismCentralURL>:9440/ -Username admin -Password 12345 -Category <DesiredCategory> -Filename <File.csv>
  
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
    
  
  