function [E] = paramToTransMat(E)
%PROJTOROW turn multiple 6D vectors into transformation matrices

Eout = zeros(12,size(E,2));
for i = 1:size(E,2)
    Eout(:,i) = vec(expMapSE3(E(:,i)));
end
E = Eout;

end

