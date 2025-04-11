---
title: 'Set Up Common Development Network'
menuTitle: '2. Set Up Dev Network'
disableToc: true
weight: 20
---

{{% comment %}}
Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
SPDX-License-Identifier: CC-BY-SA-4.0
{{% /comment %}}

In this step your Cloud Administrators will review the initial development network design, create a new **network-prod** AWS account, provision a common centrally managed development network, and share the private subnets will all team development AWS accounts in your AWS organization.

This step should take about 60 minutes to complete.

{{< toc >}}

## 1. Review initial network design

As mentioned in the [Initial Development Environment Solution Overview]({{< relref "01-review-dev-solution" >}}), it's recommended that you start with a single centrally managed development VPC that has a set of public and private subnets of which only the private subnets will be shared across all team development AWS accounts.

In those AWS regions in which at least 3 Availability Zones (AZs) are available for customer use, it's recommended that your initial set of VPCs have subnets in each of the 3 AZs so that your builder teams can experiment with and perform early testing of workloads and AWS services that can take advantage of 3 AZs.

At least one public subnet will have a NAT Gateway that enables workloads in any of the shared private subnets to send traffic outbound to the Internet. For example, to enable workloads to download content from Internet accessible source code and package repositories.

{{% notice tip %}}
**Option to filter outbound Internet traffic:** As you progress in your journey, you may transition from this initial approach of providing builder teams with unfiltered outbound or egress Internet access via the initial set of public subnets and NAT Gateway to a more secure architecture where all Internet egress traffic is routed through your standard enterprise edge security services so that all egress traffic is inspected for compliance. This capability is highlighted in the [optional capabilities]({{< relref "05-extend" >}}).
{{% /notice %}}

[![Centrally Managed Development Network Details](/images/03-dev/initial-foundation-dev-network-details.png)](/images/03-dev/initial-foundation-dev-network-details.png)

## 2. Create network-prod AWS account

In AWS Control Tower, provision a new **network-prod** AWS account that will initially contain the centrally managed development VPC.

{{% notice info %}}
**Why is a network-prod account being used for a development network?** You may be asking why we're creating a `network-prod` AWS account to contain a development network. Since the expectation is that the underlying development network for your teams should be treated as a production quality resource, the development network should reside in a production-oriented AWS account. Note that the actual development workloads will reside in team development accounts and not in the `network-prod` account. Only the underlying VPC and subnets reside in the `network-prod` account. Since a `network-dev` account would be positioned for your cloud foundation team to experiment and develop new networking capabilities, we would not want to put a production quality network in a `network-dev` account.  Short of creating a dedicated, `network-prod-common-dev` account, this guide currently co-locates the centrally managed development VPC in the `network-prod` account.  If you desire further isolation, then it's recommended that you create a distinct account such as `network-prod-common-dev` to hold the centrally managed development network.
{{% /notice %}}

Later in your journey, you'll deploy more network related resources to this AWS account. For example, you will likely configure  and manage [AWS Transit Gateway](https://aws.amazon.com/transit-gateway/) resources in this dedicated AWS account when you start integrating on-premises network connectivity in your overall AWS environment.

1. As a Cloud Administrator, use your personal user to log into AWS SSO.
2. Select the AWS **`management`** account.
3. Select **`Management console`** associated with the **`AWSAdministratorAccess`** role.
4. Select the appropriate AWS region.
5. Navigate to **`Control Tower`**.
6. Select **`Account Factory`** on the left.
7. In the upper right, click **`Enroll account`**.
8. Fill out the Enroll account form details. Some suggested fields are below:

|Field|Recommendation|
|-----|---------------|
|**`Account email`**|Consult the [set of AWS account root user email addresses]({{< relref "02-obtain-email-addresses" >}}) that you established earlier.|
|**`Display name`**|**`network-prod`**|
|**`AWS SSO email`**|Provide the email address of one of your cloud administrators as registered in AWS SSO.  As long as you reference an existing AWS SSO user, the Account Factory will not create another AWS SSO user for this new AWS account.|
|**`AWS SSO First Name`**|**`AWS Control Tower`**|
|**`AWS SSO Last Name`**|**`Admin`**|
|**`Organizational unit`**|Select **`infrastructure_prod`**.|

