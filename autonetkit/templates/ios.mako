hostname ${node}
! IOS Config generated by ${ank_version} on ${date} 
!
boot-start-marker
boot-end-marker
!
!
no aaa new-model
!
!
ip cef
! 
!      
service timestamps debug datetime msec
service timestamps log datetime msec
no service password-encryption
enable password cisco
ip classless
ip subnet-zero
no ip domain lookup
line vty 0 4
 exec-timeout 720 0
 password cisco
 login
line con 0
 password cisco
!
## Physical Interfaces
% for interface in node.interfaces:  
interface ${interface.id}
	description ${interface.description}
	ip address ${interface.ip_address} ${interface.subnet.netmask}   
	% if interface.ospf_cost:
	ip ospf cost ${interface.ospf_cost}
	% endif
	% if interface.isis:
    ip router isis
	% endif
   	duplex auto
	speed auto
	no shutdown
!
% endfor 
!               
## OSPF
% if node.ospf: 
router ospf ${node.ospf.process_id} 
# Loopback
  network ${node.loopback} 0.0.0.0 area 0
  log-adjacency-changes
  passive-interface ${node.ospf.lo_interface}
% for ospf_link in node.ospf.ospf_links:
  network ${ospf_link.network.network} ${ospf_link.network.hostmask} area ${ospf_link.area} 
% endfor    
% endif           
## ISIS
% if node.isis: 
router isis
  net ${node.isis.net}
% endif  
% if node.eigrp: 
router eigrp ${node.eigrp.process_id}       
% endif   
!
!                
## BGP
% if node.bgp: 
  router bgp ${node.asn}   
  bgp router-id ${node.loopback}
  no synchronization
% for subnet in node.bgp.advertise_subnets:
  network ${subnet.cidr}
% endfor 
! ibgp
% for client in node.bgp.ibgp_rr_clients:   
% if loop.first:
	! ibgp clients
% endif    
	! ${client.neighbor}
    neighbor ${client.loopback} update-source ${node.bgp.lo_interface} 
	neighbor ${client.loopback} route-reflector-client                                                   
% endfor            
% for parent in node.bgp.ibgp_rr_parents:   
% if loop.first:
	! ibgp route reflector servers
% endif    
	! ${parent.neighbor}
    neighbor ${parent.loopback} remote-as ${parent.asn}
    neighbor ${parent.loopback} update-source ${node.bgp.lo_interface} 
% endfor
% for neigh in node.bgp.ibgp_neighbors:      
% if loop.first:
	! ibgp peers
% endif 
	! ${neigh.neighbor}
    neighbor ${neigh.loopback} remote-as ${neigh.asn}
    neighbor ${neigh.loopback} update-source ${node.bgp.lo_interface}
    neighbor ${neigh.loopback} next-hop-self
% endfor
! ebgp
% for neigh in node.bgp.ebgp_neighbors:      
	! ${neigh.neighbor} 
    neighbor ${neigh.dst_int_ip} remote-as ${neigh.asn}
    neighbor ${neigh.dst_int_ip} send-community
% endfor    
% endif 
