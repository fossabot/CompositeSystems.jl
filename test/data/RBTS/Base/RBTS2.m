%% MATPOWER Case Format : Version 2
function mpc = RBTS
mpc.version = '2';

%%-----  Power Flow Data  -----%%
%% system MVA base
mpc.baseMVA = 100;
%% bus data
%    bus_i	type    Pd    Qd    Gs    Bs    area    Vm    Va    baseKV    zone    Vmax    Vmin
mpc.bus = [
	1	3	0.0		0.0		0.0	0.0	1	1.05	0.0	230.0	1	1.05	0.97;		
	2	2	20.0	4.0		0.0	0.0	1	1.05	0.0	230.0	2	1.05	0.97;		
	3	1	85.0	17.0	0.0	0.0	1	1.0		0.0	230.0	3	1.05	0.97;		
	4	1	40.0	8.0		0.0	0.0	1	1.0		0.0	230.0	4	1.05	0.97;		
	5	1	20.0	4.0		0.0	0.0	1	1.0		0.0	230.0	5	1.05	0.97;		
	6	1	20.0	4.0		0.0	0.0	1	1.0		0.0	230.0	6	1.05	0.97;	
];

%% generator data
%    bus    Pg    Qg    Qmax    Qmin    Vg    mBase    status    Pmax    Pmin    Pc1    Pc2    Qc1min    Qc1max    Qc2min    Qc2max    ramp_agc    ramp_10    ramp_30    ramp_q    apf
mpc.gen = [
	1	40.0	0.0	17.0	-15.0	1.05	100.0	1	40.0	0.0;														
	1	40.0	0.0	17.0	-15.0	1.05	100.0	1	40.0	0.0;															
	1	10.0	0.0	7.0		0.0		1.05	100.0	1	10.0	0.0;														
	1	10.0	0.0	12.0	-7.0	1.05	100.0	1	20.0	0.0;															
	2	5.0		0.0	5.0		0.0		1.05	100.0	1	5.0		0.0;															
	2	5.0		0.0	5.0		0.0		1.05	100.0	1	5.0		0.0;															
	2	30.0	0.0	17.0	-15.0	1.05	100.0	1	40.0	0.0;															
	2	20.0	0.0	12.0	-7.0	1.05	100.0	1	20.0	0.0;															
	2	20.0	0.0	12.0	-7.0	1.05	100.0	1	20.0	0.0;															
	2	20.0	0.0	12.0	-7.0	1.05	100.0	1	20.0	0.0;															
	2	20.0	0.0	12.0	-7.0	1.05	100.0	1	20.0	0.0;															
];

%% branch data
%    f_bus    t_bus    r    x    b    rateA    rateB    rateC    ratio    angle    status    angmin    angmax
mpc.branch = [
	1	3	0.0342	0.18	0.0212	85.00	98.18	102.64	0	0	1	-20	20;								
	2	4	0.114	0.6		0.0704	71.00	82.0	85.73	0	0	1	-20	20;								
	2	1	0.0912	0.48	0.0564	71.00	82.0	85.73	0	0	1	-20	20;							
	3	4	0.0228	0.12	0.0142	71.00	82.0	85.73	0	0	1	-20	20;								
	3	5	0.0228	0.12	0.0142	71.00	82.0	85.73	0	0	1	-20	20;								
	1	3	0.0342	0.18	0.0212	85.00	98.18	102.64	0	0	1	-20	20;								
	2	4	0.114	0.6		0.0704	71.00	82.0	85.73	0	0	1	-20	20;								
	4	5	0.0228	0.12	0.0142	71.00	82.0	85.73	0	0	1	-20	20;								
	5	6	0.0228	0.12	0.0142	71.00	82.0	85.73	0	0	1	-20	20;								
];

% adds current ratings to branch matrix
%column_names%	c_rating_a
mpc.branch_currents = [
	85.00;
	71.00;
	71.00;
	71.00;
	71.00;
	85.00;
	71.00;
	71.00;
	71.00;
];

%%-----  OPF Data  -----%%
%% cost data
%    1    startup    shutdown    n    x1    y1    ...    xn    yn
%    2    startup    shutdown    n    c(n-1)    ...    c0
mpc.gencost = [
	2	0.0	0.0	2	12.0	93.7797;
	2	0.0	0.0	2	12.0	93.7797;
	2	0.0	0.0	2	12.5	71.2251;
	2	0.0	0.0	2	12.25	80.7217;
	2	0.0	0.0	2	0.5		1.4839;
	2	0.0	0.0	2	0.5		1.4839;
	2	0.0	0.0	2	0.5		11.8708;
	2	0.0	0.0	2	0.5		5.9354;
	2	0.0	0.0	2	0.5		5.9354;
	2	0.0	0.0	2	0.5		5.9354;
	2	0.0	0.0	2	0.5		5.9354;
];