9. Select **`Enroll Account`**.

It will take a few minutes to enroll the new account. You can check the status in **`Service Catalog`**.

{{% notice info %}}
**You can change AWS account settings later:** Configuration settings of the AWS accounts you provision via Account Factory shouldn’t be considered static.  Nearly every part of an AWS account can be changed and updated at a later date. See [Account Factory](https://docs.aws.amazon.com/controltower/latest/userguide/account-factory.html) for more details.
{{% /notice %}}

## 3. Perform post AWS account creation user configuration

Once you create a new AWS account using Account Factory, there are several user account related tasks that you should perform to enhance the security of your environment.

### Remove individual access to the new AWS account

Since AWS Control Tower's Account Factory automatically grants the AWS SSO user specified in the Account Factory parameters administrative access to the newly created AWS account, you should remove this individual access.  Since you'll grant your Cloud Administrators access to the new AWS account using their AWS SSO group in a subsequent step, there's no need to leave this individual access in place.

1. Navigate to **`AWS SSO`**.
2. Access **`AWS accounts`** in AWS SSO.
3. Select the **`network-prod`** AWS account.
4. Select **`Remove access`** from the **`User/group`** entry that matches the AWS SSO email address you supplied in the previous step.
5. Select **`Remove access`** to confirm removal.

### Initialize AWS account's root user  

1. **Set AWS account root user password**: See [Log In as Root User](https://docs.aws.amazon.com/controltower/latest/userguide/best-practices.html#root-login) in the AWS Control Tower documentation for instructions to set the root user’s password.

2. **Enable multi-factor authentication (MFA)**: See [Enable MFA on the AWS Account Root User](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_root-user.html#id_root-user_manage_mfa) for instructions to enable MFA.

## 4. Enable foundation team members access

Since Cloud Administrators won't automatically be granted sufficient access to the newly created AWS account, you need to enable this access each time you create a new AWS account via AWS Control Tower's Account Factory.

1. Navigate to **`AWS SSO`**.
2. Access **`AWS accounts`** in AWS SSO.
3. Select the checkbox next to the **`network-prod`** AWS account.
4. Select **`Assign users`**.
5. Select **`Groups`**.
6. Select the checkbox next to the group **`example-cloud-admin`** or similar.
7. Select **`Next: Permission sets`**.
8. Select the checkbox next to **`AWSAdministratorAccess`**.
9. Select **`Finish`**.

Now you've enabled all users who are part of the Cloud Administrator group in AWS SSO administrator access to the **network-prod** AWS account.

## 5. Determine IP Address CIDR blocks {#dev-cidr}

If you're just experimenting and don't care which IP address CIDR block is used to build the centrally managed development VPC, you can move to the next step, [Provision Development VPC]({{< relref "#provision-dev-vpc" >}}).

Otherwise, if you have a formally assigned CIDR block to use, in this step you'll:

1. Review VPC topology
2. Determine VPC CIDR block
3. Determine subnet CIDR blocks
4. Document CIDR block usage

### 5.1 Review VPC topology

The default parameters of the AWS CloudFormation template that you will use in the next step will result in a VPC with:
* 2 tiers of subnets:
  * Public tier
  * Private tier
* 3 subnets for each tier.
* Subnets are mapped across 3 Availability Zones (AZs).

Using the default parameters, the CloudFormation template requires you to supply a CIDR block for each of the following:
* Overall VPC
* Public subnets 1, 2, and 3
* Private subnets 1, 2, and 3

To keep things simple, you can size the subnets identically.

### 5.2 Determine VPC CIDR block

As a result of your up front tasks to [Obtain a Non-Overlapping IP Address Block]({{< relref "03-obtain-ip-address-range" >}}), your Network team may have already supplied a relatively large non-overlapping CIDR block for your use of AWS.

You should use only a subset of the overall block for your centrally managed development VPC so that the remaining address space can be used in support of test and production networks.

Since you will be subdividing the CIDR block for your centrally managed development across 6 subnets: 3 public + 3 private and you may have multiple teams sharing the common development network, you should allocate at least a `/19` or `/20` CIDR block for your centrally managed development.

If you need to break down a larger block:

1. Access the [Visual Subnet Calculator](http://www.davidc.net/sites/default/subnets/subnets.html).
2. Enter your network address without the mask portion **`/nn`** in the **`Network Address`** field.
3. Enter the size of allocated block in the **`Mask bits`** field.
4. Click **`Update`**.  
5. In the table at the bottom, click the **`Divide`** link to break down the block into smaller blocks.  

### 5.3 Determine subnet CIDR blocks

Once you've determined the VPC CIDR block, you can use the following steps to break it down into an equal size block per subnet:

1. Access the [Visual Subnet Calculator](http://www.davidc.net/sites/default/subnets/subnets.html)
2. Enter your network address without the mask portion **`/nn`** the **`Network Address`** field.
3. Enter the size of allocated block in the **`Mask bits`** field.
4. Click **`Update`**.  
5. In the table at the bottom, click the **`Divide`** links to start subdividing the larger block into 6 blocks of equal size.
6. Note the first 6 blocks and supply them as the subnet CIDR blocks in the next step.

### 5.4 Document CIDR block usage

Once you've determine the CIDR block allocations for your team development VPC, you should document the allocation in your system configuration documentation. If you use an IP Address Management (IPAM) tool, you should also be able to register the use of these CIDR blocks in that tool.

## 6. Provision development VPC {#provision-dev-vpc}

You can use this [sample AWS CloudFormation template](https://github.com/aws-samples/vpc-multi-tier) to easily deploy your centrally managed development network.

Download the sample AWS CloudFormation template [vpc-multi-tier.yml](https://raw.githubusercontent.com/aws-samples/vpc-multi-tier/master/vpc-multi-tier.yml) to your desktop. You can review the [README](https://github.com/aws-samples/vpc-multi-tier/blob/master/README.md) to understand the role of this template.

Next, access the new **network-prod** AWS account:

1. As a Cloud Administrator, use your personal user to log into AWS SSO.
2. Select the **`network-prod`** AWS account.
3. Select **`Management console`** associated with the **`AWSAdministratorAccess`** role.
4. Select the appropriate AWS region.

Now create a new AWS CloudFormation stack using the sample template you downloaded to your desktop:

1. Navigate to **`CloudFormation`**.
2. Select **`Create stack`** and **`With new resources`**.
3. Select **`Upload a template file`**.
4. Select **`Choose file`** to select the downloaded template file from your desktop.
5. Select **`Next`**.
6. Enter a **`Stack name`**. For example, **`infra-dev-shared-vpc`**.
7. In **`Parameters`**:

|Parameter|Guidance|
|---------|--------|
|**`Business Scope`**|Replace `example` with your organization identifier or stock ticker if that applies. This value is used as a prefix in the name of some of the VPC-related cloud resources. For example, in the name of the IAM role used to support VPC flow logs.|
|**`VPC Name`**|Change to **`dev-shared`**|
|**`Cidr`**|**Just Experimenting**<br>If you want to just experiment at this point and don't care about using formally assigned IP address ranges, you can leave the CIDR block parameters at their default values.<br><br>**You Have Your Own CIDR Blocks**<br>Enter values for the `pVpcCidr`, `pTier1..`, and `pTier2...` CIDR blocks from the prior step. You can ignore the `pTier3...` parameters because only two tiers - public and private - are being provisioned by default.|

Leave all of the other parameters at their default settings unless you're comfortable changing them.  You can always easily create another stack to experiment with other parameter values. Review the [README](https://github.com/aws-samples/vpc-multi-tier/blob/master/README.md) for details on parameters.

8. Select **`Next`**.
9. Select **`Next`**.
10. Scrolls to the bottom and mark the checkbox to acknowledge that IAM resources will be created.
11. Select **`Create stack`**.

In the **`Events`** tab, monitor the progress of the stack creation process. After 5 or so minutes, creation of the stack should complete.

## 7. Review development VPC

Review the newly created VPC and associated resources.

1. Navigate to **`VPC`**.
2. Select the VPC and review its details.
3. Select **`Subnets`** in the left menu and review. By default, you will see 6 subnets.
4. Select **`Route Tables`** and review. You will see one route table per subnet in addition to the VPC's main route table.
5. Select **`NAT Gateways`** and review. With the default behavior of the CloudFormation template, a single NAT Gateway will be created.
6. Select **`Elastic IPs`** and review.  You will see one EIP allocated for each NAT Gateway.
7. Navigate to **`CloudWatch`**.
8. Select **`Log groups`**.
9. Select the log group associated with the VPC Flow Logs. For example, `/infra/dev-shared/flowlogs`.
10. Explore the log streams. You should see a log stream for each Elastic Network Interface (ENI) used in the VPC. For example, each NAT Gateway has one ENI. Each entry in a log stream represents the source, destination, and other overall information about the network traffic flowing through the ENI.

## 8. Share private subnets With development OUs {#share-dev-subnets}

Now that the centrally managed development VPC has been provisioned, your next step is to share the private subnets with all of the AWS accounts that will become part of the development OUs that you created earlier.  

### Enable resource sharing in AWS organizations

This is a one-time operation.

1. As a Cloud Administrator, use your personal user to log into AWS SSO.
2. Select the AWS **`management`** account.
3. Select **`Management console`** associated with the **`AWSAdministratorAccess`** role.
4. Navigate to **`Resource Access Manager`**.
5. Select **`Settings`**.
6. Select **`Enable sharing with AWS Organizations`**.

### Obtain the IDs of the development OUs

While you're in the master AWS account, obtain and record the resource ID of each of the two development OUs:

* **`infrastructure_dev`**
* **`workloads_dev`**

1. Navigate to **`AWS Control Tower`**.
2. Select **`Organizational units`**.
3. Select **`infrastructure_dev`**.
4. Copy the **`ID`** of the form `ou-szfb-rixl8jqc` (example) so that you can refer to it in the next step.
5. Perform the same task for the **`workloads_dev`** OU to make a copy of its OU ID.

### Create a resource share

1. As a Cloud Administrator, use your personal user to log into AWS SSO.
2. Select the **`network-prod`** AWS account.
3. Select **`Management console`** associated with the **`AWSAdministratorAccess`** role.
4. Select the appropriate AWS region.
5. Navigate to **`Resource Access Manager`**.
6. Select **`Create a resource share`**.
7. Enter a **`Name`** of **`dev-infra-shared-vpc-private-subnets`**.
8. Under **`Resources`**, by default, the subnets that were just provisioned should be listed.
9. Select only the private subnets.
10. Under **`Principals`**, deselect **`Allow external accounts`** given that we're sharing the subnets only with other AWS accounts within this AWS organization.
11. In the search field, copy the organization ID of the **`infrastructure_dev`** OU.
12. Select the matched OU.
13. Perform the same task for the **`workloads_dev`** OU.
14. Select **`Create resource share`**.

{{% notice info %}}
**Sharing names of VPC subnets:** If you were to list the shared private subnets from within the team development AWS accounts, you would notice that the subnet names are blank.  Currently, sharing of subnets does not include automatic propagation of resource tags, including the `Name` tag. As a workaround, in a subsequent section where you provision the team development AWS accounts, you can manually assign names to the shared private subnets so that it will be easier for the builder teams to understand the role of each subnet. For example, by including the word "private" in the subnet names, builder teams will be able to more readily understand the role of the shared subnets.
{{% /notice %}}
