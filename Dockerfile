FROM ubuntu:latest
WORKDIR /build

ADD . /build/parity

# install aarch64(armv8) dependencies and tools
RUN dpkg --add-architecture arm64
RUN echo '# source urls for arm64 \n\
	deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports/ xenial main \n\
	deb-src [arch=arm64] http://ports.ubuntu.com/ubuntu-ports/ xenial main \n\
	deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports/ xenial-updates main \n\
	deb-src [arch=arm64] http://ports.ubuntu.com/ubuntu-ports/ xenial-updates main \n\
	deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports/ xenial-security main \n\
	deb-src [arch=arm64] http://ports.ubuntu.com/ubuntu-ports/ xenial-security main \n # end arm64 section' >> /etc/apt/sources.list &&\
	sed -r 's/deb h/deb \[arch=amd64\] h/g' /etc/apt/sources.list > /tmp/sources-tmp.list && \
	cp /tmp/sources-tmp.list /etc/apt/sources.list&& \
	sed -r 's/deb-src h/deb-src \[arch=amd64\] h/g' /etc/apt/sources.list > /tmp/sources-tmp.list&&cat /etc/apt/sources.list &&\
	cp /tmp/sources-tmp.list /etc/apt/sources.list&& echo "next"&&cat /etc/apt/sources.list

# install tools and dependencies
RUN apt-get -y update && \
	apt-get upgrade -y && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		clang pkg-config curl make cmake file ca-certificates  \
		g++ gcc-aarch64-linux-gnu g++-aarch64-linux-gnu \
		libc6-dev-arm64-cross binutils-aarch64-linux-gnu \
		libc6-dev-arm64-cross libclang-dev libc6-dev-i386\
		&& \
	apt-get clean

ENV NVM_DIR="/root/.nvm"
ENV NODE_VERSION 14.2.0

# Install nvm with node and npm
RUN curl https://raw.githubusercontent.com/creationix/nvm/v0.30.2/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default \
		&& npm i

ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH      $NVM_DIR/v$NODE_VERSION/bin:$PATH

RUN npm install

# install rustup
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y

# rustup directory
ENV PATH /root/.cargo/bin:$PATH
ENV RUST_TARGETS="aarch64-unknown-linux-gnu"


# multirust add arm--linux-gnuabhf toolchain
RUN rustup target add aarch64-unknown-linux-gnu

# show backtraces
ENV RUST_BACKTRACE 1

# show tools
RUN rustc -vV && cargo -V

# build parity
RUN cd parity && \
	mkdir -p .cargo && \
	echo '[target.aarch64-unknown-linux-gnu]\n\
	linker = "aarch64-linux-gnu-gcc"\n'\
	>>.cargo/config && \
	cat .cargo/config && \
	cargo build --target aarch64-unknown-linux-gnu --release --verbose && \
	ls /build/parity/target/aarch64-unknown-linux-gnu/release/parity && \
	/usr/bin/aarch64-linux-gnu-strip /build/parity/target/aarch64-unknown-linux-gnu/release/parity

RUN file /build/parity/target/aarch64-unknown-linux-gnu/release/parity

EXPOSE 8080 8545 8180
CMD node /build/deployer/index.js
