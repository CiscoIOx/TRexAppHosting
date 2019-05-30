# TRexAppHosting
This repository contains Cisco TRex application related details on how to run it as a docker app on Cisco Catalyst 9000 series switches. We will cover a usecase where TRex docker app running on Cat9k will generate multistream traffic on each container network interafaces eth0 (vlan 700) and eth1 (vlan 500) to determine the maximum throughput that can be achieved via AppGigabitEthernet (KR port) interface of Cat9k. 

Note: AppGigabitEthernet is of bandwidth 1 Gbps.

## Pre-Requisites
* Docker installed on development machine for building docker image
* Cat9k switch with AppGigabitEthernet interface (KR Port) support

## Build TRex docker app
Do git clone of this project and run below docker command to build TRex docker image.

```
docker build -t trexapp .
```
Now save this docker image to create a tar archive. We will use this saved docker image tar archive for installing
the TRex application on Cat9k switch.

```
docker save trexapp -o trexapp.tar
```

## Cat9k Device Setup

We will setup the Cat9k switch with loopback connectivity for simplified test scenario. Interface and Vlan details are provided here for reference. If you make changes to those specific details, make sure to reflect those changes in rest of those reference in the document as well.

<img width="462" alt="TRex setup" src="https://user-images.githubusercontent.com/7672865/58609433-67b49200-825c-11e9-99e5-4358941b20a5.png">

1. Connect GigE 1/0/23 of Cat9k to GigE 1/0/24 with a loopback cable to route traffic from one port to another.

2. Configure AppGigabitEthernet1/0/1 (KR port) in trunk mode and GigE interfaces 1/0/23 (in Vlan 700), GigE 1/0/24 (in Vlan 500). Here is the corresponding IOS configuration.

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

## TRex app config setup

TRex app needs even number of network interfaces inside the container. Here we will use two container network interfaces (eth0 and eth1). TRex will generate the traffic on container interfaces eth0 and eth1, which will then routed back to the container on other interfaces like eth1 and eth0 respectively, as per our device setup. We will assign static ip address to container network interfaces eth0 (10.0.1.2) and eth1 (10.0.0.2). In TRex docker image, /etc/trex_cfg_cat9k.yaml is based on these container network interface configuration. 

Here is the corresponding TRex app IOS configuration. 
```
app-hosting appid trex
	app-vnic AppGigEthernet vlan-access
		vlan 500 guest-interface 1
			guest-ipaddress 10.0.1.2 netmask 255.255.255.0
		vlan 700 guest-interface 0
			guest-ipaddress 10.0.0.2 netmask 255.255.255.0
		app-default-gateway 10.0.1.1 guest-interface 1 
		app-resource docker
			run-opts "--cap-add=NET_ADMIN --ulimit memlock=100000000:100000000"
		app-resource package­-profile custom 
		app-resource profile custom
			cpu 7000 
			memory 2000
```
Use the docker run-opts configuration as it is and don't make any changes.

## **TRex app deployment workflow**

1. **Install saved TRex docker tar archive**

    Copy saved TRex docker image to Cat9k at USBFlash. 
    
    Then deploy TRex docker application using below IOS CLI exe command. This operation will extract tar archive and keep the docker image ready for creating the container.

   ```
   # app-hosting install appid trex package usbflash1:<path to trex docker tar file>
   ```

2. **Activate the TRex app**
    
    Now lets activate the application with pre­configured resources in 'TRex app config setup' section.

   ```
   # app-hosting activate appid trex
   ```  

3. **Start the app**

   ```
   # app-hosting start appid trex
   ```
   
4. **Get inside application container shell to connect to the trex server console and generate traffic**

  Here is the IOS CLI exec command to enter container shell.
   ```
   
   # app-hosting connect appid trex session
   
   // Connect to trex server console
   trex_shell$ ./trex-console
   
   // start 500Mbps multi stream UDP traffic
   trex_console> start -f stl/udp_1pkt_multi.py -m 500mbps -a 
   
   //viewstats
   trex_console> stats

  // to stop the traffic generation
  trex_console> stop
   ```

As you could see my TRex console stats that maximum throughput that was achieved via AppGigabitEthernet interface is 500Mbps on each of the two network interfaces inside the container.


