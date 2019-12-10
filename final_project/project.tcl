set ns [new Simulator]
# set tf [open output.tr w]

# $ns trace-all $tf

# if {$argc != 2}
# {
# Error "\nCommand: ns project.tcl \n\n "
# }

#Setting constants provided by user
set arg_b [lindex $argv 0] ;# 1st run time argument
set arg_lambda_cbr [lindex $argv 1] ;# 2nd run time argument
set simulation_total_time [lindex $argv 2] ;# 3rd run time argument
set N [lindex $argv 3] ; # 4th run time argument

# set simulation_total_time 1000.0 ; # !!!!!!!!!!! before Nt
# set N 10.0 ; # !!!!!!!!!!!


#Setting constants valids for all the simulations
set usedBW 80
set Ton 0.001
set rateCbr 0
set int_restart_crb 100

set sentCounter 0.0
set dropCounter 0.0
set sum1 0.0
set sum2 0.0
set Zt 0.0
set T [expr $simulation_total_time / $N] ; # !!!!!!!!!!!
set interval $T

proc finish {} {
global ns 
$ns flush-trace
# close $tf
exit 0
}

proc settingSources {b lambdaCbr_} {
	global sourceOnOff cbr1 Ton usedBW rateCbr
	set Toff [expr ($b * $Ton) - $Ton]
	set lambdaOnOff [expr $usedBW - ($lambdaCbr_ * $usedBW)]
	set D [expr $b * $lambdaOnOff]Mb
	set rateCbr [expr $lambdaCbr_ * $usedBW]Mb;

	$sourceOnOff set idle_time_ $Toff; #Idle time = Toff, changes in each simulation
	$sourceOnOff set rate_ $D; # !!!! changes depending of B, changes in each simulation
	$cbr1 set rate_ $rateCbr; # changes with landa CBR in each simulation
	
	##puts "b: $b lambdaCbr_: $lambdaCbr_"
	##puts "sourceOnOff: Idle_time: [$sourceOnOff set idle_time_], Burst_time: [$sourceOnOff set burst_time_], Rate: [$sourceOnOff set rate_ ]"
	##puts "sourceCbr: Rate: [$cbr1 set rate_]"
	#puts "Toff = $Toff D = $D"
	##puts "finishing to setting the sources"
}

proc restartCBR { } {
	global cbr1 int_restart_crb ns udp2_src rateCbr
	$cbr1 stop
	delete $cbr1
	set cbr1 [new Application/Traffic/CBR]
	$cbr1 set packet_size_ 1000 
	$cbr1 set rate_ $rateCbr; # changes with landa CBR in each simulation
	$cbr1 set random_ 1
	#attach the application to the agent
	$cbr1 attach-agent $udp2_src
	#set when the application begins and stops in seconds 
	$cbr1 start
	$ns at [expr [$ns now] + $int_restart_crb] "restartCBR"
}

#Calculating confidence intervals 

proc confidence_interval { } {
	global ns dsamp_on_off interval sum1 sum2 Zt
	# puts "ns: [$ns now], samples_object: $samples_object"
	##puts "time: [$ns now], Zt(mean): [$dsamp_on_off mean]"

	#optional
	# puts "global monitor drops: [$monitor_n0_n1 set pdrops_] \
	# 		flow monitor drops: [$fdesc_on_off set pdrops_] \
	# 		flow monitor arrivals: [$fdesc_on_off set parrivals_]"

	set Zt [$dsamp_on_off mean]
   	set sum1 [expr $sum1 + $Zt]
    set sum2 [expr $sum2 + ($Zt * $Zt)]
	##puts "CI calc: sum1=$sum1 sum2=$sum2"

	# puts "size of the sample of flow monitor: [$dsamp_on_off set int_]" ; #gives the size of the sample
	$dsamp_on_off reset; #empties the sample
	$ns at [expr [$ns now] + $interval] "confidence_interval"
}

