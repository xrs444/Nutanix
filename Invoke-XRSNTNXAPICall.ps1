


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
  Invoke-XRSNutanixAPICall -RequestURI https://<PrismCentralUrl:9440/api/nutanixv3/vms/<UUID> -Method GET -Username admin -Password 12345

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