##################################################################################
##                                                                              ##
##        Dockerfile to create an AWS Lambda layer with Kakadu installed        ##
##                                                                              ##
##################################################################################

# Same Amazon Linux version as Lambda execution environment AMI
# Cf. https://docs.aws.amazon.com/lambda/latest/dg/current-supported-versions.html
FROM amazonlinux:2.0.20191217.0 as KAKADU_BUILDER

# Our build directory where the Kakadu source will be located
WORKDIR /build/kakadu/

# Kakadu source should be installed in a 'kakadu' directory in this project's root
COPY kakadu /build/kakadu/

# Lock to 2019.12 release (same as Lambda) and install compilation dependencies
RUN sed -i 's;^releasever.*;releasever=2019.12;' /etc/yum.conf && \
  yum install -y --setopt=skip_missing_names_on_install=False \
    gcc-7.3.1 \
    gcc-c++-7.3.1 \
    make-3.82 \
    libjpeg-turbo-1.2.90-6.amzn2.0.3 \
    libtiff-4.0.3 \
    libtiff-devel-4.0.3 && \
  yum update -y && \
  yum clean all

# Compile Kakadu library, but do a clean first to make sure the directory is clean
RUN  cd /build/kakadu/make && \
  make -f Makefile-Linux-x86-64-gcc clean && \
  make -f Makefile-Linux-x86-64-gcc && \
  mkdir -p /build/kakadu/artifacts && \
  cp ../lib/Linux-x86-64-gcc/*.so /build/kakadu/artifacts && \
  cp ../bin/Linux-x86-64-gcc/kdu_compress /build/kakadu/artifacts && \
  cp ../bin/Linux-x86-64-gcc/kdu_expand /build/kakadu/artifacts && \
  cp ../bin/Linux-x86-64-gcc/kdu_jp2info /build/kakadu/artifacts && \
  cp /usr/lib64/libtiff*.so /build/kakadu/artifacts && \
  cp /usr/lib64/libjpeg.so.* /build/kakadu/artifacts && \
  cp /usr/lib64/libjbig.so.* /build/kakadu/artifacts

# Same Amazon Linux version as Lambda execution environment AMI
FROM amazonlinux:2.0.20191217.0

# Create the directory that we'll be putting Kakadu libs into
WORKDIR /opt/lib

# Copy the library files we'll need into a clean Docker image
COPY --from=KAKADU_BUILDER /build/kakadu/artifacts/*.so /opt/lib/
COPY --from=KAKADU_BUILDER /build/kakadu/artifacts/libjpeg.so.* /opt/lib/
COPY --from=KAKADU_BUILDER /build/kakadu/artifacts/libjbig.so.* /opt/lib/

# Let's use symlinks to conserve space on our final Lambda image
RUN cd /opt/lib && \
  ln -s libtiffxx.so libtiffxx.so.5.2.0 && \
  ln -s libtiffxx.so libtiffxx.so.5 && \
  ln -s libtiff.so libtiff.so.5.2.0 && \
  ln -s libtiff.so libtiff.so.5

# Then we can output a little human friendly output to confirm stuff is installed
RUN if ls /opt/lib/libkdu_v*.so 1> /dev/null 2>&1; then echo "Kakadu libs installed"; fi
RUN if ls /opt/lib/libtiff.so.* 1> /dev/null 2>&1; then echo "TIFF libs installed"; fi
RUN if ls /opt/lib/libjpeg.so.* 1> /dev/null 2>&1; then echo "JPEG libs installed"; fi
RUN if ls /opt/lib/libjbig.so.* 1> /dev/null 2>&1; then echo "JBIG libs installed"; fi

# Create the directory that we'll be putting Kakadu bins into
WORKDIR /opt/bin

# Copy the binary files we'll need into the clean Docker image
COPY --from=KAKADU_BUILDER /build/kakadu/artifacts/kdu_* /opt/bin/

RUN if [ -f "/opt/bin/kdu_compress" ]; then echo "Kakadu bins installed"; fi

# Image is used to build an AWS Lambda layer; it doesn't need to _do_ anything
CMD ["sh", "-c", "tail -f /dev/null"]
