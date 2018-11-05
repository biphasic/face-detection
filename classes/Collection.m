classdef Collection < dynamicprops
   properties
       DatasetType
       OnColour = [0.8500, 0.3250, 0.0980] % red
       OffColour = [0, 0.4470, 0.7410] % blue
       % don't forget to update getsubjects method
       % rest are subjects
   end
   properties (Dependent = true)
       Supermodel
   end
   
   methods
        function obj = Collection(type)
            obj.DatasetType = type;
        end
        
        function obj = get.Supermodel(obj)
            obj = obj.getaveragemodelblink;
        end
        
        function list = getsubjects(obj)
            list = fieldnames(obj);
            list = list(5:end);
        end

        function calculateallcorrelations(obj)
            subjects = obj.getsubjects;
            for s = 1:numel(subjects)
               disp(['calculating correlations for ', subjects{s}])
               obj.(subjects{s}).calculateallcorrelations;
            end
        end
        
        function calculatealltrainingcorrelations(obj)
            subjects = obj.getsubjects;
            for s = 1:numel(subjects)
                obj.(subjects{s}).gettrainingrecording.calculatecorrelation;
            end
        end

        function blink = getaveragemodelblink(obj, smoothingFactor)
            if ~exist('smoothingFactor','var')
                smoothingFactor = 40;
                disp(['Using default smoothing factor of ', num2str(smoothingFactor)]);
            end
            subjects = obj.getsubjects;
            num = 0;
            for s = 1:numel(subjects)
               if obj.(subjects{s}).gettrainingrecordingindex ~= 0
                   if ~exist('blink', 'var')
                       blink = obj.(subjects{s}).gettrainingrecording.getmodelblink(smoothingFactor);
                       num = num + 1;
                   else
                       blink = blink + obj.(subjects{s}).gettrainingrecording.getmodelblink(smoothingFactor);
                       num = num + 1;
                   end
               else
                   continue
               end
            end
            blink = blink / num;
        end

        function plotaveragemodelblink(obj, smoothingFactor)
            if ~exist('smoothingFactor','var')
                smoothingFactor = 40;
                disp(['Using default smoothing factor of ', num2str(smoothingFactor)]);
            end
            figure;
            title(['averaged blink across all ', obj.DatasetType, ' subjects'])
            m = obj.getaveragemodelblink(smoothingFactor);
            ax = shadedErrorBar(1:length(m.AverageOn), m.AverageOn, m.VarianceOn, 'lineprops', '-b');
            ax.mainLine.LineWidth = 3;
            ax.mainLine.Color = obj.OnColour;
            ax.edge.set('Visible', false)
            ax.patch.FaceColor = obj.OnColour;
            ax = shadedErrorBar(1:length(m.AverageOff), m.AverageOff, m.VarianceOff, 'lineprops', '-r');
            ax.edge.set('Visible', false)
            ax.mainLine.Color = obj.OffColour;
            ax.patch.FaceColor = obj.OffColour;
            ax.mainLine.LineWidth = 3;
            ylim([0 inf])
            file = [1:1:length(m.AverageOn); m.AverageOn; m.AverageOff; m.VarianceOn; m.VarianceOff]';
            csvwrite('/home/gregorlenz/Recordings/face-detection/plotting-with-matplotlib/average-blink-model.csv', file)
        end
        
        function ploteachmodelblink(obj)
            subjects = obj.getsubjects;
            figure
            for s = 1:numel(subjects)
                ax = subplot(1,numel(subjects),s);
                obj.(subjects{s}).plotmodelblink(ax)
            end
        end
        
        function plotallcorrelations(obj)
            subjects = obj.getsubjects;
            figure
            for s = 1:numel(subjects)
                for r = 1:numel(obj.(subjects{s}).Recordings)
                    if ~isempty(obj.(subjects{s}).Recordings{r})
                        ax = subplot(numel(subjects),length(obj.(subjects{s}).Recordings), (s-1) * length(obj.(subjects{s}).Recordings) + r);
                        obj.(subjects{s}).Recordings{r}.plotcorrelation(ax);
                    end
                end
            end
        end
   end
end
