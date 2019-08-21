function [cum_ret, cumprod_ret, daily_ret, daily_portfolio] ...
    = eg_run_o(fid, data, eta, tc, opts)
% This file is the run core for the EG strategy.
%
% function [cum_ret, cumprod_ret, daily_ret, daily_portfolio] ...
%           = eg_run(fid, data, tc, opts)
%
% cum_ret: cumulative wealth achived at the end of a period.
% cumprod_ret: cumulative wealth achieved till the end each period.
% daily_ret: daily return achieved by a strategy.
% daily_portfolio: daily portfolio, achieved by the strategy
%
% data: market sequence vectors
% fid: handle for write log file
% eta: learning rate, key parameter
% tc: transaction fee rate
% opts: option parameter for behvaioral control
%
% Example: [cum_ret, cumprod_ret, daily_ret, daily_portfolio] ...
%          = eg_run(fid, data, 0.05, 0, opts);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This file is part of OLPS: http://OLPS.stevenhoi.org/
% Original authors: Bin LI, Steven C.H. Hoi
% Contributors:
% Change log: 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[n, m] = size(data);

% Variables for return, start with uniform weight
cum_ret = 1;
cumprod_ret = ones(n, 1);
daily_ret = ones(n, 1);
day_weight = ones(m, 1)/m;  %#ok<*NASGU>
day_weight_o = zeros(m, 1);
daily_portfolio = zeros(n, m);

% print file head
fprintf(fid, '-------------------------------------\n');
fprintf(fid, 'Parameters [eta:%f, tc:%f]\n', eta, tc);
fprintf(fid, 'day\t Daily Return\t Total return\n');

fprintf(1, '-------------------------------------\n');
if(~opts.quiet_mode)
    fprintf(1, 'Parameters [eta:%f, tc:%f]\n', eta, tc);
    fprintf(1, 'day\t Daily Return\t Total return\n');
end
if (opts.progress)
	progress = waitbar(0,'Executing Algorithm...');
end
for t = 1:1:n
    
    
    % --------  adapt params ----------
    % eta
    
    num_points   = 10;
    dim          = 1;
    lower_b      = 0.0005;
    upper_b      = 0.5000;
    initData     = getInitialInputFunctionData(num_points, dim, lower_b, upper_b)';
    init_eta  = [ 0.10000, ... 1
                  0.01000, ... 2
                  0.00100, ... 3
                  0.00010, ... 4
                  0.50000, ... 5
                  0.05000, ... 6
                  0.00500, ... 7
                  0.00050, ... 8
                  0.12345, ... 9
                  0.23450, ... 10
                  0.33450, ... 11
                  0.78000, ... 12
                  0.56780, ... 13
                  0.45612, ... 14
                  0.66750, ... 15
                  0.87653, ... 16
                  0.01020, ... 17
                  0.05890, ... 18
                  0.06730, ... 19
                  0.07850, ... 20
                  0.04560, ... 21
                  0.05640, ... 22
                  0.07860, ... 23
                  0.08920, ... 24
                  0.04500, ... 25
                  0.02220, ... 26
                  0.08930, ... 27
                  0.05345, ... 28
                  0.01345, ... 29
                  0.99679, ... 30
                  initData ]; % 50
              
    init_eta  = initData;          
    burnin    = 11;
    if t == 1
       x      = [];
       y      = [];
    end
    if t == burnin
        model = initBayesOptModelOLPS_eg();        % initialise settings/model
        model = initBayesOptData( x, y, model );   % initialise data
    end
    if t >= burnin
        
        model         = trainBayesOptModel( model );       % train model
        model         = doABOChecks(        model );       % do ABOChecks
        
        datas         = [ model.xt, exp( - model.yt ) ]
        datas_full    = [ model.x, exp( - model.y ) ]
        t
        num_data      = size(model.xt, 1)
        num_data_full = size(model.x, 1)
        
        x_            = getSampleBayesOpt(  model );        % get sample from model
        
        eta           = x_( 2 );
    end
    % ----------------------------------
    
    
    % Calculate t's portfolio at the beginning of t-th trading day
    if (t >= 2)
        [day_weight] = eg_kernel(data(1:t-1, :), day_weight, eta);
    end
    
    % Normalize the constraint, always useless
    day_weight = day_weight./sum(day_weight);
    daily_portfolio(t, :) = day_weight';
    
    % Cal t's return and total return
    daily_ret(t, 1) = (data(t, :)*day_weight)*(1-tc/2*sum(abs(day_weight-day_weight_o)));
    cum_ret = cum_ret * daily_ret(t, 1);
    cumprod_ret(t, 1) = cum_ret;
    
    % Adjust weight(t, :) for the transaction cost issue
    day_weight_o = day_weight.*data(t, :)'/daily_ret(t, 1);
    
    
    % -------- update BO model data --------
    xx        =   [ t , eta ];
    yy        = - log( daily_ret( t, 1 ) );
    if t  < burnin
        xx    = [ t, init_eta(t) ];
        x     = [ x ; xx ];
        y     = [ y ; yy ];
    end
    if t >= burnin
        model = updateBayesOptData( xx, yy, model ); % update model data
    end
    % ----------------------------------
    
    % Debug information
    % Time consuming part, other way?
    
    fprintf(fid, '%d\t%f\t%f\n', t, daily_ret(t, 1), cumprod_ret(t, 1));
    if (~opts.quiet_mode)
        if (~mod(t, opts.display_interval))
            fprintf(1, '%d\t%f\t%f\n', t, daily_ret(t, 1), cumprod_ret(t, 1));
        end
    end
    if (opts.progress)
		if mod(t, 50) == 0 
			waitbar((t/n));
		end
	end
end

% save model
%save('0-model-eg.mat', 'model');
mat_dt_       = datestr(now, 'yyyy-mmdd-HH-MM');
strategy_name = 'eg-o';
mat_name_     = ['OLPS/Log/' strategy_name '-' mat_dt_ '.mat'];
save(         mat_name_, 'model');
hyp_end       = exp(model.training_hyp.cov)

% Debug Information
fprintf(fid, 'EG(eta:%.2f, tc:%.4f) Final return: %.2f\n', eta, tc, cum_ret);
fprintf(fid, '-------------------------------------\n');
fprintf(1, 'EG(eta:%.2f, tc:%.4f) Final return: %.2f\n', eta, tc, cum_ret);
fprintf(1, '-------------------------------------\n');
	if (opts.progress)	
		close(progress);
	end
end