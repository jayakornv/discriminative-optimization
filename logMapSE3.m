function [l] = logMapSE3(A)
%LOGMAP : R in R^{3x4} -> r \in R^6

l = zeros(6,1);
R = A(1:3,1:3);
theta = acos((trace(R)-1)/2)+eps;
wx = theta/(2*sin(theta))*(R-R');
l(1:3) = [-wx(2,3) wx(1,3) -wx(1,2)];
V = eye(3)+(1-cos(theta))/theta^2*wx+(theta-sin(theta))/theta^3*wx^2;
l(4:6) = V\A(1:3,4);
end

