# New Debian WSL
## Python
Install a new Python version.  Ensure it is compatible with Azure Function Apps (maximum v3.11).  
Add the basic linux tools such as gcc, open-ssh (within git), etc.  
```posix
sudo apt-get install wget
sudo apt-get install curl
sudo apt-get install git
sudo apt-get install build-essential
```

Download a python tgz file and install as the default in debian, which is located in the */usr/local/lib/pythonx.xx* folder but which runs from the */usr/local/bin* location.    
```posix
tar -xvf <python-file>.tgz
cd python-x.x.x
./configure --enable-optimizations
sudo make
sudo make install
```
If you want to add a another python version then make it as an alternative install which puts it into the users home folder path.  
```posix
sudo make altinstall
```

Finish the python utilities.  
```posix
sudo apt-get install python3-venv
sudo apt-get install python3-pip
```
## Dotnet
To run any C# modules, we will need a dotnet environment.  Always read the latest docs:  
https://docs.microsoft.com/en-us/dotnet/core/install/linux  

What is your Deb version?  
```posix
cat /etc/os-release
```

Run the installation process using apt (this is copied from the microsft docs pages):  
```posix
wget https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb
```
```posix
sudo apt-get update && \
  sudo apt-get install -y dotnet-sdk-7.0
```
Check you have what you expect.  
```posix
dotnet --list-sdks
```

## Azure CLI & Tools
First add the CLI.  Check the docs again, to ensure your Deb version is compatible.  
https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=apt  

Use their single bash install script.  
```posix
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```
Also, check you have what you expect.  
```posix
az --version
```

Second, add the Azure Functions core tools so you can develop function apps locally.  
https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local?tabs=linux%2Ccsharp%2Cbash

```posix
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
```
```posix
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/debian/$(lsb_release -rs | cut -d'.' -f 1)/prod $(lsb_release -cs) main" > /etc/apt/sources.list.d/dotnetdev.list'
```
If you like, you can check your Deb version is in the generated config list.  
```posix
/etc/apt/sources.list.d/dotnetdev.list
```
Then perform the core tools installation.  
```posix
sudo apt-get update
sudo apt-get install azure-functions-core-tools-4
```
**Version Issue**  
Core tools 4 is missing from Deb 12 (as of Oct 2023).  Manually edit your dotnetdev.list file and change this enttry:  
```
deb [arch=amd64] https://packages.microsoft.com/debian/12/prod bookworm main
```
To this entry:  
```
deb [arch=amd64] https://packages.microsoft.com/debian/11/prod bullseye main
```
Then run the apt update and install, check you have the right version.  
```posix
func --version
```

Third, install the Bicep components of the Azure CLI.  
```posix
az bicep install
az bicep version
```



