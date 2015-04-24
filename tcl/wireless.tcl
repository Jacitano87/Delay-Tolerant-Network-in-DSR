# Define options
set val(chan) Channel/WirelessChannel ;#Channel Type
set val(prop) Propagation/TwoRayGround ;# radio-propagation model
set val(netif) Phy/WirelessPhy ;# network interface type
set val(mac) Mac/802_11 ;# MAC type
set val(ll) LL ;# link layer type
set val(ant) Antenna/OmniAntenna ;# antenna model
set val(ifqlen) 50 ;# max packets in ifq
set val(rxPower) 0.1 ;# (in W)
set val(txPower) 0.3 ;# (in W)
set val(idlePower) 0.005;
set val(energymodel) EnergyModel ;#
set val(initialenergy) 100 ;# (in Joule)
set val(sleepPower) 0.02 ;# energia consumata in stato di sleep
set val(tp) 0.05 ;# Energia consumata per la transizione dallo stato di sleep a quello di attivita'...
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
set val(numeroNodi) 20


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
-txPower $val(txPower) \
-idlePower $val(idlePower) \
-sleepPower $val(sleepPower)

for {set i 0} {$i<$val(numeroNodi)} {incr i} {
set node($i) [$ns node]
# disable random motion for static network
$node($i) random-motion 1
$node($i) start
}


set source_node_list {0 2 4 6 8 10 12 14 16 18}
set dest_node_list {1 3 5 7 9 11 13 15 17 19}

for {set i 0} {$i < [llength $source_node_list]} {incr i} {
    #Create udp agent
    set udp($i) [new Agent/UDP]
    set source [lindex $source_node_list $i]
    $ns attach-agent $node($source) $udp($i)

    #create cbr
    set cbr($i) [new Application/Traffic/CBR]
    $cbr($i) set packetSize_ 512
    $cbr($i) set interval_ 0.5
    $cbr($i) set random_ 1
    $cbr($i) set maxpkts_ 100000
    $cbr($i) attach-agent $udp($i)

    #Create a Null agent ( traffic sink)
    set sink($i) [new Agent/LossMonitor]
    set dest [lindex $dest_node_list $i]
    $ns attach-agent $node($dest) $sink($i)

    #Connet source and dest Agents
    $ns connect $udp($i) $sink($i)
}

for {set i 0} {$i < [llength $source_node_list]} {incr i} {
    $ns at 1.0 "$cbr($i) start"
}



#posizione iniziale a tutti i nodi
for {set i 0} {$i < $val(numeroNodi)} {incr i} {
$ns initial_node_pos $node($i) 30
}

$ns at 1001 "finish"

proc finish {} {
	global ns f nf
		$ns flush-trace
	close $f
	close $nf
	# puts "running nam..."
	#exec nam out.nam &
	exit 0
}

$ns run
