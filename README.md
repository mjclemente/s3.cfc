# s3.cfc
Call the AWS Java SDK functions for S3 directly from your CFML code.

This is very much a work in progress; I don't have a clear idea where I want to take it or what I want its interface to look like. Some of these functions have come in handy for various projects, so I thought it worthwhile to try to work them together into something coherent and helpful.

## Table of Contents

- [s3.cfc](#s3cfc)
  - [Table of Contents](#table-of-contents)
    - [Acknowledgements](#acknowledgements)
    - [Getting Started](#getting-started)
    - [A Note on Permissions](#a-note-on-permissions)
    - [Requirements](#requirements)

### Acknowledgements

The core interactions with AWS used in this project are derived from projects and demos by [brianklaas](https://github.com/brianklaas), particularly [AWS Playbox](https://github.com/brianklaas/awsPlaybox).

### Getting Started
*This assumes some degree of familiarity with AWS services, permissions, etc. If you're not familiar with AWS, this is going to sound like a complicated mess, but it's really pretty straightforward.*

In order to be initialized, the component requires a [properly permissioned user's](#a-note-on-permissions) AccessKey and SecretKey:

```cfc
s3 = new s3( accessKey = xxx, secretKey = xxx, clientRegion = xxx );
```

### A Note on Permissions

In order to use this component, you will need an IAM User with permission to work with S3. The AWS provided `AmazonS3FullAccess` policy, while it would work, is likely too expansive. Depending on your use case, you'd likely want to create a policy that restricts actions to those you need (List, Read, Write) and limits the user to specific buckets. The following would be an example of a more limited policy with read/write/list/delete permission for a bucket:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "VisualEditor0",
      "Effect": "Allow",
      "Action": [
          "s3:GetObject",
          "s3:GetObjectAcl",
          "s3:DeleteObject",
          "s3:DeleteObjectVersion",
          "s3:PutObject",
          "s3:PutObjectAcl"
      ],
      "Resource": "arn:aws:s3:::your-bucket-name/*"
    },
    {
      "Sid": "VisualEditor1",
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::your-bucket-name"
    }
  ]
}
```

### Requirements

This component depends on the .jar files contained in the `/lib` directory. All of these files can be downloaded from https://sdk-for-java.amazonwebservices.com/latest/aws-java-sdk.zip. Files other than the actual SDK .jar itself can be found in the `/third-party` directory within the SDK download.

There are two ways that you can include them in your project.

1. Include the files in your `<cf_root>/lib` directory. You will need to restart the ColdFusion server.
2. Use `this.javaSettings` in your Application.cfc to load the .jar files. Just specify the directory that you place them in; something along the lines of

	```cfc
  	this.javaSettings = {
    	loadPaths = [ '.\path\to\jars\' ]
  	};
	```

The project was most recently tested using the following jars:

- aws-java-sdk-1.12.185.jar
- jackson-dataformat-cbor-2.12.6.jar
- jackson-databind-2.12.6.jar
- jackson-core-2.12.6.jar
- jackson-annotations-2.12.6.jar
- joda-time-2.8.1.jar
