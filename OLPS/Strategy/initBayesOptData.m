% This function initialises the data for a BayesOpt model
%
% Copyright (c) Favour Mandanji Nyikosa <favour@nyikosa.com> 3-MAR-2018

function model = initBayesOptData( x, y, model )

% data that is used
model.xt       = x;
model.yt       = y;

% storage for ALL data
model.x        = x;
model.y        = y;

end