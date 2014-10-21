#!/bin/bash
set -e

echo "Fetching Consul..."
cd /tmp
wget https://dl.bintray.com/mitchellh/consul/0.4.1_linux_amd64.zip -O consul.zip
wget https://dl.bintray.com/mitchellh/consul/0.4.1_web_ui.zip -O consul-ui.zip

echo "Installing Consul..."
unzip consul.zip >/dev/null
chmod +x consul
mv consul /usr/local/bin/consul
mkdir -p /etc/consul.d
mkdir -p /mnt/consul/{data,ui}
mkdir -p /etc/service
unzip consul-ui.zip >/dev/null
mv dist/* /mnt/consul/ui/
rm /tmp/consul.zip
rm /tmp/consul-ui.zip

# Setup the join address
echo "Configure IPs..."
cat >/etc/service/consul-join << EOF
export CONSUL_JOIN="10.0.1.10 10.0.1.11 10.0.1.12"
EOF
chmod 0644 /etc/service/consul-join

# Configure the server
echo "Configure server..."
cat >/etc/service/consul << EOF
export CONSUL_FLAGS="-server -bootstrap-expect=3 -data-dir=/mnt/consul/data -ui-dir=/mnt/consul/ui -client=0.0.0.0"
EOF
chmod 0644 /etc/service/consul

# Add "first start" join service
echo "Creating 'join' service..."
cat >/etc/init/consul-join.conf <<"EOF"
description "Join the consul cluster"

start on started consul
stop on stopped consul

task

script
  if [ -f "/etc/service/consul-join" ]; then
    . /etc/service/consul-join
  fi

  # Keep trying to join until it succeeds
  set +e
  while :; do
    logger -t "consul-join" "Attempting join: ${CONSUL_JOIN}"
    /usr/local/bin/consul join \
      ${CONSUL_JOIN} \
      >>/var/log/consul-join.log 2>&1
    [ $? -eq 0 ] && break
    sleep 5
  done

  logger -t "consul-join" "Join success!"
end script
EOF
chmod 0644 /etc/init/consul-join.conf

# Add actual service
echo "Creating service..."
cat >/etc/init/consul.conf <<"EOF"
description "Consul agent"

start on runlevel [2345]
stop on runlevel [!2345]

respawn

script
  if [ -f "/etc/service/consul" ]; then
    . /etc/service/consul
  fi

  # Make sure to use all our CPUs, because Consul can block a scheduler thread
  export GOMAXPROCS=`nproc`

  exec /usr/local/bin/consul agent \
    -config-dir="/etc/consul.d" \
    ${CONSUL_FLAGS} \
    >>/var/log/consul.log 2>&1
end script
EOF
chmod 0644 /etc/init/consul.conf

# Start service
echo "Starting service..."
initctl start consul

