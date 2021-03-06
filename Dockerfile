FROM ubuntu:14.04

MAINTAINER tcnksm "https://github.com/tcnksm"

# Install packages for building ruby
RUN apt-get update
RUN apt-get install -y --force-yes build-essential curl git autoconf
RUN apt-get install -y --force-yes zlib1g-dev libssl-dev libreadline-dev libyaml-dev libxml2-dev libxslt-dev libsnappy-dev
RUN apt-get clean

RUN apt-get install -y --force-yes libtool
RUN apt-get clean

# Install sparkey
RUN git clone https://github.com/spotify/sparkey.git && (cd sparkey && autoreconf --install && ./configure && make && sudo make install && sudo ldconfig) && rm -rf sparkey

# Install rbenv and ruby-build
RUN git clone https://github.com/sstephenson/rbenv.git /root/.rbenv
RUN git clone https://github.com/sstephenson/ruby-build.git /root/.rbenv/plugins/ruby-build
RUN /root/.rbenv/plugins/ruby-build/install.sh
ENV PATH /root/.rbenv/bin:$PATH
RUN echo 'eval "$(rbenv init -)"' >> /etc/profile.d/rbenv.sh # or /etc/profile
RUN echo 'eval "$(rbenv init -)"' >> .bashrc

# Install multiple versions of ruby
ENV CONFIGURE_OPTS "--disable-install-doc --enable-shared"
ADD ./versions.txt /root/versions.txt
RUN xargs -L 1 rbenv install < /root/versions.txt

# Install Bundler for each version of ruby
RUN echo 'gem: --no-rdoc --no-ri --no-document' >> /.gemrc
RUN bash -l -c 'for v in $(cat /root/versions.txt); do rbenv global $v; gem update --system && gem install bundler; done'

# Generate a SSH key
RUN apt-get -y install openssh-client
RUN ssh-keygen -q -t rsa -N '' -f /id_rsa

RUN mkdir /root/.ssh
RUN chmod 700 /root/.ssh
RUN mv /id_rsa* /root/.ssh
RUN chmod 700 /root/.ssh/*

# show public key
RUN cat /root/.ssh/id_rsa.pub

# Add GHE to known hosts
RUN ssh-keyscan git.musta.ch >> ~/.ssh/known_hosts

# Clone Monorail
RUN git clone git@git.musta.ch:airbnb/airbnb.git
RUN mv /airbnb /root/airbnb

RUN apt-get install -y --force-yes libtool libcurl3-dev libmysqlclient-dev libmemcached-dev libsqlite3-dev
RUN apt-get clean

# Install Monorail Gems
RUN cd /root/airbnb && rbenv local 1.9.3-p551 && bash --login -c bundle
