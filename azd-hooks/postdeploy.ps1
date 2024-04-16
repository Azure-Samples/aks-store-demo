#!/usr/bin/env pwsh

############################################
# Delete custom-values.yaml
############################################
Remove-Item -Path custom-values.yaml -ErrorAction SilentlyContinue