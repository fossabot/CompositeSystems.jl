%% MATPOWER Case Format : Version 2
function mpc = RTS
mpc.version = '2';

%%-----  Power Flow Data  -----%%
%% system MVA base
mpc.baseMVA = 100.0;

%% bus data
%    bus_i    type    Pd    Qd    	Gs    Bs    area    Vm    Va    baseKV    zone    Vmax    Vmin
mpc.bus = [
	1	2	108.0	22.0	0.0		0.0		1	1.03116	-7.74931	138.0	1	1.05	0.95				
	2	2	97.0	20.0	0.0		0.0		1	1.02794	-7.72341	138.0	1	1.05	0.95				
	3	1	180.0	37.0	0.0		0.0		1	1.01395	-9.95875	138.0	1	1.05	0.95				
	4	1	74.0	15.0	0.0		0.0		1	1.00903	-10.81131	138.0	1	1.05	0.95				
	5	1	71.0	14.0	0.0		0.0		1	1.02711	-10.74273	138.0	1	1.05	0.95				
	6	1	136.0	28.0	0.0		-100.0	2	1.0276	-13.28597	138.0	1	1.05	0.95				
	7	2	125.0	25.0	0.0		0.0		2	1.02956	-3.591640	138.0	1	1.05	0.95				
	8	1	171.0	35.0	0.0		0.0		2	1.00427	-9.50027	138.0	1	1.05	0.95				
	9	1	175.0	36.0	0.0		0.0		1	1.02698	-9.271950	138.0	1	1.05	0.95				
	10	1	195.0	40.0	0.0		0.0		2	1.05	-10.62235	138.0	1	1.05	0.95				
	11	1	0.0		0.0		0.0		0.0		3	1.03273	-4.64818	230.0	1	1.05	0.95				
	12	1	0.0		0.0		0.0		0.0		3	1.02695	-3.52232	230.0	1	1.05	0.95				
	13	3	265.0	54.0	0.0		0.0		3	1.05	0.0			230.0	1	1.05	0.95				
	14	2	194.0	39.0	0.0		0.0		3	1.05	-3.71689	230.0	1	1.05	0.95				
	15	2	317.0	64.0	0.0		0.0		4	1.04479	1.17525		230.0	1	1.05	0.95				
	16	2	100.0	20.0	0.0		0.0		4	1.04951	1.27626		230.0	1	1.05	0.95				
	17	1	0.0		0.0		0.0		0.0		4	1.04984	4.77096		230.0	1	1.05	0.95				
	18	2	333.0	68.0	0.0		0.0		4	1.05	5.75937		230.0	1	1.05	0.95				
	19	1	181.0	37.0	0.0		0.0		3	1.04185	0.70319		230.0	1	1.05	0.95				
	20	1	128.0	26.0	0.0		0.0		3	1.04489	2.0619		230.0	1	1.05	0.95				
	21	2	0.0		0.0		0.0		0.0		4	1.05	6.19253		230.0	1	1.05	0.95				
	22	2	0.0		0.0		0.0		0.0		4	1.05	11.871		230.0	1	1.05	0.95				
	23	2	0.0		0.0		0.0		0.0		3	1.05	3.51051		230.0	1	1.05	0.95				
	24	1	0.0		0.0		0.0		0.0		4	1.01424	-2.85872	230.0	1	1.05	0.95				
];

