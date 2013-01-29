#set terminal postscript eps color size 8,7
#set terminal postscript eps color size 8,5

set terminal postscript enhanced color size 10,7

set xtics nomirror
set ytics nomirror

set key left top

set grid linecolor rgb "black"

set style line 1 lt 1 lw 2 pt 7
set style line 2 lt 1 lw 2 pt 9

#show timestamp
set xlabel "time in sec"
set ylabel "snd_cwnd in segments"
