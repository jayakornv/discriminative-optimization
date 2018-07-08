function [DM,Ymat,error] = learnDO(Xmodel,X,Y,nMap,sigmaSq,gridStep)
%LEARNDO Summary of this function goes here
%   Detailed explanation goes here

fprintf('Training DO with %d maps\n',nMap)
fprintf('#data: %d \n',length(X))

D = cell(1,nMap);
error = inf(nMap,1);
Xori = X;
Yori = Y;
Yorimat = reshape(cell2mat(Yori),[numel(Yori{1}) length(Yori)]);
Ymat = Yorimat;

[pcmptFeat,normals] = precomputeFeature(Xmodel,sigmaSq,gridStep);


Ygoal = transMatToParam(Yori);
Yinit = zeros(6,length(X));
Y = Yinit;


fprintf('It: %d, err: %f\n',0,norm(Ygoal-Y,'fro').^2/length(X))

for itMap = 1:nMap
    
    % extract features
    featX = extFeat(X,pcmptFeat);
    
    % find difference between current estimates and goals
    featY = Y - Ygoal;

    % regression
    D{itMap} = (featY*featX')/(featX*featX'/length(X)+1e-4*(eye(size(featX,1))))/length(X);

    % update
    Y = Y - D{itMap}*featX;

    % convert to parameters to transformation matrices
    rotMat = paramToTransMat(Y);
    
    % transform shapes
    X = transCell(rotMat,Xori,0);

    % compute and print error
    error(itMap) = norm(Ygoal-Y,'fro')^2/length(X);
    fprintf('It: %d, err: %f\n',itMap,error(itMap))

    
end

% save data
DM = struct();
DM.Dmap = D;
DM.runOrder = 1:length(D);
DM.trainErr = error;
DM.Xmodel = Xmodel;
DM.pcmptFeat = pcmptFeat;
DM.normals = normals;
end

function x = addZero(x)
    x = [x zeros(size(x,1),1);zeros(1,size(x,1)+1)];
end

function [pcmptFeat,normals] = precomputeFeature(Xmodel,sigmaSq,gridStep)
%PRECOMPUTEFEATURE 

% set parameters
sparseMapThreshold = 1e-6;
x = -2:gridStep:2;
[X,Y,Z] = meshgrid(x,x,x);
D = [X(:) Y(:) Z(:)]';

% Compute the grids by finding all pairwise distance between all points in
% the model and the grids. This could cause error if memory is not large
% enough. If it happens, reduce the grid size or write a loop instead.
pcmptFeat.map = exp(-pwSqDist(Xmodel,D)/sigmaSq);
pcmptFeat.minVal = -2;
pcmptFeat.size = length(x)*[1 1 1];
pcmptFeat.maxSize = pcmptFeat.size(1);
pcmptFeat.numStepPerUnit = 1/gridStep; 

% calculate normal vector
[ normals ] = findPointNormals(Xmodel',6,[0 0 0]);
dirMat = bsxfun(@gt,normals*D,sum(normals.*Xmodel',2));

clear D

% compute grid in front and in the back of normal vectors
mapTmp1 = pcmptFeat.map;
mapTmp1(dirMat) = 0;
mapTmp2 = pcmptFeat.map;
mapTmp2(~dirMat) = 0;
pcmptFeat.map = [mapTmp1;mapTmp2];

clear mapTmp1
clear mapTmp2

% set small values to zero and make the matrix sparse
if sparseMapThreshold > 0
    spPcmptFeatTmp = pcmptFeat.map;
    spPcmptFeatTmp(spPcmptFeatTmp < sparseMapThreshold) = 0;
    pcmptFeat.map = sparse(spPcmptFeatTmp);
end
clear spExpMapTmp


end

