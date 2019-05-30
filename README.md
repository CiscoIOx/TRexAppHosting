# TRexAppHosting
This repository contains Cisco TRex application related details on how to run it as an app on Cisco Catalyst 9000 series switches..



# Goal

Lets deploy TRex as a docker app on Cat9k and have TRex generate multistream traffic on container
ports eth0 (on vlan 700) and eth1 (on vlan 500) to determine the maximum throughput of Cat9k KR port
that can be achieved without packet drop.



## Prerequisites
Here are the prerequisites needed for TRex Docker app. 

1. Even number of network interfaces inside the container. Here we will use two interfaces (eth0 and eth1) 

2. Additional docker runtime options support: 

```
--cap-add=NET_ADMIN --ulimit memlock=100000000:100000000
```

3. KR port support 



## Test setup

<img width="462" alt="TRex setup" src="https://user-images.githubusercontent.com/7672865/58609433-67b49200-825c-11e9-99e5-4358941b20a5.png">



1. Connect GigE 1/0/23 of Cat9k to GigE 1/0/24 with a loopback cable to route traffic from one port to another. 

2. Configure KR port (AppGigabitEthernet1/0/1) in trunk mode and GigE interfaces 1/0/23 (in Vlan 700), GigE 1/0/24 (in Vlan 500) 

```
interface AppGigabitEthernet1/0/1 
	switchport trunk allowed vlan 700,500
	switchport mode trunk

interface GigabitEthernet1/0/23 
	switchport access vlan 700
!
interface GigabitEthernet1/0/24
	switchport access vlan 500
interface Vlan500
	ip address 10.0.1.1 255.255.255.0
!
interface Vlan700
	ip address 10.0.0.1 255.255.255.0
```

3. Configure TRex IOx application activation details.

```
app-hosting appid trex
	app-vnic AppGigEthernet vlan-access
		vlan 500 guest-interface 1
			guest-ipaddress 10.0.1.2 netmask 255.255.255.0
		vlan 700 guest-interface 0
			guest-ipaddress 10.0.0.2 netmask 255.255.255.0
		app-default-gateway 10.0.1.1 guest-interface 1 
		app-resource docker
			run-opts "--cap-add=NET_ADMIN --ulimit memlock=100000000:100000000 --entrypoint '/bin/sleep 10000'"
		app-resource package­profile custom app-resource profile custom
			cpu 7000 
			memory 2000
```



4. Use below trex_cfg.yaml for routing traffic externally from the container as per above test setup
   diagram. Store this file in usbflash drive of cat9k, lets say the path is **usbflash1:trex_cfg.yaml**



```
[ms-p0-31_1_RP_0:/]$ cat /vol/usb1/trex_cfg.yaml
- port_limit	: 2 
	version 		: 2
	low_end 		: true
	interfaces	:	["eth0", "eth1"]
	port_info		: # set eh mac addr
-	ip : 10.0.0.2 default_gw : 10.0.1.2
-	ip : 10.0.1.2 default_gw : 10.0.0.2
```





## **IOx TRex app deployment**



1. **Install TRex package/dockerimage stored in USBFlash:**

   ```
   # app-hosting install appid trex package usbflash1:<path to trex tar file>
   ```

2. **Activate the application with pre­configured resources (refer test setup section #3)**

   ```
   # app-hosting activate appid trex
   ```

   

3. **Upload the custom trex configuration into trex application under /iox_data/appdata**

   ```
   # app-hosting data appid trex copy usbflash1:trex_cfg.yaml trex_cfg.yaml
   ```

   

4. **Start the app**

   ```
   #	app-hosting start appid trex
   ```

   

5. **Get inside application container shell and start trex manually**

   ```
   # app-hosting connect appid trex session
   // start trex server
   trex_shell$ ./t-rex-64 -i --cfg /iox_data/appdata/trex_cfg.yaml
   ```

   

6. **Get inside application container shell in another terminal to connect to the trex server console and generate traffic**

   ```
   # app-hosting connect appid trex session
   // Connect to trex server console
   trex_shell$ ./trex-console
   
   // start 500Mbps multi stream UDP traffic
   trex_console> start -f stl/udp_1pkt_multi.py -m 500mbps -a //viewstats
   trex_console> stats
   ```


**Maximum throughput (traffic generation rate) observed on each vlan of KR port without packet drop, as per TRex stats = 500Mbps**

