# INSIEMI DEL PROBLEMA
set SETT ordered;
set sett within SETT;
#data;
#set SETT:= c1 c2 c3 c4 c5 c6;
# PARAMETRI DEL PROBLEMA
# coefficienti f.o.
param cp{SETT};
param cs{SETT};

# coefficienti vincoli
param d{SETT};
param l{SETT};

# VARIABILI
var x{SETT};
var s{SETT};

# F.O.
minimize obj: (sum{j in SETT}cs[j]*s[j])   +   (sum{j in SETT} x[j]*cp[j] );

# VINCOLI
subject to vin1 {j in sett}:  x[j] + s[prev(j, SETT)] = d[j] + s[j];	
subject to vin2 {j in SETT}: x[j] >= 0;
subject to vin5 {j in SETT}: x[j] <= l[j];
subject to vin3 {j in SETT}: s[j] >= 0;
subject to vin4 :x['c1'] = s['c1'] + d['c1'];

