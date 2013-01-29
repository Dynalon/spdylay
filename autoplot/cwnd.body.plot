# Congestion control send window
plot "-" using 1:7 title "snd_cwnd" with lines, \
  "-" using 1:($9/1460) title "snd_wnd" with lines, \
  "-" using 1:($8>=2147483647 ? 0 : $8) title "ssthresh" with lines
