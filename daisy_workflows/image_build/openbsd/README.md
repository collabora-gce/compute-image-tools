# OpenBSD Image Builds

Example Daisy invocations:

```shell

# Building OpenBSD 6.1 in a Debian 9 virtual machine
daisy -project my-project \
      -zone us-west1-a \
      -variables \
          source_image=projects/debian-cloud/global/images/family/debian-9
          image_dest=gs://bucket/images/openbsd-6.1.tar.gz \
          version=6.1 \
          arch=amd64 \
          mirror=ftp.usa.openbsd.org \
      openbsd-builder.wf.json

```

The `openbsd` directory contains scripts and configurations to create a basic
OpenBSD raw disk and upload it to Google Cloud Storage via Daisy. If you want
to create virtual machines in GCE based on this raw disk you should create an
image manually in the web interface. For now this disk does not contain
the latest GCE agents since they are not available for OpenBSD yet.
