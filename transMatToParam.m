function [featY] = transMatToParam(Y)
%TRANSMATTOPARAM convert multiple transformation matrices to 6d parameter
%vectors

featY = zeros(numel(logMapSE3(Y{1})),length(Y));

for i = 1:length(Y)
    featY(:,i) = logMapSE3(Y{i});
end

end

