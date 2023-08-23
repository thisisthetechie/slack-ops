Param(
  [string]$pipeline_name,
  [string]$pipeline_file,
  [string]$pipeline_type
)

$default_variables = @(
  "approval_needed",
  "request_parameters",
  "request_title",
  "request_type",
  "user_id",
  "user_name"
)

switch ($pipeline_type) {
  "User Requests" {
    $path = "requests"
  }

  "Scheduled Tasks" {
    $path = "scheduled-tasks"
  }
}

Write-Host "Creating ${pipeline_name} Pipeline (Ignore any warnings about Queue ID)"
$pipeline = az pipelines create --name $pipeline_name --folder-path $pipeline_type --yml-path "${path}/templates/${pipeline_file}" --branch main --skip-first-run | ConvertFrom-Json -Depth 99 -AsHashtable

Write-Host "Pipeline ID: $($pipeline.id)"

Write-host "Creating Default Variables"
foreach ($variable in $default_variables) {
  Write-Host "Creating ${variable}"
  $variable = az pipelines variable create --name $variable --allow-override true --detect true --pipeline-id $pipeline.id 
}
