% This function updates the data of a BayesOpt model
%
% Copyright (c) Favour Mandanji Nyikosa <favour@nyikosa.com> 3-MAR-2018

function model    = updateBayesOptData( x, y, model )

x_                = [ model.x;  x ];
y_                = [ model.y;  y ];

model.x           = x_;
model.y           = y_;

model.iterations  = model.iterations + 1 ;

end