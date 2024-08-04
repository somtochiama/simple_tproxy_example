# simple_tproxy_example with Docker

This repository includes instruction for testing out the tproxy
example with two docker containers.

The simplest possible working example of TPROXY transparent proxying.

In transparent proxying, someone's path to the internet runs through you, and
you choose to have some/all of their traffic to remote hosts pass through your
logic. Maybe you just inspect it and forward it directly on to the intended
destination. Maybe you send it to the intended destination, but tunneled through
a VPN. Maybe you forward it, but alter one or both sides of the conversation.
Maybe you just outright impersonate the remote host! (Not that it has to be
sinister; maybe you're a hotel wifi login portal).

It's "transparent" because the client doesn't have to configure anything
(browser proxy settings, etc) to make it work: both the human and the device
they're using just see a "normal" internet connection.

TPROXY is an iptables + Linux kernel feature that makes transparent proxying
extremely straightforward: your code does a single exotic setsockopt(), and
then you bind() listen() accept() etc exactly the same as if you were writing
an ordinary TCP server. Behind the scenes, packets you send through your
accepted sockets will be spoofing the client's intended destination. Of course,
since you're working with ordinary socket file descriptors, you can plug right
into frameworks like libevent.

To run this example, you'll want one container to be the proxy, and another to
be the client. 

First, build the docker container on your local machine
```
docker build -t tproxy-example .
```

Create two containers (with NET_ADMIN capabilities because we want to modify some
networking things) connected with a docker network.

```
docker network create tproxy-net
docker run -dit --cap-add=NET_ADMIN --network tproxy-net --name tproxy tproxy-example
docker run -dit --cap-add=NET_ADMIN --network tproxy-net --name tproxy-client tproxy-example
```

Exec into the proxy:

```
docker exec -it tproxy /bin/bash

# run ip addr to find out address associated with
# eth0 interface
iptables -t mangle -A PREROUTING -i eth0 -p tcp --dport 80 -m tcp
          -j TPROXY --on-ip 172.19.0. --on-port 1234 --tproxy-mark 1/1

sysctl -w net.ipv4.ip_forward=1
ip rule add fwmark 1/1 table 1
ip route add local 0.0.0.0/0 dev lo table 1
./tproxy_captive_portal 172.19.0.2
```


Exec into the client container:

```
docker exec -it tproxy-client /bin/bash

# change the default gateway to go to the proxy
# so packets get routed to it

ip route del default; ip route add default via <eth addr from proxy container above>
curl http://11.22.33.44/whatever.html
# SUCCESS, REQUEST IS SERVED BY TRANSPARENT PROXY!
```
