classdef Subject < handle
    properties
        Name
        Recordings
        CorrelationThreshold
        Modelblink
        AmplitudeScale
        BlinkLength
    end
        
    methods
        function obj = Subject(name)
            obj.Name = name;
            obj.CorrelationThreshold = 0.88;
            obj.Modelblink = Modelblink();
            obj.BlinkLength = 300000;
        end
        
        function obj = addrecording(obj, number, eventStream, isTrainingRecording)
            obj.Recordings{1,number} = Recording(eventStream, isTrainingRecording, obj);
        end
        
        function index = gettrainingrecordingindex(obj)
            for index = 1:numel(obj.Recordings)
                if ~isempty(obj.Recordings{index}) && obj.Recordings{index}.IsTrainingRecording
                    break
                end
            end
        end
        
        function recording = gettrainingrecording(obj)
            recording = obj.Recordings{obj.gettrainingrecordingindex};
        end
        
        function [] = calculateallcorrelations(obj)
            for r = 1:numel(obj.Recordings)
                if ~isempty(obj.Recordings{r})
                    disp(['Subject: ', obj.Name, ', recording no: ', num2str(r)])
                    obj.Recordings{r}.calculatecorrelation();
                end
            end
        end
        
        function [] = ploteyeactivitiesfortraining(obj)
            rec = obj.gettrainingrecording;
            locs = rec.getannotatedlocations;
            figure
            for l = 1:numel(locs)
                rec.(locs{l}).plotactivity(numel(locs), 1, l, locs{l})
            end
        end
        
        function [] = plotcorrelation(obj)
            figure
            for r = 1:numel(obj.Recordings)
                ax = subplot(1,length(obj.Recordings), r);
                grid1 = obj.Recordings{r}.EventstreamGrid1;
                corrThreshold = obj.CorrelationThreshold;
                scatter3(grid1.x(grid1.patternCorrelation>corrThreshold), -grid1.ts(grid1.patternCorrelation>corrThreshold), grid1.y(grid1.patternCorrelation>corrThreshold))
                hold on
                if r == 2
                    title(ax, [obj.Name, ', correlation threshold: 0.', int2str(obj.CorrelationThreshold*100)]);
                end
                grid2 = obj.Recordings{r}.EventstreamGrid2;
                scatter3(grid2.x(grid2.patternCorrelation>corrThreshold), -grid2.ts(grid2.patternCorrelation>corrThreshold), grid2.y(grid2.patternCorrelation>corrThreshold))
                set(gca, 'xtick', [0:19:304])
                set(gca, 'ztick', [0:15:240])
                zlim([0 240])
                xlim([0 304])

                %for e = grid1.ts(grid1.patternCorrelation>corrThreshold)
                maximumDifference = 50000;
                valid = grid1.ts(grid1.patternCorrelation>corrThreshold);
                for e = 2:length(valid)
                    %x = abs(grid1.x(grid1.ts == valid(e)) - grid1.x(grid1.ts == valid(e-1)) )/2;
                    x1 = grid1.x(grid1.ts == valid(e));
                    x2 = grid1.x(grid1.ts == valid(e-1));
                    x = (x1(1) + x2(1))/2;
                    y = grid1.y(grid1.ts == valid(e));
                    y = y(1);
                    if valid(e) > 1000000 && (valid(e) - valid(e-1)) < maximumDifference && isequal(grid1.y(grid1.ts == valid(e)), grid1.y(grid1.ts == valid(e-1))) && abs(x1(1) - x2(1)) < 60
                        scatter3(ax, x, -valid(e), y, 'red', 'diamond', 'filled')
                    end
                end

                valid = grid2.ts(grid2.patternCorrelation>corrThreshold);
                for e = 2:length(valid)
                    %x = abs(grid2.x(grid2.ts == valid(e)) - grid2.x(grid2.ts == valid(e-1)) )/2;
                    x1 = grid2.x(grid2.ts == valid(e));
                    x2 = grid2.x(grid2.ts == valid(e-1));
                    x = (x1(1) + x2(1))/2;
                    y = grid2.y(grid2.ts == valid(e));
                    y = y(1);
                    if valid(e) > 1000000 && (valid(e) - valid(e-1)) < maximumDifference && isequal(grid2.y(grid2.ts == valid(e)), grid2.y(grid2.ts == valid(e-1))) && abs(x1(1) - x2(1)) < 60
                        scatter3(ax, x, -valid(e), y, 'red', 'diamond', 'filled')
                    end
                end
            end            
        end
    end
    
end