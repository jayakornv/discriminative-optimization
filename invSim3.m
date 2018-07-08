function [A] = invSim3(A)
%INVSIM3 inverse Sim(3)

s = 1/A(4,4);
R = A(1:3,1:3);
t = A(1:3,4);
A = [R' -s*R'*t; 0 0 0 s];

end

