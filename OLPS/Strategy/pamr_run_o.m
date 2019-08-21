function [cum_ret, cumprod_ret, daily_ret, daily_portfolio] ...
    = pamr_run_o(fid, data, epsilon, tc, opts)
% This program simulates the PAMR algorithm
%
% function [cum_ret, cumprod_ret, daily_ret, daily_portfolio, exp_ret] ...
%    = pamr_run(fid, data, epsilon, tc, opts)
%
% cum_ret: a number representing the final cumulative wealth.
% cumprod_ret: cumulative return until each trading period
% daily_ret: individual returns for each trading period
% daily_portfolio: individual portfolio for each trading period
%
% data: market sequence vectors
% fid: handle for write log file
% epsilon: mean reversion threshold
% tc: transaction cost rate parameter
% opts: option parameter for behvaioral control
%
% Example: [cum_ret, cumprod_ret, daily_ret, daily_portfolio, exp_ret] ...
%            = pamr_run(fid, data, epsilon, tc, opts)

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
fprintf(fid, 'Parameters [epsilon:%.2f, tc:%.4f]\n', epsilon, tc);
fprintf(fid, 'day\t Daily Return\t Total return\n');

fprintf(1, '-------------------------------------\n');
if(~opts.quiet_mode)
    fprintf(1, 'Parameters [epsilon:%.2f, tc:%.4f]\n', epsilon, tc);
    fprintf(1, 'day\t Daily Return\t Total return\n');
end
if (opts.progress)
	progress = waitbar(0,'Executing Algorithm...');
end
for t = 1:1:n
    
    
    
    % -------- adapt params ----------
    % epsilon
    
    num_points   = 10;
    dim          = 1;
    lower_b      = 0.2;
    upper_b      = 0.8;
    initData     = getInitialInputFunctionData(num_points, dim, lower_b, upper_b)';
    init_epsilon = [  0.10000, ... 1
                      0.20000, ... 2
                      0.30100, ... 3
                      0.40010, ... 4
                      0.50000, ... 5
                      0.65000, ... 6
                      0.70500, ... 7
                      0.80050, ... 8
                      0.92345, ... 9
                      0.23450, ... 10
                      0.33450, ... 11
                      0.78000, ... 12
                      0.56780, ... 13
                      0.45612, ... 14
                      0.66750, ... 15
                      0.87653, ... 16
                      0.91020, ... 17
                      0.51890, ... 18
                      0.26730, ... 19
                      0.37850, ... 20
                      0.44560, ... 21
                      0.50640, ... 22
                      0.78060, ... 23
                      0.8920,  ... 24
                      0.54500, ... 25
                      0.52220, ... 26
                      0.58930, ... 27
                      0.55345, ... 28
                      0.51345, ... 29
                      0.79679, ... 30 
                      initData]; % 30 + 20
    
    init_epsilon  = initData;
    burnin    = 11;
    if t == 1
       x      = [];
       y      = [];
    end
    if t == burnin
        model = initBayesOptModelOLPS_pamr();           % initialise settings/model
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
        
        x_    = getSampleBayesOpt(  model );        % get sample from model
        
        epsilon = x_( 2 );
    end
    % ------------------------------------
    
    
    
    % Calculate t's portfolio at the beginning of t-th trading day
    if (t >= 2)
        [day_weight] = pamr_kernel(data(1:t-1, :), day_weight, eta);
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
    
    % Calculate the Lagarange Multiplier
    denominator = (data(t, :)-1/m*sum(data(t, :)))*(data(t, :)-1/m*sum(data(t, :)))';
    if (~eq(denominator, 0.0))
        eta = (daily_ret(t, 1) - epsilon)/denominator;
    end
    eta = max(0, eta);
    
    
    
    % -------- Update BO Model ----------
    % epsilon
    
    xx        =   [ t , epsilon ];
    yy        = - log( daily_ret( t, 1 ) );
    if t  < burnin
        xx    = [ t, init_epsilon(t) ];
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
strategy_name = 'pamr-o';
mat_name_     = ['OLPS/Log/' strategy_name '-' mat_dt_ '.mat'];
save(         mat_name_, 'model');
hyp_end       = exp(model.training_hyp.cov)

% Debug Information
fprintf(fid, 'PAMR(%.2f, %.4f), Final return: %.2f\n', epsilon, tc, cum_ret);
fprintf(fid, '-------------------------------------\n');
fprintf(1, 'PAMR(%.2f, %.4f), Final return: %.2f\n', epsilon, tc, cum_ret);
fprintf(1, '-------------------------------------\n');
	if (opts.progress)	
		close(progress);
	end
end