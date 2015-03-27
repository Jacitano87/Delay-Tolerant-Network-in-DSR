# Define options
set val(chan) Channel/WirelessChannel ;#Channel Type
set val(prop) Propagation/TwoRayGround ;# radio-propagation model
set val(netif) Phy/WirelessPhy ;# network interface type
set val(mac) Mac/802_11 ;# MAC type
set val(ll) LL ;# link layer type
set val(ant) Antenna/OmniAntenna ;# antenna model
set val(ifqlen) 50 ;# max packets in ifq
set val(rxPower) 1.11 ;# (in W)
set val(txPower) 1.11 ;# (in W)
set val(energymodel) EnergyModel ;#
set val(initialenergy) 150 ;# (in Joule)
set val(sleeppower) 0.02 ;# energia consumata in stato di sleep
set val(tp) 0.03 ;# Energia consumata per la transizione dallo stato di sleep a quello di attivita'...
#set val(ifq) Queue/DropTail/PriQueue ;# interface queue type

# DumbAgent no routing!, AODV, DSDV, DSR
set val(rp) DSR; #
if { $val(rp) == "DSR" } {
set val(ifq) CMUPriQueue
} else {
set val(ifq) Queue/DropTail/PriQueue
}

set val(x) 1000
set val(y) 1000
set val(numeroNodi) 5


set ns [new Simulator]

set topo [new Topography]
$topo load_flatgrid $val(x) $val(y)


set f [open out.tr w]
$ns trace-all $f
set nf [open out.nam w]
$ns namtrace-all-wireless $nf $val(x) $val(y)
$ns use-newtrace

set god [create-god $val(numeroNodi)]

set chan_1_ [new $val(chan)]

$ns node-config -adhocRouting $val(rp) \
-llType $val(ll) \
-macType $val(mac) \
-ifqType $val(ifq) \
-ifqLen $val(ifqlen) \
-antType $val(ant) \
-propType $val(prop) \
-phyType $val(netif) \
-topoInstance $topo \
-agentTrace ON \
-routerTrace ON \
-macTrace ON \
-movementTrace ON \
-channel $chan_1_ \
-energyModel $val(energymodel) \
-initialEnergy $val(initialenergy) \
-rxPower $val(rxPower) \
-txPower $val(txPower)

for {set i 0} {$i<$val(numeroNodi)} {incr i} {
set node($i) [$ns node]
# disable random motion for static network
$node($i) random-motion 1
$node($i) start
}

#sorgente
set udp(0) [new Agent/UDP]
$ns attach-agent $node(0) $udp(0)
#ricevente
set null(0) [new Agent/Null]
$ns attach-agent $node(4) $null(0)

set cbr(0) [new Application/Traffic/CBR]
$cbr(0) set packetSize_ 512
$cbr(0) set interval_ 0.2
$cbr(0) set random_ 1
$cbr(0) set maxpkts_ 10000
$cbr(0) attach-agent $udp(0)

$ns connect $udp(0) $null(0)
$ns at 1.0 "$cbr(0) start"

#posizione iniziale a tutti i nodi
for {set i 0} {$i < $val(numeroNodi)} {incr i} {
$ns initial_node_pos $node($i) 30
}

$ns at 1000 "finish"

proc finish {} {
	global ns f nf
		$ns flush-trace
	close $f
	close $nf
	# puts "running nam..."
	exec nam out.nam &
	exit 0
}

$ns run
