classdef Collection < dynamicprops
   properties
   end
   
   methods
       function [] = computeallcorrelations(obj)
           subjects = fieldnames(obj);
           for s = 1:numel(subjects)
               disp(['calculating correlations for ', subjects{s}])
               obj.(subjects{s}).calculateallcorrelations;
           end
       end
   end
end
