% This function gets a proposal from the BayesOpt model
%
% Copyright (c) Favour Mandanji Nyikosa <favour@nyikosa.com> 3-MAR-2018

function [ xopt, model ] = getSampleBayesOpt( model )

[xopt, model]            = optimizeAcquistion( model.x0, model);

end