function [Y,Ystep,Xstep] = infer(D,X,maxIter,stopThres)
%INFER Infer the transformation
% 
% INPUT
% D object contains the precomputed features
% X : 3 x n matrix          - 3D scene shape
% maxIter : 1 x 1 matrix    - maximum number of iterations
% stopThres : 1 x 1 matrix  - stop threshold for terminating update
%
% OUTPUT
% Y : 3 x 4 matrix           - output transformation
% Ystep : cell of 3 x 4 matrices    - transformation in each step
% Xstep : cell of 3 x n matrices    - transformed scene in each step
%
Y = zeros(6,length(X));
Xmodel = D.Xmodel;
n = length(D.Dmap);
Xout = cell(n,1);
Ystep = cell(n,1);
Xori = X;

for i = 1:length(X)
    X{i}(:,any(abs(X{i}) > 3)) = [];
end

for itMap = 1:n
    
    % compute ture
    featX = extFeat(X,D.pcmptFeat);
    
    % update
    update = D.Dmap{itMap}*featX;
    Y = Y - update;
    
    % convert to tansformation and transform X
    rotMat = paramToTransMat(Y);
    X = transCell(rotMat,Xori,0);
    
    % save transformation in each step
    Ystep{itMap} = {reshape(paramToTransMat(Y),3,4)};
    
    % save shape in each step
    Xout{itMap} = X;
    
    % save update
    updateList(:,itMap) = update;
end

% continue loop iwith last map f update is still large
while norm(update) > stopThres && itMap < maxIter
    itMap = itMap + 1;
    
    % extract feature
    featX = extFeat(X,D.pcmptFeat);
    
    % update
    update = D.Dmap{end}*featX;
    Y = Y - update;
    
    % transform X
    rotMat = paramToTransMat(Y);
    X = transCell(rotMat,Xori,0);
    
    % save param
    Ystep{itMap} = {reshape(paramToTransMat(Y),3,4)};
    Xout{itMap} = X;
    updateList(:,itMap) = update;
end

% last step
Yout = {reshape(paramToTransMat(Y),3,4)};

% invert transformation
[Y,Ystep,Xstep] = invertInferDOCell(Yout,Ystep,Xmodel);

end

function [Y,Ystep,Xstep] = invertInferDOCell(Y,Ystep,X)
%INVERTINFERDOCELL Invert the result of DO to get transformation that
%transforms model to scene
%
% Input
% Y : 3 x 4 matrix - transformation matrix that is output from INFER, i.e.,
%                    transform scene to 3D model
% Ystep : cell of 3 x 4 matrices - transformation matrix that is output from INFER, i.e.,
%                    transform scene to 3D model in each step
% X : 3 x n matrix - 3D model of object
%
% Output
% same as input
if ~exist('Ystep','var')
    Ystep = [];
end

if ~exist('X','var')
    X = [];
end

% invert Y
for i = 1:length(Y)
    Y{i} = [Y{i}(1:3,1:3)' -Y{i}(1:3,1:3)'*Y{i}(1:3,4)];
end

Xstep = [];

% invert Ystep
if ~isempty(Ystep)
    for itMap = 1:length(Ystep)
        for i = 1:length(Ystep{itMap})
            Ystep{itMap}{i} = [Ystep{itMap}{i}(1:3,1:3)' -Ystep{itMap}{i}(1:3,1:3)'*Ystep{itMap}{i}(1:3,4)];
        end
    end
    
    % invert X back
    if ~isempty(X)
        Xstep = cell(length(Ystep),1);
        
        for itMap = 1:length(Ystep)
            
            Xstep{itMap} = cell(length(Ystep{itMap}),1);
            
            for i = 1:length(Ystep{itMap})
                Xstep{itMap}{i} = X;
                Xstep{itMap}{i}(4,:) = 1;
                Xstep{itMap}{i} = Ystep{itMap}{i}*Xstep{itMap}{i};
            end
            
        end
        
    end
    
    
end
end


