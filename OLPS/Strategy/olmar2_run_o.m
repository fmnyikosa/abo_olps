function [cum_ret, cumprod_ret, daily_ret, daily_portfolio]...
    = olmar2_run_o(fid, data, epsilon, alpha, tc, opts)
% This program simulates the OLMAR-2 algorithm
%
% function [cum_ret, cumprod_ret, daily_ret, daily_portfolio] ...
%    = olmar2_run(fid, data, epsilon, alpha, tc, opts)
%
% cum_ret: a number representing the final cumulative wealth.
% cumprod_ret: cumulative return until each trading period
% daily_ret: individual returns for each trading period
% daily_portfolio: individual portfolio for each trading period
%
% data: market sequence vectors
% fid: handle for write log file
% epsilon: mean reversion threshold
% alpha: trade off parameter for calculating moving average [0, 1]
% tc: transaction cost rate parameter
% opts: option parameter for behvaioral control
%
% Example: [cum_ret, cumprod_ret, daily_ret, daily_portfolio, exp_ret] ...
%           = olmar2_run(fid, data, epsilon, alpha, tc, opts)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This file is part of OLPS: http://OLPS.stevenhoi.org/
% Original authors: Bin LI, Steven C.H. Hoi
% Contributors:
% Change log: 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[n, m] = size(data);

% Return variables
cum_ret = 1;
cumprod_ret = ones(n, 1);
daily_ret = ones(n, 1);

% Portfolio weights, starting with uniform portfolio
day_weight = ones(m, 1)/m;  %#ok<*NASGU>
day_weight_o = zeros(m, 1);  % Last closing price adjusted portfolio
daily_portfolio = zeros(n, m);

% print file head
fprintf(fid, '-------------------------------------\n');
fprintf(fid, 'Parameters [epsilon:%.2f, alpha:%.2f, tc:%.4f]\n', ...
    epsilon, alpha, tc);
fprintf(fid, 'day\t Daily Return\t Total return\n');

fprintf(1, '-------------------------------------\n');
if(~opts.quiet_mode)
    fprintf(1, 'Parameters [epsilon:%.2f, alpha:%.2f, tc:%.4f]\n', ...
        epsilon, alpha, tc);
    fprintf(1, 'day\t Daily Return\t Total return\n');
end

data_phi = ones(1, m);

% Trading
if (opts.progress)
	progress = waitbar(0,'Executing Algorithm...');
end
for t = 1:1:n
    
    
    % -------- adapt params ----------
    % epsilon range = [10,15], alpha range = [0.15,0.85]
    
%     num_points   = 50;
%     dim          = 1;
%     lower_b      = 10;
%     upper_b      = 15;
%     initData_eps = getInitialInputFunctionData(num_points, dim, lower_b, upper_b);
    
    num_points   = 3;
    dim          = 1;
    lower_b      = 0.0;
    upper_b      = 1.0;
    initData_al  = getInitialInputFunctionData(num_points, dim, lower_b, upper_b);
    
%     init_params  = [ initData_eps,  initData_al ];
    init_params  = initData_al;
    
    burnin    = 4;
    if t == 1
       x      = [];
       y      = [];
    end
    if t == burnin
        model = initBayesOptModelOLPS_olmar();           % initialise settings/model
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
        
        %epsilon = x_( 2 );
        alpha    = x_( 2 );
    end
    
    % ------------------------------------
    
    
    % Step 1: Receive stock price relatives
    if (t >= 2)
        [day_weight, data_phi] ...
            = olmar2_kernel(data(1:t-1, :), data_phi, day_weight, epsilon, alpha);
    end
    
    % Normalize the constraint, always useless
    day_weight = day_weight./sum(day_weight);
    daily_portfolio(t, :) = day_weight';
    
    if or((day_weight < -0.00001+zeros(size(day_weight))), (day_weight'*ones(m, 1)>1.00001))
        fprintf(1, 'mrpa_expert: t=%d, sum(day_weight)=%d, pause', t, day_weight'*ones(m, 1));
        pause;
    end

    % Step 2: Cal t's daily return and total return
    daily_ret(t, 1) = (data(t, :)*day_weight)*(1-tc/2*sum(abs(day_weight-day_weight_o)));
    cum_ret = cum_ret * daily_ret(t, 1);
    cumprod_ret(t, 1) = cum_ret;
    
    % fprintf(1, '%d\t%.2f\t%.2f\t%.2f\n', t, day_weight(1), day_weight(2), daily_ret(t, 1));
    % Adjust weight(t, :) for the transaction cost issue
    day_weight_o = day_weight.*data(t, :)'/daily_ret(t, 1);
    
    
    % -------- Update BO model with new params ----------
    %  epsilon, alpha
    
    xx        =   [ t, alpha ]; % epsilon, 
    yy        = - log( daily_ret( t, 1 ) );
    if t  < burnin
        xx    = [ t,  init_params( t , : ) ];
        x     = [ x ; xx ];
        y     = [ y ; yy ];
    end
    if t >= burnin
        model = updateBayesOptData( xx, yy, model ); % update model data
    end
    
    % ------------------------------------
    
    
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
mat_dt_       = datestr(now, 'yyyy-mmdd-HH-MM');
strategy_name = 'olmar-o';
mat_name_     = ['OLPS/Log/' strategy_name '-' mat_dt_ '.mat'];
save(         mat_name_, 'model');
hyp_end       = exp(model.training_hyp.cov)

% Debug Information
fprintf(fid, 'OLMAR-2(epsilon:%.2f, alpha:%.2f, tc:%.4f), Final return: %.2f\n', ...
    epsilon, alpha, tc, cum_ret);
fprintf(fid, '-------------------------------------\n');
fprintf(1, 'OLMAR-2(epsilon:%.2f, alpha:%.2f, tc:%.4f), Final return: %.2f\n', ...
    epsilon, alpha, tc, cum_ret);
fprintf(1, '-------------------------------------\n');
    if (opts.progress)	
        close(progress);
    end
end