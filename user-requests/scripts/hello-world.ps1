Param(
  [string]$output
)

$request_variables = $env:REQUEST_PARAMETERS | ConvertFrom-Json

$output += "Hello World!|"


Write-Host "##vso[task.setvariable variable=output]$output"

