# Run qsalary in AWS

## Terraform automated environment

[Official Terraform Documentation](https://www.terraform.io/docs/)

This terraform docker container provides a complete enviroment in order to run the qsalary application. It will spin up the required host and start the application in AWS.

~'~ Warning - This WILL cost money ~'~

** Be sure to set all custom required configs before running (.env)**

** This includes creating the required .env file containing AWS Access and Secret key **

## Usage

Create a SSH keypair within your AWS account. Use the name of the keypair you just created in the following command.

```bash
sed -i.bak 's/KEYPAIR/<keypair_name>/g' host.tf
sed -i.bak 's/QYEAR/<year>/g' userdata.sh
docker-compose up
```

### Destroying the host

```bash
sed 's/apply/destroy/g' docker-compose.yml
docker-compose up
```
