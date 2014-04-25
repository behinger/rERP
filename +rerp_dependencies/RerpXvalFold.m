classdef RerpXvalFold < matlab.mixin.Copyable
    %RERPXVALFOLD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        data_variance
        noise_variance
        num_samples
    end
    
    methods
        function r2 = getMeanR2(obj)
            r2=[];
            for i = 1:length(obj)
                
            end
            
        end
        
        function significance = getMeanR2Significance(obj, alpha)
            significance=[];
            for i = 1:length(obj)
                
            end           
        end
    end
end

