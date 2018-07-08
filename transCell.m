function [X] = transCell(rotMat,X,mode)
%TRANSCELL perform forward and inverse transformation on mutliple inputs
%
% INPUT
% rotMat : cell of 3 x 4 matrices - transformation matrices
% X : cell of 3 x n or 3 x 4 matrices - shapes or transformation matrices
%                                       to be transformed
% mode : 1 x 1 matrix - mode of operation (see below)
%
% OUTPUT
% X : transformed X

% transform shape 
if mode == 0
    for i = 1:length(X)
        X{i} = reshape(rotMat(1:9,i),[3 3])*X{i};
        X{i}(1:3,:) = X{i}(1:3,:)+rotMat(10:12,i);
    end
    
% inverse transform transformation matrices
elseif mode == 1
    for i = 1:length(X)
        K = X{i}(1:3,1:3)*reshape(rotMat(1:9,i),[3 3])';
        X{i} = [K -K*rotMat(10:12,i)+X{i}(1:3,4)];
    end
    
% forward transform transformation matrices
elseif mode == 2
    for i = 1:length(X)
        X{i} = reshape(rotMat(:,i),3,4)*[X{i}; 0 0 0 1];
    end
end

end

