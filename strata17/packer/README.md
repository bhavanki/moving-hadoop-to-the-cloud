# Packer template for Hadoop image

Use the _hadoop.json_ Packer template to create an AMI preloaded with and mostly preconfigured for Hadoop. The template and provisioning scripts cover up through Chapter 9 of _Moving Hadoop to the Cloud_.

## Prerequisites

* An AWS account with permissions to work with EC2
* An AWS access key ID and secret access key
* [Packer](https://packer.io)

## User variables

The template requires a set of user variables. Create a file, _vars.json_, setting those that you will use for every build. For example:

```
{
    "region": "us-east-1",
    "source_ami": "ami-1d4e7a66",
    "ssh_username": "ubuntu",
    "vpc_id": "vpc-12345678",
    "subnet_id": "subnet-23456789",
    "security_group_id": "sg-34567890",
    "root_device_name": "/dev/sda1"
}
```

Any that aren't included in _vars.json_ must be provided to Packer on the command line.

* **ami_name**: name of AMI to build
* **region**: EC2 region to build in
* **source_ami**: base AMI to work from
* **ssh_username**: default login account for base AMI
* **vpc_id**: VPC ID
* **subnet_id**: subnet ID
* **security_group_id**: security group ID
* **root_device_name** name of root device in base image
* **java_package**: name of Java package to install
* **java_home**: `JAVA_HOME` for Java when installed
* **hadoop_version**: version of Hadoop to install

Currently the provisioning scripts only support operating systems that use apt-get for package installation.

## Running

```
$ export AWS_ACCESS_KEY_ID=...
$ export AWS_SECRET_ACCESS_KEY=...
$ packer build -var-file=vars.json -var 'ami_name=my_ami' hadoop.json
```

## License

Source code and templates in this project are licensed under the [Apache 2.0 license](http://www.apache.org/licenses/LICENSE-2.0.html). See [NOTICE.md](../../NOTICE.md) for third-party licenses.


