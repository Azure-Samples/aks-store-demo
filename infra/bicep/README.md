# Azure Bicep Infrastructure

This directory contains Bicep templates for deploying Azure infrastructure and is scanned for compliance using PSRule.

## PSRule for Azure

PSRule is a tool for validating Azure resources against best practices and compliance rules. It can be used to ensure that your Bicep templates adhere to organizational standards.

To manually run PSRule against the Bicep templates in this directory, you can use the following command:

```powershell
$modules = @('PSRule.Rules.Azure')
Install-Module -Name $modules -Scope CurrentUser -Force -ErrorAction Stop;
Assert-PSRule -InputPath './infra/bicep/*.test.bicep' -Module $modules -Format File -ErrorAction Stop;
```

Some rules have been suppressed due to known issues or specific requirements. You can find the list of suppressed rules in the [ps-rule.yaml](./ps-rule.yaml) file.

## Resources

- [PSRule for Azure](https://azure.github.io/PSRule.Rules.Azure/)
- [PSRules for Azure Rule Reference](https://azure.github.io/PSRule.Rules.Azure/en/rules/)
