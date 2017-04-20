# Terraform Bluemix Load Balanced Web Servers

An example Terraform configuration template to deploy an IBM load balancer and _N_ number of web servers running nginx configured with a simple hello world app.

This configuration will create the following resources:

- A Private VLAN
- A Load balancer
- _N_ (default `2`) load balancer service definitions
- An SSH Key
- _N_ (default `2`) virtual guests acting as web servers

# Architecture

![Non-Redundent Two-tier Architecture](./non-redundent-two-tier-arch-diag.png)

# Usage

This is not a module, it is a terraform configuration template that can be cloned or forked to be used with the IBM Cloud terraform binary locally, or it can be used with the [IBM Cloud Schematics](https://github.com/IBM-Bluemix/schematics-onboarding) service. A module is used in this template for creating the load balancer and load balancer service group; it can be found at [ckelner/tf_ibmcloud_local_loadbalancer](https://github.com/ckelner/tf_ibmcloud_local_loadbalancer/).

To run this project execute the following steps:

- [Setup up IBM Cloud provider credentials](#setting-up-provider-credentials), please see the section titled "[Setting up Provider Credentials](#setting-up-provider-credentials)" for help.
- You will need the IBM Terraform binary or access to the IBM Schematics service. You can obtain either by visiting [github.com/IBM-Bluemix/schematics-onboarding](https://github.com/IBM-Bluemix/schematics-onboarding#ibm-bluemix-schematics-service-on-boarding).
- Supply or override the following variable values:
  - `datacenter` - Available IBM Cloud data centers are listed in the [Available Data Centers](#available-data-centers) section below. A default value of `dal06` is supplied but can be overwritten in `terraform.tfvars` by using `datacenter = <new-value>`.
  - `public_key` - public SSH key material to be installed on the server.
    - Specifically for `public_key` material see ["Generating a new SSH key and adding it to the ssh-agent"](https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/)) so that your workstation will use the key.
  - `key_label` - a label for the SSH key, a default of `schematics-demo-ssh-key` is supplied.
  - `key_note` - a note for the SSH key, a default of `""` is supplied.
  - `vlan_name` - The name of the private VLAN that the web servers will be placed in. A default of `private-vlan` is supplied.
  - `subnet_size` - The size of the subnet for the private VLAN that the web servers will be placed in. A default of `16` is supplied.
  - `node_count` - The number of web servers to create and put behind the load balancer. A default of `2` is supplied.
  - `web_operating_system` - The OS to install on the web servers -- **WARNING** changing this will likely break the setup of nginx. A default of `UBUNTU_LATEST` is supplied.
  - `port` - the port that the load balancer and the web servers will serve traffic on.
  - `vm_cores` - the number of cores the web servers will have. Defaults to `1`.
  - `vm_memory` - the amount of memory the web servers will have. Defaults to `1024`.
  - `vm_tags` - tags to apply to the VMs. The deafult is `nginx`, `demo`, `schematics`, and `webserver`.
- The above variables can be supplied using `terraform.tfvars`, see https://www.terraform.io/intro/getting-started/variables.html#from-a-file for instructions, or alternatively these values can be supplied via the command line or environment variables, see https://www.terraform.io/intro/getting-started/variables.html.
- `terraform get`: this will get all referenced modules
- `terraform plan`: this will perform a dry run to show what infrastructure terraform intends to create
- `terraform apply`: this will create actual infrastructure
  - Infrastructure can be seen in IBM Bluemix under the following URLs:
    - Virtual Guests: https://control.bluemix.net/devices
    - Load Balancers: https://control.bluemix.net/network/loadbalancing/local
    - SSH keys: https://control.bluemix.net/devices/sshkeys
- `terraform destroy`: this will destroy all infrastructure which has been created

# Available Data Centers
Any of these values is valid for use with the `datacenter` variable:
- `ams01`: Amsterdam 1
- `ams03`: Amsterdam 3
- `che01`: Chennai 1
- `dal01`: Dallas 1
- `dal10`: Dallas 10
- `dal12`: Dallas 12
- `dal02`: Dallas 2
- `dal05`: Dallas 5
- `dal06`: Dallas 6
- `dal07`: Dallas 7
- `dal09`: Dallas 9
- `fra02`: Frankfurt 2
- `hkg02`: Hong Kong 2
- `hou02`: Houston 2
- `lon02`: London 2
- `mel01`: Melbourne 1
- `mex01`: Mexico 1
- `mil01`: Milan 1
- `mon01`: Montreal 1
- `osl01`: Oslo 1
- `par01`: Paris 1
- `sjc01`: San Jose 1
- `sjc03`: San Jose 3
- `sao01`: Sao Paulo 1
- `sea01`: Seattle 1
- `seo01`: Seoul 1
- `sng01`: Singapore 1
- `syd01`: Sydney 1
- `syd04`: Sydney 4
- `tok02`: Tokyo 2
- `tor01`: Toronto 1
- `wdc01`: Washington 1
- `wdc04`: Washington 4

# Running in Multiple Data centers

Simply run `terraform plan -var 'datacenter=lon02' -state=lon02.tfstate` or whatever your preferred datacenter is (replace `lon02` for both arguments), and repeat for `terraform apply` with the same arguments (or create alternative `terraform.tfvars` files and pass them to terraform).

# Video of Terraform Execution

[Click here to watch a video of Terraform Plan, Apply, and Destroy](https://youtu.be/vTKeWTfalTU) - this is a simple video that shows the core three phases of execution and management using Terraform.

# Setting up Provider Credentials

To setup the IBM Cloud provider to work with this example there are a few options for managing credentials safely; here we'll cover the preferred method using environment variables. Other methods can be used, please see the [Terraform Getting Started Variable documentation](https://www.terraform.io/intro/getting-started/variables.html) for further details.

## Environment Variables using IBMid credentials

You'll need to export the following environment variables:

- `TF_VAR_ibmid` - your IBMid login
- `TF_VAR_ibmidpw` - your IBMid password
- `TF_VAR_slaccountnum` - the target softlayer account number (while optional, it is REQUIRED if you have multiple accounts associated with your ID; otherwise you will recieve an error similar to `* ibmcloud_infra_virtual_guest.debian_small_virtual_guest: Error ordering virtual guest: SoftLayer_Exception_Public: You do not have permission to verify server orders. (HTTP 500)`)

On OS X this is achieved by entering the following into your terminal, replacing the `<value>` characters with the actual values (remove the `<>`:

- `export TF_VAR_ibmid=<value>`
- `export TF_VAR_ibmidpw=<value>`
- `export TF_VAR_slaccountnum=<value>`

However this is only temporary to your current terminal session, to make this permanent add these export statements to your `~/.profile`, `~/.bashrc`, `~/.bash_profile` or preferred terminal configuration file. If you go this route without running `export ...` in your command prompt, you'll need to source your terminal configuration file from the command prompt like so: `source ~/.bashrc` (or your preferred config file).

### IBMid Credentials

If you happen to get the error `provider.ibmcloud: Client request to fetch IMS token failed with response code 401` you are likely passing the wrong credentials for IBMid (this is different than IBM w3id).

One way to be certain if your credentials are good or not is to test them with the `test-credentials.sh` script in this repo.  Simply execute the following:

```
bash test-credentials.sh <ibmid> <password> <account-number>
```

Replacing `<ibmid>`, `<password>`, and `<account-number>` for real values.  Where `<account-number>` is your Softlayer account number, which can found at https://control.bluemix.net/account/user/profile under the "API Access Information" section prepended to your "API Username" (or in the upper right it is displayed as part of your account information in parenthesis).

Alternatively you can run the following command:

```bash
curl -s -u 'bx:bx' -k -X POST --header \
'Content-Type: application/x-www-form-urlencoded' \
--header 'Accept: application/json' -d \ "grant_type=password&response_type=cloud_iam,ims_portal \
&username=${1}&password=${2}&ims_account=${3}" https://iam.ng.bluemix.net/oidc/token
```

Replacing `${1}` with your IBMid, `${2}` with your IBMid password, and `${3}` with you Softlayer account number.

When you run either of the above methods, a successful response (meaning the credentials are good) looks like (trimmed for brevity):

```json
{
   "access_token":"eyJraWQiOiIyMDE…a72w",
   "refresh_token":"BTJ8…KLaBJ",
   "ims_token":"e56350224c...1d3d3",
   "ims_user_id":6525897,
   "token_type":"Bearer",
   "expires_in":3600,
   "expiration":1489623909
}
```

And if your credentials are wrong, you will get a different response:

```json
{
   "errorCode":"BXNIM0602E",
   "errorMessage":"The credentials you provided are incorrect",
   "errorDetails":"The credentials you entered for the user 'ckelner@us.ibm.com' are incorrect",
   "context":{
      "requestId":"2512082279",
      "requestType":"incoming.OIDC_Token",
      "startTime":"15.03.2017 22:50:39:925 UTC",
      "endTime":"15.03.2017 22:50:40:224 UTC",
      "elapsedTime":"299",
      "instanceId":"tokenservice/1",
      "host":"localhost",
      "threadId":"8791",
      "clientIp":"73.82.211.28",
      "userAgent":"curl/7.43.0",
      "locale":"en_US"
   }
}
```

If you run into this error, you should reset your IBMid password by navigating to https://www.ibm.com/account/profile/us and clicking on "Reset password"