%% generator data
%    bus    Pg    Qg    Qmax    Qmin    Vg    mBase    status    Pmax    Pmin    Pc1    Pc2    Qc1min    Qc1max    Qc2min    Qc2max    ramp_agc    ramp_10    ramp_30    ramp_q    apf
mpc.gen = [
	1	20.0	4.934	10.0	0.0		1.03116	100.0	1	20.0	16.0															
	1	20.0	4.934	10.0	0.0		1.03116	100.0	1	20.0	16.0															
	1	76.0	0.571	30.0	-25.0	1.03116	100.0	1	76.0	15.2															
	1	76.0	0.571	30.0	-25.0	1.03116	100.0	1	76.0	15.2															
	2	20.0	2.222	10.0	0.0		1.02794	100.0	1	20.0	16.0															
	2	20.0	2.222	10.0	0.0		1.02794	100.0	1	20.0	16.0															
	2	76.0	-21.307	30.0	-25.0	1.02794	100.0	1	76.0	15.2															
	2	76.0	-21.307	30.0	-25.0	1.02794	100.0	1	76.0	15.2															
	7	99.974	10.062	60.0	0.0		1.02956	100.0	1	100.0	25.0															
	7	99.974	10.062	60.0	0.0		1.02956	100.0	1	100.0	25.0															
	7	99.974	10.062	60.0	0.0		1.02956	100.0	1	100.0	25.0															
	13	173.258	34.475	80.0	0.0		1.05	100.0	1	197.0	69.0															
	13	173.258	34.475	80.0	0.0		1.05	100.0	1	197.0	69.0															
	13	173.258	34.475	80.0	0.0		1.05	100.0	1	197.0	69.0															
	14	0.0		110.354	200.0	-50.0	1.05	100.0	1	0.0		0.0															
	15	2.4		6.0		6.0		0.0		1.04479	100.0	1	12.0	2.4															
	15	2.4		6.0		6.0		0.0		1.04479	100.0	1	12.0	2.4															
	15	2.4		6.0		6.0		0.0		1.04479	100.0	1	12.0	2.4															
	15	2.4		6.0		6.0		0.0		1.04479	100.0	1	12.0	2.4															
	15	2.4		6.0		6.0		0.0		1.04479	100.0	1	12.0	2.4															
	15	54.3	80.0	80.0	-50.0	1.04479	100.0	1	155.0	54.3														
	16	155.0	80.0	80.0	-50.0	1.04951	100.0	1	155.0	54.3															
	18	400.0	54.665	200.0	-50.0	1.05	100.0	1	400.0	100.0															
	21	296.31	-15.579	200.0	-50.0	1.05	100.0	1	400.0	100.0															
	22	47.938	-6.795	16.0	-10.0	1.05	100.0	1	50.0	10.0															
	22	47.938	-6.795	16.0	-10.0	1.05	100.0	1	50.0	10.0															
	22	47.938	-6.795	16.0	-10.0	1.05	100.0	1	50.0	10.0															
	22	47.938	-6.795	16.0	-10.0	1.05	100.0	1	50.0	10.0															
	22	47.938	-6.795	16.0	-10.0	1.05	100.0	1	50.0	10.0															
	22	47.938	-6.795	16.0	-10.0	1.05	100.0	1	50.0	10.0															
	23	113.399	-9.984	80.0	-50.0	1.05	100.0	1	155.0	54.3															
	23	113.399	-9.984	80.0	-50.0	1.05	100.0	1	155.0	54.3															
	23	248.289	21.208	150.0	-25.0	1.05	100.0	1	350.0	140.0															
];

