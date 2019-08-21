function [cum_ret, cumprod_ret, daily_ret, daily_portfolio, exp_ret] ...
    = anticor_run_o(fid, data, W, tc, opts)
% This file is the run core for the BAH(Anticor) strategy.
%
% function [cum_ret, cumprod_ret, daily_ret, daily_portfolio, exp_ret] ...
%           = anticor_run(fid, data, W, tc, opts)

% cum_ret: cumulative wealth achived at the end of a period.
% cumprod_ret: cumulative wealth achieved till the end each period.
% daily_ret: daily return achieved by a strategy.
% daily_portfolio: daily portfolio, achieved by the strategy
% exp_ret: experts' returns in the first fold
%
% data: market sequence vectors
% fid: handle for write log file
% W: maximum window size
% tc: transaction fee rate
% opts: option parameter for behvaioral control
%
% Example: [cum_ret, cumprod_ret, daily_ret, daily_portfolio, exp_ret] ...
%          = anticor_run(fid, data, 30, 0, opts);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This file is part of OLPS: http://OLPS.stevenhoi.org/
% Original authors: Bin LI, Steven C.H. Hoi
% Contributors:
% Change log: 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% [T, N]=size(data);
[n, m] = size(data);

% Variables for return, start with uniform weight
% cumprod_ret = 1;
% daily_ret = 1;
% weight = ones(nStocks, 1)/nStocks;

cum_ret = 1;
cumprod_ret = ones(n, 1);
daily_ret = ones(n, 1);
day_weight = ones(m, 1)/m;  %#ok<*NASGU>
day_weight_o = zeros(m, 1);
daily_portfolio = zeros(n, m);

% Variables for expert
exp_ret = ones(W-1, 1);
exp_w = ones(W-1, m)/m;

% print file head
fprintf(fid, '-------------------------------------\n');
if (~opts.quiet_mode)
    fprintf(fid, 'Parameters [W=%d, tc=%f\n]', W, tc);
    fprintf(fid, 'day\t Daily Return\t Total return\n');
end
if (opts.progress)
	progress = waitbar(0,'Executing Algorithm...');
end
for t = 1:1:n
    
    
    
    % -------- adapt params ----------
    % W
    init_W  = [   10.000, ... 1
                  20.000, ... 2
                  30.000, ... 3
                  40.000, ... 4
                  15.000, ... 5
                  25.000, ... 6
                  35.000, ... 7
                  26.000, ... 8
                  27.000, ... 9
                  23.000, ... 10
                  33.000, ... 11
                  18.000, ... 12
                  37.000, ... 13
                  45.000, ... 14
                  36.000, ... 15
                  34.000, ... 16
                  33.000, ... 17
                  32.890, ... 18
                  31.000, ... 19
                  30.000, ... 20
                  21.000, ... 21
                  22.000, ... 22
                  23.000, ... 23
                  24.000, ... 24
                  25.000, ... 25
                  26.000, ... 26
                  27.000, ... 27
                  29.000, ... 28
                  28.000, ... 29
                  30.000 ]; % 30
    burnin    = 31;
    if t == 1
       x      = [];
       y      = [];
    end
    if t == burnin
        model = initBayesOptModelOLPS();           % initialise settings/model
        model = initBayesOptData( x, y, model );   % initialise data
    end
    if t >= burnin
        datas = [ model.xt, exp( - model.yt ) ]
        model = trainBayesOptModel( model );       % train model
        model = doABOChecks(        model );       % do ABOChecks
        x_    = getSampleBayesOpt(  model )        % get sample from model
        W   = round( x_(2) );
    end
    % ---------
    
    
    
    % Calculate t's portfolio
    if (t >= 2)
        [day_weight, exp_w] ...
            = anticor_kernel(data(1:t-1, :), W, exp_ret, exp_w);
    end
    
    % Normalize the constraint
    day_weight = day_weight./sum(day_weight);
    daily_portfolio(t, :) = day_weight';
    
    % Cal t's return and total return
%     (data(t, :)*day_weight)*(1-tc/2*sum(abs(day_weight-day_weight_o)))
    daily_ret(t, 1) = (data(t, :)*day_weight)*(1-tc/2*sum(abs(day_weight-day_weight_o)));
    cum_ret = cum_ret * daily_ret(t, 1);
    cumprod_ret(t, 1) = cum_ret;
    
    % Normalize the portfolio
    day_weight_o = day_weight.*data(t, :)'/daily_ret(t, 1);
    
    % Cal t's experts return
    for k=2:W
        exp_ret(k-1, 1) = exp_ret(k-1, 1)*data(t, :)*exp_w(k-1, :)';
    end;
    exp_ret(:, 1) = exp_ret(:, 1)/sum(exp_ret(:, 1));
    
    
    
    % -------- Update BO Model ----------
    xx        =   [ t, W ];
    yy        = - log( daily_ret( t, 1 ) );
    if t  < burnin
        xx    = [ t, init_W(t) ];
        x     = [ x ; xx ];
        y     = [ y ; yy ];
    end
    if t >= burnin
        model = updateBayesOptData( xx, yy, model ); % update model data
    end
    % ------------------------------------
    
    
    
    % Debug information
    fprintf(fid, '%d\t%f\t%f\n', t, daily_ret(t, 1), cum_ret);
    if (~opts.quiet_mode)
        if (~mod(t, opts.display_interval))
            fprintf(1, '%d\t%f\t%f\n', t, daily_ret(t, 1), cum_ret);
        end
    end
    if (opts.progress)
		if mod(t, 50) == 0 
			waitbar((t/n));
		end
	end
end

% Debug Information
fprintf(fid, 'Anticor(W:%d, tc:%.4f), Final return: %.2f\n', ...
    W, tc, cum_ret);
fprintf(fid, '-------------------------------------\n');

fprintf(1, 'Anticor(W:%d, tc:%.4f), Final return: %.2f\n', ...
    W, tc, cum_ret);
fprintf(fid, '-------------------------------------\n');
if (opts.progress)	
    close(progress);
end
end