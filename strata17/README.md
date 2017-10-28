This directory contains files relevant to the presentation *Automating Cloud Cluster Deployment: Beyond the Book*, given at [Strata Data NYC](https://conferences.oreilly.com/strata/strata-ny) in September 2017. They serve as examples of automating the deployment of Hadoop clusters in AWS, using ideas found in the book *Moving Hadoop to the Cloud*.

If you are looking for the video recording of the presentation, it's available on [Safari](https://www.safaribooksonline.com/library/view/strata-data-conference/9781491976326/video316357.html).

If you are looking for the presentation slides, they are [posted](https://cdn.oreillystatic.com/en/assets/1/event/261/Automating%20cloud%20cluster%20deployment_%20Beyond%20the%20book%20Presentation.pptx) in the conference [proceedings](https://conferences.oreilly.com/strata/strata-ny/public/schedule/proceedings).

## Prerequisites

* An AWS account with permissions to work with EC2 instances
* EC2 networking established, with a VPC, subnet, and optionally a security group
* The [AWS CLI](https://aws.amazon.com/cli/) installed and configured locally
* [Packer](https://www.packer.io/)

## Step 1. Create an AMI

Create an Amazon Machine Image (AMI) using Packer that contains most of what you need for your cluster. Check out the [README](packer/README.md) for the Packer template to get started.

## Step 2. Launch Instances

Use the [allocate_aws_cluster.sh](./allocate_aws_cluster.sh) script to spin up the instances for your cluster. Each of them should be based on your custom AMI. Run the script with the `-h` option for documentation. You must have the AWS CLI installed and configured locally for the script to work.

The script reports the instance IDs and private and public IP addresses for the instances it allocates.

## Step 3. Configure New SSH Keys

Use the [coordinate_ssh_keys.sh](../appb/coordinate_ssh_keys.sh) script to configure fresh SSH keypairs for each cluster instance. Run the script with the `-h` option for documentation. The script can be run from the same machine you ran the allocation script on, or any that can reach the cluster's manager instance. Feed this script the IP addresses reported by the allocation script.

## Step 4. Configure Hadoop

Use the [config_hadoop.sh](../appb/config_hadoop.sh) script to configure Hadoop on the instances as a single cluster. Run the script with the `-h` option for documentation. Unlike the other scripts, this one must be run on the cluster's manager instance. Feed this script the private IP addresses reported by the allocation script.

## Ready to Go

Your Hadoop cluster in the cloud is ready for use. Perform the usual initialization steps, such as formatting the HDFS namenode, and then start the cluster services.

## License

Source code in this project are licensed under the [Apache 2.0 license](http://www.apache.org/licenses/LICENSE-2.0.html). See [NOTICE.md](../NOTICE.md) for third-party licenses.
