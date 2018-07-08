function [X,R,Rinv,Xrm] = generateData(opt)
%GENERATEDATA Generate data from option given
%
% Input
%
% opt : struct with following options
% - vertex : 3 x n matrix - base shape
% - nVertices : 1 x 1 matrix - number of randomly selected points 
%                              [default = size(opt.vertex,2)] 
% - rotation : 1 x 1 matrix - rotation in degrees [default = 0]
% - translation : 3 x 1 matrix - translation from zeros [default = 0]
% - nOutliers : 1 x 1 matrix - number of outliers [default = 1]
% - outlBd : 3 x 2 matrix - boundaries of outliers [default = [-1 1;-1 1;-1 1] ]
% - noiseSd : 1 x 1 matrix - sd of added gaussian noise [default = 0]
% - rRmvPt : 1 x 1 matrix - ratio of close points to removed [default = 0]
%
%
% Output
% X : 3 x k matrix - output shape according to option
% R : 4 x 4 matrix - matrix representation of similarity transformation
%                    satisfying R*opt.vertex == X  prior to adding noise
%                    and outliers. The above equation is in homogeneous coordinates. 
% Rinv : 4 x 4 matrix - inverse of R
% Xrm : 3 x k1 matrix - points that are removed

X = [];
R = [];

if ~isfield(opt,'vertex')
    error('No shape given in option for generating shape');
    return
end

opt = setStructDefaultValue(opt,{...
    {'nVertices',size(opt.vertex,2)},...
    {'rotation',0},...
    {'translation',[0 0 0]'},...
    {'nOutlier',0},...
    {'outlBd',[-1 1;-1 1;-1 1]},...
    {'noiseSd',0},...
    {'rRmvPt',0} ...
    });


% generate transformation matrix
R = zeros(4,4);
R(1:3,1:3) = genRandomRotationAngle(opt.rotation);
R(1:3,4) = opt.translation;
R(4,4) = 1;

% select and transform vertices
X = opt.vertex(:,ceil(size(opt.vertex,2)*rand(1,opt.nVertices)));
X = R(1:3,:) * [X;ones(1,opt.nVertices)];

% invert transformation matrix
Rinv = invSim3(R);

% add noise and outliers and remove points
X = X + opt.noiseSd*randn(size(X));
toRmPt = ceil(size(X,2)*opt.rRmvPt);
axisToRm = randn(3,1); 
axisToRm = axisToRm/norm(axisToRm);
[~,l] = sort(axisToRm'*X);
X(:,l(1:toRmPt)) = [];

outlierPt = rand(3,opt.nOutlier);
outlierPt = bsxfun(@times,outlierPt,opt.outlBd(:,2)-opt.outlBd(:,1));
outlierPt = bsxfun(@plus,outlierPt,opt.outlBd(:,1));
X = [X outlierPt];

end

