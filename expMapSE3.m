function [R] = expMapSE3(r)
%EXPMAP : x \in R^6 -> X in R^{3x4}

R = zeros(3,4);
theta = norm(r(1:3))+eps;
wx = [0 -r(3) r(2);r(3) 0 -r(1); -r(2) r(1) 0]/theta;
wx2 = wx^2;
sintheta = sin(theta);
costheta = cos(theta);
R(1:3,1:3) = eye(3) + sintheta*wx+(1-costheta)*wx2;
V = eye(3)+(1-costheta)/theta*wx+(theta-sintheta)/theta*wx2;
R(1:3,4) = V*r(4:6);
end