proc errorCalc { } {
	global N simulation_total_time sum2 sum1 Zt T arg_b arg_lambda_cbr
	#	puts "sum1=$sum1 sum2=$sum2"
	set EZt2 [expr $sum2 / $N]
	set EZt [expr ($sum1 * $sum1) / ($N * $N)]
	# puts "EZt2=$EZt2 EZt=$EZt"
	set standartDeviation [expr sqrt($EZt2 - $EZt)]
	set errorZt [expr 4.5 * $standartDeviation]
	set errorZnt [expr $errorZt * (sqrt($T / $simulation_total_time))]
	##puts "errorZt: $errorZt, errorZnt:$errorZnt"

	set EZt3 [expr $sum1 / $N]

	puts "$arg_b\t$arg_lambda_cbr\t$EZt3\t[expr ($errorZnt / $EZt3) * 100 ]\t$simulation_total_time\t$N"

}



#create 2 nodes
set n0 [$ns node];
set n1 [$ns node];
#create a duplex link between the nodes, with 100Mbits/s of BW and 1ms of latency
$ns duplex-link $n0 $n1 100Mb 1ms DropTail
#buffer of the queue of the downlink equals to 5 packets
$ns queue-limit $n0 $n1 10000000; # Definir!!!! 
#create UDP agents
set udp1_src [new Agent/UDP]
$udp1_src set fid_ 1
set udp1_dest [new Agent/Null]

set udp2_src [new Agent/UDP]
set udp2_dest [new Agent/Null]
#attach agents
$ns attach-agent $n0 $udp1_src
$ns attach-agent $n1 $udp1_dest
$ns attach-agent $n0 $udp2_src
$ns attach-agent $n1 $udp2_dest
#connect both agents
$ns connect $udp1_src $udp1_dest
$ns connect $udp2_src $udp2_dest

#Generating traffic
#setting source ON/OF
set sourceOnOff [new Application/Traffic/Exponential]
$sourceOnOff set burst_time_ 0.001; # equal to Ton
# $sourceOnOff set rate_ 90Mb; # !!!! changes depending of B, changes in each simulation
$sourceOnOff set packetSize_ 1000 #bytes
#attach the application to the agent
$sourceOnOff attach-agent $udp1_src

$ns at 0.0 "settingSources $arg_b $arg_lambda_cbr" 

#set when the application begins and stops in seconds 
$ns at 0.0 "$sourceOnOff start"
# $ns at 100 "$sourceOnOff stop"; #????

#setting source CBR
set cbr1 [new Application/Traffic/CBR]
$cbr1 set packet_size_ 1000 
#$cbr1 set rate_ 90Mb; # changes with landa CBR in each simulation 
#the application will send packets separated by a random uniformly distributed delay
$cbr1 set random_ 1
#attach the application to the agent
$cbr1 attach-agent $udp2_src
#set when the application begins and stops in seconds 
$ns at 0.0 "$cbr1 start"
# $ns at 100.0 "$cbr1 stop"; #?????
$ns at $int_restart_crb "restartCBR"

#Monitor

set monitor_n0_n1 [$ns makeflowmon Fid]
$ns attach-fmon [$ns link $n0 $n1] $monitor_n0_n1
set samples_object [new Samples]
$monitor_n0_n1 set-delay-samples $samples_object
set fdesc_on_off [new QueueMonitor/ED/Flow]
set dsamp_on_off [new Samples]
$fdesc_on_off set-delay-samples $dsamp_on_off
set classif [$monitor_n0_n1 classifier]
set slot [$classif installNext $fdesc_on_off]
$classif set-hash auto $udp1_src $udp1_dest 1 $slot


$ns at $interval "confidence_interval"


$ns at [expr $simulation_total_time + 0.001] "errorCalc"
$ns at [expr $simulation_total_time + 0.001] "finish"; #max 2h of execution time 
$ns run
