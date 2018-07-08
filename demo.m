% this is a demo file

%% (1) Load and preprocess model

% load model
load('stanford_bunny.mat');
modelFull = model;

% remove mean and scale so that it fits in the box of [-1,1]^3
modelFull = bsxfun(@minus,modelFull,min(modelFull,[],2));
modelFull = bsxfun(@minus,modelFull,max(modelFull,[],2)/2);
modelFull = modelFull / max(abs(modelFull(:)));

% subsample model
pcModel = pointCloud(modelFull');
pcModel = pcdownsample(pcModel,'gridAverage',0.16);
modelSmp = pcModel.Location';
clear pcModel

%% (2) Generate training Data
nTrain = 30000; % number of training samples

% generate train set
fprintf('Generating %d training data\n',nTrain);

% cells for saving generated data
Rtrain = cell(1,nTrain);
Xtrain = cell(1,nTrain);
Ytrain = cell(1,nTrain);

for i = 1:nTrain
    
    % ************ Be careful about these parameters! If set too high then
    % the alignment could away from correct pose!
    
    % setting for generate train set
    opt = struct( ...
        'vertex',modelSmp, ... % the template point cloud for generating data
        'nVertices',400+ceil(400*rand(1)),... % number of points
        'rotation',60*(sqrt(rand())),... % angle for generating random rotation
        'translation',sign(randn(3,1)).*rand(3,1)*0.3,... % random translation
        'nOutlier',max(0,ceil((rand(1)-0.3)/0.7*300)),... % number of outliers
        'outlBd',1.5*[-1 1;-1 1;-1 1],... % boundaries of outliers
        'noiseSd',0.05*rand(),... % noise sd
        'rRmvPt',rand()*0.5+0.4); % percentage of incompleteness for model
    
    % generate train data
    [Xtrain{i},Rtrain{i},Ytrain{i}] = generateData(opt);
    
    % generate structured outliers
    Xtrain{i} = [Xtrain{i} ...
        bsxfun(@plus,randn(3,ceil(50+rand*150))/(4+5*rand),sign(rand(3,1)-0.5).*rand(3,1)*1.5)];
    Rtrain{i} = Rtrain{i}(1:3,:);
    Ytrain{i} = Ytrain{i}(1:3,:);
end

%% (3) Train DO
nMap = 30; % number of maps
sigmaSq = 0.03;
gridStep = 0.05;

% train DO
% INPUT
% modelSmp : 3 x n matrix - 3D points of model
% Xtrain, Ytrain: n x 1 cells - training data and groundtruths as generated
%                               above
% nMap: 1 x 1 matrix - number of maps to learn
% sigmaSq: 1 x 1 matrix - sigma squared for gaussian
% gridStep : 1 x 1 struct - grid step for precomputing
% ***** Important: gridStep must divide 1 and get integer... Otherwise
% could cause error...
%
% OUTPUT
% D : nMap x 1 cell - sequence of update maps
% YtrainFinal : n x 1 cells - final values of Y
% trainErr : nMap x 1 matrix - training error in each iteration
[DM,YtrainFinal,trainErr] = learnDO(modelSmp,Xtrain,Ytrain,nMap,sigmaSq,gridStep);

%% (5) Run test
% generate a test sample
opt = struct( ...
    'vertex',modelFull, ... % the template point cloud for generating data
    ... % note that for test here we use a different point cloud!
    'nVertices',400+ceil(400*rand(1)),... % number of points
    'rotation',60*rand(),... % angle for generating random rotation
    'translation',sign(randn(3,1)).*rand(3,1)*0.3,... % random translation
    'nOutlier',max(0,ceil((rand(1)-0.3)/0.7*300)),... % number of outliers
    'outlBd',1.5*[-1 1;-1 1;-1 1],... % boundaries of outliers
    'noiseSd',0.05*rand(),... % noise sd
    'rRmvPt',rand()*0.25+0.5); % percentage of incompleteness for model

% generate train data
[Xtest,Rtest,Ytest] = generateData(opt);

maxIter = 1000;
stopThres = 0.001;
tic
% INPUT
% DM : The DM maps above
% Xtest : cell of 3 x n data : test data point *** needs to be put in a cell
% maxIter : 1 x 1 matrix : maximum number of iterations
% stopThres : 1 x 1 matrix : steop threshold
%
% Output
% Yout : 1 x 1 cell - final rotation and translation matrix
% Ystep : step x 1 cell - rotation and translation in each iteration
% Xstep : step x 1 cell - the rotated and translated shape
[Yout,Ystep,Xstep] = infer(DM,{Xtest},maxIter,stopThres);
toc
Xgt = bsxfun(@plus,Rtest(1:3,1:3)*DM.Xmodel,Rtest(1:3,4));

% visualize result in steps
figure
scatter3(Xtest(1,:),Xtest(2,:),Xtest(3,:),'b.');
hold on
scatter3(DM.Xmodel(1,:),DM.Xmodel(2,:),DM.Xmodel(3,:),'r.');
scatter3(Xgt(1,:),Xgt(2,:),Xgt(3,:),'g.');
legend('Data','Current estimate','Groundtruth')
title(['Step : 0/' num2str(length(Xstep)) ', press any key to continue'])
    axis equal
    pause
for itStep = 1:length(Xstep)
    cla
    scatter3(Xtest(1,:),Xtest(2,:),Xtest(3,:),'b.');
    hold on
    scatter3(Xstep{itStep}{1}(1,:),Xstep{itStep}{1}(2,:),Xstep{itStep}{1}(3,:),'r.');
    scatter3(Xgt(1,:),Xgt(2,:),Xgt(3,:),'g.');
    
    legend('Data','Current estimate','Groundtruth')
    title(['Step : ' num2str(itStep) '/' num2str(length(Xstep)) ', press any key to continue'])
    axis equal
    pause
end