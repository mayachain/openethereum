FROM ubuntu:latest
WORKDIR /mayachain

ADD . /mayachain

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

ENV NODE_PATH $NVM_DIR/versions/node/v$NODE_VERSION/lib/node_modules
ENV PATH      $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

RUN npm install

# install rustup
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y

# rustup directory
ENV PATH /root/.cargo/bin:$PATH

# show backtraces
ENV RUST_BACKTRACE 1

# show tools
RUN rustc -vV && cargo -V

RUN  cargo build --release --verbose && \
	ls /mayachain/target/release/openethereum

RUN file /mayachain/target/release/openethereum

EXPOSE 8545 8646 30303 30303/udp
CMD node /mayachain/deployer/index.js
