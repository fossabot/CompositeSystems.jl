%
% Test for component status pre-processing
%

function mpc = case7_tplgy
mpc.version = '2';
mpc.baseMVA = 100.0;
mpc.start_timestamp = 2022;
mpc.timezone = 'UTC';
mpc.timestep_count = 8736;
mpc.timestep_length = 1;
mpc.timestep_unit = 'h';

%% bus data
%	bus_i	type	Pd	Qd	Gs	Bs	area	Vm	Va	baseKV	zone	Vmax	Vmin
mpc.bus = [
	1	 3	 0.0	  0.0	 0.0	 0.0	 1	    1.00000	   0.00000	 240.0	 1	    1.10000	    0.90000;
	2	 2	 100.0	 50.0	 1.0	 5.0	 1	    1.00000	   0.00000	 240.0	 1	    1.10000	    0.90000;
	3	 1	 0.0	  0.0	 0.0	 0.0	 1	    1.00000	   0.00000	 240.0	 1	    1.10000	    0.90000;
	4	 1	 100.0	 50.0	 0.0	 0.0	 1	    1.00000	   0.00000	 240.0	 1	    1.10000	    0.90000;
	5	 2	  0.0	  0.0	 1.0	 5.0	 1	    1.00000	   0.00000	 240.0	 1	    1.10000	    0.90000;
	6	 4	 100.0	 50.0	 1.0	 5.0	 1	    1.00000	   0.00000	 240.0	 1	    1.10000	    0.90000;
	7	 1	 50.0	 10.0	 1.0	 5.0	 1	    1.00000	   0.00000	 240.0	 1	    1.10000	    0.90000;
];

%% generator data
%	bus	Pg	Qg	Qmax	Qmin	Vg	mBase	status	Pmax	Pmin
mpc.gen = [
	1	 0.000	 0.000	 1000.0	 -1000.0	 1.00000	 100.0	 1	 200.0	 0.0;
	2	 0.000	 0.000	 1000.0	 -1000.0	 1.00000	 100.0	 1	 140.0	 0.0;
	5	 0.000	 0.000	 100.0	  -100.0	 1.00000	 100.0	 1	 330.0	 0.0;
];

%% generator cost data
%	2	startup	shutdown	n	c(n-1)	...	c0
mpc.gencost = [
	2	 0.0	 0.0	 3	   0.000000	   1.000000	   0.000000;
	2	 0.0	 0.0	 3	   0.000000	   1.000000	   0.000000;
	2	 0.0	 0.0	 3	   0.000000	  10.000000	   0.000000;
];

%% branch data
%	fbus	tbus	r	x	b	rateA	rateB	rateC	ratio	angle	status	angmin	angmax
mpc.branch = [
	1	 3	 0.065	 0.62	 0.00	 30.0	 0.0	 0.0	 0.0	 0.0	 0	 -30.0	 30.0;
	1	 4	 0.012	 0.53	 0.00	 60.0	 0.0	 0.0	 0.0	 0.0	 0	 -30.0	 30.0;
	1	 5	 0.042	 0.90	 0.00	 60.0	 0.0	 0.0	 0.0	 0.0	 0	 -30.0	 30.0;
	2	 3	 0.075	 0.51	 0.00	 45.0	 0.0	 0.0	 0.0	 0.0	 0	 -30.0	 30.0;
	3	 5	 0.025	 0.75	 0.25	 30.0	 0.0	 0.0	 0.0	 0.0	 1	 -30.0	 30.0;
	3	 6	 0.025	 0.75	 0.25	 30.0	 0.0	 0.0	 0.0	 0.0	 1	 -30.0	 30.0;
	5	 6	 0.025	 0.75	 0.25	 30.0	 0.0	 0.0	 0.0	 0.0	 1	 -30.0	 30.0;
	4	 5	 0.025	 0.07	 0.05	300.0	 0.0	 0.0	 0.0	 0.0	 1	 -30.0	 30.0;
];

%% dcline data
%	fbus	tbus	status	Pf	Pt	Qf	Qt	Vf	Vt	Pmin	Pmax	QminF	QmaxF	QminT	QmaxT	loss0	loss1
mpc.dcline = [
	1	2	0	10	9.0	99.0	-10.0	1.0000	1.0000	   10	100	-100	100	-100 100	10.00	0.00;
	5	6	1	10	9.0	99.0	-10.0	1.0000	1.0000	    0	200	-100	100	-100 100	10.00	0.00;
	7	4	1	10	9.0	99.0	-10.0	1.0000	1.0000	 -200	  0	-100	100	-100 100	10.00	0.00;
];

%% storage data
%   storage_bus ps qs energy  energy_rating charge_rating  discharge_rating  charge_efficiency  discharge_efficiency  thermal_rating  qmin  qmax  r  x  p_loss  q_loss  status
mpc.storage = [
	 6	 0.0	 0.0	 20.0	 100.0	 50.0	 70.0	 0.8	 0.9	 100.0	 -50.0	 70.0	 0.1	 0.0	 0.0	 0.0	 1;
];

%% switch data
%	f_bus	t_bus	psw	qsw	state	thermal_rating	status
mpc.switch = [
	1	 6	 0.0	 0.00	 1	 1000.0	 0;
];
