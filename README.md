# Nutanix
PowerShell functions for interfacing with the Nutanix API.

Module is still a work in progress, and I need to fix the password handling.
This selection of scripts uses my normal strategy for Powershell API access of adjusting a template function to interact with the API, 
then everything else can just call it rather than building the headers etc. 

Good for less technical people too, as they can use the function as any other Powershell Cmdlet, but still interact with an API.

This is a placeholder for more in depth doc coming soon, but the functions do have help text and are commented, so you can probably work it out.

Yes, the password handling is horrible. I was in a bit of a crunch at the time. I have a much better method I just need to port in I promise.
