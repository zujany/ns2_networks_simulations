#!/bin/sh
for i in 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20
do
	# arguments: b lambda_Cbr simulation_total_time partitions(N)
  ns project.tcl $i 0.25 1000.0 20.0
done