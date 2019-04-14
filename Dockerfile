##################################################################################
##                                                                              ##
##        Dockerfile to create an AWS Lambda layer with Kakadu installed        ##
##                                                                              ##
##################################################################################

# Same Amazon Linux version as Lambda execution environment AMI
# Cf. https://docs.aws.amazon.com/lambda/latest/dg/current-supported-versions.html
FROM amazonlinux:2017.03.1.20170812 as KAKADU_BUILDER

# Our build directory where the Kakadu source will be located
WORKDIR /build/kakadu/

# Kakadu source should be installed in a 'kakadu' directory in this project's root
COPY kakadu /build/kakadu/

# Lock to 2017.03 release (same as Lambda) and install compilation dependencies
RUN sed -i 's;^releasever.*;releasever=2017.03;;' /etc/yum.conf && \
  yum update -y && \
  yum clean all && \
  yum install -y gcc gcc-c++ make

# Compile Kakadu library, but do a clean first to make sure the directory is clean
RUN  cd /build/kakadu/make && \
  make -f Makefile-Linux-x86-64-gcc clean && \
  make -f Makefile-Linux-x86-64-gcc && \
  cp ../lib/Linux-x86-64-gcc/*.so /build/kakadu && \
  cp ../bin/Linux-x86-64-gcc/kdu_compress /build/kakadu && \
  cp ../bin/Linux-x86-64-gcc/kdu_expand /build/kakadu && \
  cp ../bin/Linux-x86-64-gcc/kdu_jp2info /build/kakadu

# Same Amazon Linux version as Lambda execution environment AMI
FROM amazonlinux:2017.03.1.20170812

# Create the directory that we'll be putting Kakadu into
WORKDIR /opt/kakadu

# Copy the files we'll need into a clean Docker image
COPY --from=KAKADU_BUILDER /build/kakadu/*.so /build/kakadu/kdu_* /opt/kakadu/

# Image is used to build an AWS Lambda layer; it doesn't need to _do_ anything
CMD ["sh", "-c", "tail -f /dev/null"]