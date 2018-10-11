classdef Collection < dynamicprops
   properties
       %only subjects
   end
   
   methods
        function obj = Collection()
        end

        function calculateallcorrelations(obj)
           subjects = fieldnames(obj);
           for s = 1:numel(subjects)
               disp(['calculating correlations for ', subjects{s}])
               obj.(subjects{s}).calculateallcorrelations;
           end
        end

        function blink = getaveragemodelblink(obj, smoothingfactor)
            subjects = fieldnames(obj);
            num = numel(subjects);
            for s = 1:numel(subjects)
               if s == 1
                   blink = obj.(subjects{s}).gettrainingrecording.getmodelblink(smoothingfactor);
               else
                   blink = blink + obj.(subjects{s}).gettrainingrecording.getmodelblink(smoothingfactor);
               end
            end
            blink = blink / num;
        end

        function plotaveragemodelblink(obj, smoothingFactor)
            figure;
            %title('averaged blink across all subjects')
            m = obj.getaveragemodelblink(smoothingFactor);
            ax = shadedErrorBar(1:length(m.AverageOn), m.AverageOn, m.VarianceOn, 'lineprops', '-b');
            ax.mainLine.LineWidth = 3;
            ax.mainLine.Color = [0  0.4470    0.7410];
            ax.edge.set('Visible', false)
            ax.patch.FaceColor = [0    0.4470    0.7410];
            ax = shadedErrorBar(1:length(m.AverageOff), m.AverageOff, m.VarianceOff, 'lineprops', '-r');
            ax.edge.set('Visible', false)
            %ax.mainLine.Color = [0.8500    0.3250    0.0980];
            %ax.patch.FaceColor = [0.8500    0.3250    0.0980];
            ax.mainLine.LineWidth = 3;
            ylim([0 inf])
            file = [1:1:length(m.AverageOn); m.AverageOn; m.AverageOff; m.VarianceOn; m.VarianceOff]';
            csvwrite('/home/gregorlenz/Recordings/face-detection/printing-with-matplotlib/average-blink-model.csv', file)
        end
        
        function ploteachmodelblink(obj)
            subjects = fieldnames(obj);
            for s = 1:numel(subjects)
                ax = subplot(1,numel(subjects),s);
                obj.(subjects{s}).plotmodelblink(ax)
            end
        end
        
        function plotallcorrelations(obj)
            subjects = fieldnames(obj);
            figure
            for s = 1:numel(subjects)
                if isempty(obj.(subjects{s}).gettrainingrecording.EventstreamGrid1)
                    error('Run correlation first')
                else
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
end
