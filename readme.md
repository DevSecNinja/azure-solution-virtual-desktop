# Azure Virtual Desktop Solution

This repository contains the code that I use to deploy my Azure Virtual Desktop demo environment with Terraform.

## 📌 Features

- Creates a new Azure resource group
- Creates multiple personal and pooled VMs

## 🔧 Usage

To use code from this repository, you will need to have an Azure account and access to the Azure CLI with Terraform installed.
I heavily rely on the [terraform-azurerm-caf-enterprise-scale](https://github.com/Azure/terraform-azurerm-caf-enterprise-scale) and the [terraform-azurerm-lz-vending](https://github.com/Azure/terraform-azurerm-lz-vending) modules, hence some of the references to e.g. the management & connectivity subscriptions.

## ⚒️ Known Issues

### Azure AD Join

The Azure AD Join extension doesn't allow virtual machines with the same hostname to be joined to Azure AD again. Cleanup the old VM resources after deleting the VMs. There doesn't seem to be a Terraform resource for it and PowerShell requires the Azure AD module.

### AVD Extension

There doesn't seem to be a source to know the most recent URL for the agent extension. Therefore, we centrally keep track of the URL like so:

``` json
{
 "azure_virtual_desktop": {
  "config": {
   "agentUrl": "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_06-15-2022.zip"
  }
 }
}
```

## 🤝 Contributions

I welcome contributions to this project! If you have an idea for a feature or improvement, please open an issue or pull request. If you find this project helpful, I would also appreciate it if you could leave a star on the GitHub repository 🌟

Thank you for considering contributing 🙏

## 📜 License

This project is licensed under the MIT License. It is not affiliated with my employer.

Feel free to use and modify the code as you see fit 🎉

## 📄 Terraform Documentation

I'm using `terraform-docs` to update my documentation automatically. You can find this documentation in the `readme.md` in the `solutions/<solutionName>` folder.
