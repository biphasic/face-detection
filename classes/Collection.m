classdef Collection < dynamicprops
   properties
       %only subjects
   end
   
   methods
        function obj = Collection()
        end

        function [] = computeallcorrelations(obj)
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
            fig = figure;
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
            set(gca,'xtick',[])
            set(gca,'xticklabel',[])
            set(gca,'ytick',[])
            set(gca,'yticklabel',[])
            iptsetpref('ImshowBorder','tight'); 
            set(gca,'Color','None')
            %saveas(gca, '/home/gregorlenz/PhD/cvpr2019/figures/averageModelBlink.png');
            export_fig /home/gregorlenz/PhD/cvpr2019/figures/averageModelBlink.png
        end
   end
end
