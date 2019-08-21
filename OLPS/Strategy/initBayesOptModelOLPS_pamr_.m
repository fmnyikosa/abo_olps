% This function initilaizes a Bayesian optimization model for
% Online Portfilio Selection
%
% (c) Copyright Favour M Nyikosa <favour@nyikosa.com> March 3rd 2018

function model = initBayesOptModelOLPS_pamr_()

% We assume that data is 2D - {time, param}

% Pre-data configurations

settings                    = getDefaultGPMetadataGPML();
settings.hyp_opt_mode       = 0;

% GP model

%cov                         = {'covSum',{{'covSum',{{'covMaternard', 1},'covSEard'}},'covRQard'}};
%cov                         = {'covSum',{{'covMaternard', 1},'covSEard'}};
cov                          = {'covMaternard', 1};
%cov                          = {'covSum',{{'covMaternard', 5},'covSEard'}};
%cov                         = {'covSEard'};

gpModel                     = {{'infGaussLik'},[],cov,{'likGauss'}};                              
hyperparameters.mean        = [];
l1                          = 5;
l2                          = 0.1;
sf1                         = 1;
sf2                         = 1.01;
alpha                       = 0.2;
hyp_t                       = [ l1; l2; sf1 ]; % ; l1; l2; sf2
hyp_s                       = [ l1; l2; sf2; alpha];
hyperparameters.cov         = log( hyp_t );   
sn                          = 0.05;
hyperparameters.lik         = log(sn);
settings.gpModel            = gpModel;
settings.hyp                = hyperparameters;

% Data settings

settings.x0                 = [ 0 , 0.5 ];

settings.hyp_opt_mode_nres  = 10;
settings.hyp_bounds_set     = 1;
% settings.hyp_lb             = log([ 00.010, 0.001, 00.01, 0.001,  00.010, 0.001, 0.001, 0.00001 ]);
% settings.hyp_ub             = log([ 10.000, 3.000, 10.00, 3.000,  10.000, 3.000, 2.000, 0.20000 ]);

%                                   l1    l2    sf1   l1     l2    sf2    sn
settings.hyp_lb            = log([ 0001.1, 0.2, 1.00 ]); %  000.1, 0.45, 1.00, 
settings.hyp_ub            = log([ 1200.0, 0.8, 1.00 ]); %  100.0, 0.55, 1.00, 


% ABO settings

max_t_train                 = 1;
max_t_test                  = 50000;

settings.abo                = 1;
settings.current_time_abo   = 1;

settings.initial_time_tag   = 10;
settings.time_delta         = 1;
settings.final_time_tag     = max_t_test;

% settings                    = getDefaultBOSettingsLCB( settings.x0, 50000, settings );
settings                    = getDefaultBOSettingsEL(settings.x0, 50000, settings);
%settings                   = getDefaultBOSettingsMinMean(x0, iters, settings);

% Post data settings

settings.optimiseForTime    = 0;
settings.burnInIterations   = 5;

settings.acq_opt_mode       = 9;
settings.acq_opt_mode_nres  = 5;

settings.tolX               = eps;
settings.tolObjFunc         = eps;

lb_                         = [ 0,      0.2 ];
ub_                         = [ 50000,  0.8 ];

lb                          = lb_;
ub                          = ub_;

settings.acq_bounds_set     = 1;
settings.acq_lb             = lb;
settings.acq_ub             = ub;
settings.acq_lb_            = lb_;
settings.acq_ub_            = ub_;
% settings.true_func        = @(x) stybtang_func_bulk(x);
% settings.true_func_bulk   = @(x) stybtang_func_bulk(x);
settings.closePointsMax     = 0;

settings.animateBO          = 0;
settings.animatePerformance = 0;
settings.finalStepMinfunc   = 0;   % perform minfunc after using a global method
settings.mcmc               = 0;
settings.standardized       = 0;
settings.abo                = 1;

settings.nit                = -100;
settings.streamlined        = 0;
settings.num_grid_points    = 1500;

settings.flex_acq           = 0; % flexible acquisition

%settings.streamlined       = 0;
h_                          = load('1_hyp.mat');
settings.streamlined_hyp    = h_.hyperparameters;
%settings.true_opts_flag    = 1;

settings.windowing          = 1;
settings.window             = 50;
settings.resetting          = 0;

settings.alg                = 'OLPS-ABO';

settings.time_stability_flag = 0; % a variable for checking if algol has stabilised
settings.time_stability_peg  = 0; % peg for keeping track of number of times we see stability
settings.time_stability_key  = 1; % number of times to see phenomenon before setting flag
settings.time_gradient       = 0.1;

settings.timeLengthscales    = [];


% Iterator updates
settings.iterations          = 1;

model                        = settings;

end