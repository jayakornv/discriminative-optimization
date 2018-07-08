function [featX] = extFeat(X,pcmptFeat)
%EXTFEAT extract features from precomputed map
    sizeMapVec = [size(pcmptFeat.map,2) 1];

    featX = zeros(size(pcmptFeat.map,1),length(X));
    
    % loop over each shape in X
    for i = 1:length(X)
        tmp = X{i};
        
        % remove points too far 
        tmp(:,any(abs(tmp) > 2,1)) = [];
        
        % compute index of each point in the map
        tmp = round((tmp-pcmptFeat.minVal)*pcmptFeat.numStepPerUnit+1);
        tmp = tmp(2,:)+(tmp(1,:)-1)*pcmptFeat.size(2)+(tmp(3,:)-1)*pcmptFeat.size(2)*pcmptFeat.size(1);

        % compute the feature
        featX(:,i) = pcmptFeat.map*accumarray(tmp',1,sizeMapVec,[],[],1);
    end

    % normalize
    if length(X) > 2
        featX = bsxfun(@rdivide,featX,sum(featX,1));
    else
        featX = featX/sum(featX);
    end
    featX(~isfinite(featX)) = 0;

end

