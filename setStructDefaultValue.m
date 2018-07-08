function [opt] = setStructDefaultValue(opt,paramValPair)
%SETSTRUCTDEFAULTVALUE Set default value to fields of structure if not
%provided

for i = 1:length(paramValPair)
   if ~isfield(opt,paramValPair{i}{1})
       opt.(paramValPair{i}{1}) = paramValPair{i}{2};
   end
end


end

