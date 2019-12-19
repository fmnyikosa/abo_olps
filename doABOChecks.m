% This function gets a proposal from the BayesOpt model
%
% Copyright (c) Favour Mandanji Nyikosa <favour@nyikosa.com> 3-MAR-2018


function model = doABOChecks( model )

    i                            = model.iterations;

    if model.abo == 1

        init_t                   = model.initial_time_tag;
        delta_t                  = model.time_delta;
        cov_hyperparams_         = model.training_hyp.cov;
        time_lengthscale         = exp( cov_hyperparams_(1) );

        model.timeLengthscales   = [model.timeLengthscales, time_lengthscale];

        % ------- To enforce seeing a short time into the future -------

        if i > 1
            if model.optimiseForTime == 1 && model.time_stability_flag == 1
                current_t              = xopt(1);
                model.current_time_abo = current_t;
            else
                if ~isfield(model, 'mpb')
                    current_t              = init_t + (i-1)*delta_t;
                    model.current_time_abo = current_t;
                elseif model.mpb == 1
                    current_t              = model.p.time + delta_t;
                    model.current_time_abo = current_t;
                end
            end

            %--------- Deal with time lengthscale stability --------
            % 1. Get gradients
            time_lengthscale_gradient = 1000;
            if (i > model.burnInIterations)
                  ... && (time_stability_flag == 0)
                delta                     = model.burnInIterations - 1;
                tl_                       = model.timeLengthscales;
                top                       = tl_(i) - tl_( i - delta );
                bottom                    = delta;
                time_lengthscale_gradient = top ./ bottom;
            end

            % 2. Set stability flag
            if (time_lengthscale_gradient) < model.time_gradient  ...
                    && ( time_lengthscale_gradient > -model.time_gradient )
                if model.time_stability_peg > model.time_stability_key
                    model.time_stability_flag = 1;
                else
                    model.time_stability_peg  = model.time_stability_peg + 1;
                end
            end

            % 3. Change acquisition function to  minimum mean
            if (model.flex_acq == 1) && model.time_stability_flag == 1
                model.acquisitionFunc = 'MinMean';
            end

        else
            current_t              = init_t + (i-1)*delta_t;
            model.current_time_abo = current_t;
        end

        if model.optimiseForTime == 0

            % Adjust time constraints
            temp_lb      = model.acq_lb;
            temp_ub      = model.acq_ub;

            temp_lb(1)   = current_t;
            temp_ub(1)   = current_t;

            mid_point    = ( temp_lb + temp_ub )./ 2;
            x0           = mid_point;

            if ~isfield(model, 'sbo')

                model.acq_lb = temp_lb;
                model.acq_ub = temp_ub;
                model.x0     = x0;

            elseif ~(model.sbo == 1)

                model.acq_lb = temp_lb;
                model.acq_ub = temp_ub;
                model.x0     = x0;

            end

        else

            if (model.time_stability_flag == 1)
                % Adjust time constraints
                temp_lb      = model.acq_lb;
                temp_ub      = model.acq_ub;

                temp_lb(1)   = current_t;
                temp_ub(1)   = current_t + ( time_lengthscale ./ 3 );

                mid_point    = (temp_lb(:,2:end) + temp_ub(:,2:end))./2;
                x0           = [current_t, mid_point];

                model.acq_lb = temp_lb;
                model.acq_ub = temp_ub;
                model.x0     = x0;
            else
                % Use fixed timesteps
                temp_lb      = model.acq_lb;
                temp_ub      = model.acq_ub;

                temp_lb(1)   = current_t;
                temp_ub(1)   = current_t;

                mid_point    = ( temp_lb(:,2:end) + temp_ub(:,2:end) ) ./ 2;
                x0           = [ current_t, mid_point];


                model.acq_lb = temp_lb;
                model.acq_ub = temp_ub;
                model.x0     = x0;
            end

        end

    end

end