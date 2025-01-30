FROM python:3.11.9-alpine3.20 as builder

# Add the community repo for access to patchelf binary package
RUN echo 'https://dl-cdn.alpinelinux.org/alpine/v3.20/community/' >> /etc/apk/repositories
RUN apk --no-cache upgrade && apk --no-cache add build-base tar musl-utils openssl-dev patchelf
RUN pip install --upgrade pip
# patchelf-wrapper is necessary now for cx_Freeze, but not for Curator itself.
# keep cx_Freeze 7.2.6 to avoid bug with symlinks https://ic-consult.atlassian.net/browse/SLP-4156
RUN pip3 install cx_Freeze==7.2.6 patchelf-wrapper

COPY . .
RUN ln -s /lib/libc.musl-x86_64.so.1 ldd
RUN ln -s /lib /lib64
RUN pip3 install -r requirements.txt
RUN python3 setup.py build_exe --silent

FROM alpine:3.20
RUN apk --no-cache upgrade && apk --no-cache add openssl-dev expat
COPY --from=builder build/exe.linux-x86_64-3.11 /curator/
RUN mkdir /.curator

USER 65534:65534
ENV LD_LIBRARY_PATH /curator/lib:$LD_LIBRARY_PATH
ENTRYPOINT ["/curator/curator"]

