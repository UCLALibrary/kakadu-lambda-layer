# kakadu-lambda-layer

An [AWS Lambda](https://aws.amazon.com/lambda/) layer that provides Kakadu's functionality to other AWS [Lambda functions](https://docs.aws.amazon.com/lambda/latest/dg/lambda-introduction-function.html).

### Prerequisites

In order to build the [Lambda layer](https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html), you must have a few prerequisites available and/or pre-installed on your system:

* [img2lambda](https://github.com/awslabs/aws-lambda-container-image-converter)
* [docker](https://www.docker.com/products/docker-engine)
* [kakadu](http://kakadusoftware.com/)

The kakadu source code is proprietary and must be obtained from Kakadu Software directly (for a fee). It should be put into a `kakadu` directory within the root of this project. You'll see this directory's name is in the `.gitignore` to prevent you from accidentally checking it into version control.

Note: In the Zip file Kakadu delivers to you, the source code will be in a directory that is named with your license number. Put the source code in the 'kakadu' directory directly. Don't put the directory with your license number in there.

The installation instructions for the other two prerequisites can be found on their websites. Both should be available from your system's $PATH.

### Building

Once you have all the prerequisites mentioned in the introduction installed, you're ready to generate an AWS Lambda layer. First, build the Docker image:

    docker build --squash -t kakadu-lambda-layer .

Note that the `squash` argument is an experimental Docker feature; to use it, experimental features must be enabled in your local Docker daemon.

After building your Docker image, you can run the image converter. This will generate the AWS Lambda layer from your Docker image:

    img2lambda -i kakadu-lambda-layer:latest -r us-east-1

You can choose to use a different region or, in addition, use any of the other configuration options that are described in the image converter's documentation. You, of course, have to be using an AWS account that has the proper permissions to create a Lambda layer. These credentials are often stored in the local `~/.aws/credentials` file. For more information about what permissions are needed, consult img2lambda's documentation on their GitHub page.

Once you have run the above, you will have the new layer's information written to a `output/layers.yaml` file. The value(s) from this file can be fed to an AWS Lambda function's deployment. This will allow your AWS Lambda function to use the Kakadu layer as its base.

### Contact

If you have any questions, feel free to contact Kevin at <a href="mailto:ksclarke@ksclarke.io">ksclarke@ksclarke.io</a>. If you discover a bug or have suggestions on how to improve this project, please open a ticket in the project's [issue queue](https://github.com/UCLALibrary/kakadu-lambda-layer/issues).
