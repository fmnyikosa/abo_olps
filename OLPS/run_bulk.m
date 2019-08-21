% Run all experiments at batch
%
% Algorithms: Market, BS, BCRP, EG, ONS, AntiCor, PAMR, CWMR, OLMAR
% Datsets:    DJIA, SP500, TSE, MSCI, NYSE(N), NYSE(O) 
%
% Copyright (c) Favour M Nyikosa March 2nd 2018 <favour@nyikosa.com>

clc
close all

% DJIA
OLPS_cli('djia')

% SP500
OLPS_cli('sp500')

% TSE
OLPS_cli('tse')

% MSCI
OLPS_cli('msci')

% NYSE (N)
OLPS_cli('nyse-n')

% NYSE (O)
OLPS_cli('nyse-o')