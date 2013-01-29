# Congestion control send window
plot "-" using 2:($4/1024) title "push" with linespoints, \
  "-" using 2:($4/1024) title "fetch" with linespoints
