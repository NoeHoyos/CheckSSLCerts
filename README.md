# CheckSSLCerts
These are scripts to check the expiration date of SSL/TLS certificates.

Windows version: CheckSSLCertificates.ps1
Linux verison: check_ssl_certificates.sh

These scripts need an input file. It is a text file with a list of URLs. Comments start with the "#" sign; blank lines are ignored. For example:

```text
# This is my first URL
https://www.sap.com

#
# This is my second URL
https://www.google.com
#
```
Note that these scripts do not support a proxy.

Assuming the URLs are in a file called 'urls.txt', here are examples on how to run the scripts:

PS C:\Users\Myself> .\CheckSSLCertificates.ps1 .\urls.txt  <=== Example command line for Windows (PowerShell)

myself@host:~> ./check_ssl_dates.sh urls.txt               <=== Example command line for Linux

The PowerShell script can be copied to your laptop and called from there.
The Linux script must be copied to one of the systems in the customer landscape and called from there.
It is possible to call the Llinux script remotely from the terminal server. Use 'plink' in a PowerShell window, for example:

```text
plink -batch -ssh i-user@<server>.sap.biz /path/check_ssl_certificates.sh urls.txt
```
