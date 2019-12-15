# Build: 
# docker build -t xmrig .
#
# Run:
# docker run --rm -it \
# 	--name xmrig \
# 	xmrig:latest
#
FROM debian:buster-slim as buildmachine

RUN apt-get update
RUN apt-get install -y git build-essential cmake libuv1-dev libssl-dev libhwloc-dev automake libtool autoconf wget

RUN git clone https://github.com/xmrig/xmrig.git

# change to 0% donation
RUN sed -i 's/kMinimumDonateLevel = 1/kMinimumDonateLevel = 0/g' xmrig/src/donate.h

# build deps for static compile
RUN cd xmrig/scripts && ./build_deps.sh

RUN mkdir xmrig/build && cd xmrig/build && cmake .. -DXMRIG_DEPS=scripts/deps && make -j$(nproc)

RUN ls -la xmrig/build
RUN pwd

# runtime
FROM debian:buster-slim

# ssh for app service deployment
#RUN apt-get install openssh-server -y && echo "root:Docker!" | chpasswd
#RUN mkdir /run/sshd
#COPY sshd_config /etc/ssh/
#EXPOSE 80 2222
#RUN /usr/sbin/sshd

COPY --from=buildmachine /xmrig/build/xmrig /usr/local/bin/xmrig

CMD [ "xmrig", "--help" ]