%% branch data
%    f_bus    t_bus    r    x    b    rateA    rateB    rateC    ratio    angle    status    angmin    angmax
mpc.branch = [
	1	2	0.0026	0.0139	0.4611	175.0	193.0	200.0	0		0	1	-20	20						
	1	3	0.0546	0.2112	0.0572	175.0	208.0	220.0	0		0	1	-20	20								
	1	5	0.0218	0.0845	0.0229	175.0	208.0	220.0	0		0	1	-20	20							
	2	4	0.0328	0.1267	0.0343	175.0	208.0	220.0	0		0	1	-20	20									
	2	6	0.0497	0.192	0.052	175.0	208.0	220.0	0		0	1	-20	20								
	3	9	0.0308	0.119	0.0322	175.0	208.0	220.0	0		0	1	-20	20								
	3	24	0.0023	0.0839	0.0		400.0	510		600.0	1.015	0	1	-20	20								
	4	9	0.0268	0.1037	0.0281	175.0	208.0	220.0	0		0	1	-20	20								
	5	10	0.0228	0.0883	0.0239	175.0	208.0	220.0	0		0	1	-20	20								
	6	10	0.0139	0.0605	2.459	175.0	193.0	200.0	0		0	1	-20	20								
	7	8	0.0159	0.0614	0.0166	175.0	208.0	220.0	0		0	1	-20	20								
	8	9	0.0427	0.1651	0.0447	175.0	208.0	220.0	0		0	1	-20	20								
	8	10	0.0427	0.1651	0.0447	175.0	208.0	220.0	0		0	1	-20	20								
	9	11	0.0023	0.0839	0.0		400.0	510		600.0	1.03	0	1	-20	20								
	9	12	0.0023	0.0839	0.0		400.0	510		600.0	1.03	0	1	-20	20								
	10	11	0.0023	0.0839	0.0		400.0	510		600.0	1.015	0	1	-20	20								
	10	12	0.0023	0.0839	0.0		400.0	510		600.0	1.015	0	1	-20	20							
	11	13	0.0061	0.0476	0.0999	500.0	600.0	625.0	0		0	1	-20	20								
	11	14	0.0054	0.0418	0.0879	500.0	600.0	625.0	0		0	1	-20	20							
	12	13	0.0061	0.0476	0.0999	500.0	600.0	625.0	0		0	1	-20	20					
	12	23	0.0124	0.0966	0.203	500.0	600.0	625.0	0		0	1	-20	20							
	13	23	0.0111	0.0865	0.1818	500.0	600.0	625.0	0		0	1	-20	20						
	14	16	0.005	0.0389	0.0818	500.0	600.0	625.0	0		0	1	-20	20							
	15	16	0.0022	0.0173	0.0364	500.0	600.0	625.0	0		0	1	-20	20							
	15	21	0.0063	0.049	0.103	500.0	600.0	625.0	0		0	1	-20	20							
	15	21	0.0063	0.049	0.103	500.0	600.0	625.0	0		0	1	-20	20							
	15	24	0.0067	0.0519	0.1091	500.0	600.0	625.0	0		0	1	-20	20							
	16	17	0.0033	0.0259	0.0545	500.0	600.0	625.0	0		0	1	-20	20						
	16	19	0.003	0.0231	0.0485	500.0	600.0	625.0	0		0	1	-20	20							
	17	18	0.0018	0.0144	0.0303	500.0	600.0	625.0	0		0	1	-20	20								
	17	22	0.0135	0.1053	0.2212	500.0	600.0	625.0	0		0	1	-20	20							
	18	21	0.0033	0.0259	0.0545	500.0	600.0	625.0	0		0	1	-20	20							
	18	21	0.0033	0.0259	0.0545	500.0	600.0	625.0	0		0	1	-20	20							
	19	20	0.0051	0.0396	0.0833	500.0	600.0	625.0	0		0	1	-20	20							
	19	20	0.0051	0.0396	0.0833	500.0	600.0	625.0	0		0	1	-20	20							
	20	23	0.0028	0.0216	0.0455	500.0	600.0	625.0	0		0	1	-20	20							
	20	23	0.0028	0.0216	0.0455	500.0	600.0	625.0	0		0	1	-20	20							
	21	22	0.0087	0.0678	0.1424	500.0	600.0	625.0	0		0	1	-20	20							
];

%%-----  OPF Data  -----%%
%% cost data
%    1    startup    shutdown    n    x1    y1    ...    xn    yn
%    2    startup    shutdown    n    c(n-1)    ...    c0
mpc.gencost = [
	2	0.0	0.0	2	5.0	100.0
	2	0.0	0.0	2	5.0	100.0
	2	0.0	0.0	2	0.9	100.0
	2	0.0	0.0	2	0.9	100.0
	2	0.0	0.0	2	5.0	100.0
	2	0.0	0.0	2	5.0	100.0
	2	0.0	0.0	2	0.9	100.0
	2	0.0	0.0	2	0.9	100.0
	2	0.0	0.0	2	0.8	100.0
	2	0.0	0.0	2	0.8	100.0
	2	0.0	0.0	2	0.8	100.0
	2	0.0	0.0	2	0.7	100.0
	2	0.0	0.0	2	0.7	100.0
	2	0.0	0.0	2	0.7	100.0
	2	0.0	0.0	2	0.0	0.0
	2	0.0	0.0	2	0.9	100.0
	2	0.0	0.0	2	0.9	100.0
	2	0.0	0.0	2	0.9	100.0
	2	0.0	0.0	2	0.9	100.0
	2	0.0	0.0	2	0.9	100.0
	2	0.0	0.0	2	0.8	100.0
	2	0.0	0.0	2	0.8	100.0
	2	0.0	0.0	2	0.3	100.0
	2	0.0	0.0	2	0.3	100.0
	2	0.0	0.0	2	0.001	0.001
	2	0.0	0.0	2	0.001	0.001
	2	0.0	0.0	2	0.001	0.001
	2	0.0	0.0	2	0.001	0.001
	2	0.0	0.0	2	0.001	0.001
	2	0.0	0.0	2	0.001	0.001
	2	0.0	0.0	2	0.8	100.0
	2	0.0	0.0	2	0.8	100.0
	2	0.0	0.0	2	0.7	100.0
];

%column_names% col_1 col_2 
mpc.areas = {
	1	1
	2	3
	3	8
	4	6
};

