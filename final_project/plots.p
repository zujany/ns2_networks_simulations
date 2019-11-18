set grid
set title "Burtiness vs Arrival delay of On/Off source sharing resources with CBR"  

plot "0.dat" u 1:3 title "CBR 0%" w l, '' u 1:3:(($4 /100)*$3) title "" with yerrorbars
replot "25.dat" u 1:3 title "CBR 25%" w l, '' u 1:3:(($4 /100)*$3) title "" with yerrorbars
replot "50.dat" u 1:3 title "CBR 50%" w l, '' u 1:3:(($4 /100)*$3) title "" with yerrorbars
replot "75.dat" u 1:3 title "CBR 75%" w l, '' u 1:3:(($4 /100)*$3) title "" with yerrorbars

set xrange [2 : 21]
set yrange [0 : 0.1]
replot

pause -1 "Hit any key to continue"


