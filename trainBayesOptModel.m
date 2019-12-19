% This function trains the BayesOpt model
%
% Copyright (c) Favour Mandanji Nyikosa <favour@nyikosa.com> 3-MAR-2018


function model = trainBayesOptModel(model)

xt          = model.x;
yt          = model.y;


if isfield(model,'windowing') && model.windowing==1 && (size(xt,1)>model.window)
                                                       
    xt     = xt( end - (model.window - 1): end, : );
    yt     = yt( end - (model.window - 1): end, : );

end

model.xt   =  xt;
model.yt   =  yt;

if model.streamlined == 1 

    model.gpDef           = gpModel;
    hyperparams_          = model.streamlined_hyp;
    model.training_hyp    = hyperparams_;

else
    
    %     model.hyp
    %     model.gpModel{3}
    %     
    %     cov_hyp = model.hyp.cov
    %     lik_hyp = model.hyp.lik

    [hyperparams_, model] = trainGP( xt , yt , model.hyp , model.gpModel , model );
    model.training_hyp    = hyperparams_;
    model.streamlined_hyp = hyperparams_;
    
    %     cov_hyp = hyperparams_.cov
    %     lik_hyp = hyperparams_.lik

end

end