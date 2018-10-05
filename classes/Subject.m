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
            tileWidth = 19;
            tileHeight = 15;
            figure
            hold on
            for l=1:3
                if l == 1
                    loc = 'Center';
                elseif l == 2
                    loc = 'Left';
                elseif l == 3
                    loc = 'Right';
                end
                rec = obj.gettrainingrecording();
                blinkCoordinates = rec.(loc).Location;
                eye = crop_spatial(rec.Eventstream, blinkCoordinates(1)-tileWidth/2, blinkCoordinates(2)-tileHeight/2, tileWidth, tileHeight);
                eye = activity(eye, 50000, true);
                timeScale = 10;
                continuum = shannonise(eye, timeScale);
                ax = subplot(3, 1, l);
                title(ax, loc)
                ylim([0 3])
                opts1={'FaceAlpha', 0.7, 'FaceColor', [0    0.4470    0.7410]};%blau
                opts2={'FaceAlpha', 0.7, 'FaceColor', [0.8500    0.3250    0.0980]};%rot
                opts3={'FaceAlpha', 0.7, 'FaceColor', [0.4660    0.6740    0.1880]};%grün
                if l == 1
                    if ~isempty(rec.Center.Times)
                        mask = continuum.ts < ((rec.Center.Times(end) + 4000000)/timeScale);
                        disp('custom scale for center')
                    else
                        mask = continuum.ts < (20000000/timeScale);
                    end
                elseif l == 2
                    if ~isempty(rec.Left.Times)
                       mask = and(continuum.ts > ((rec.Left.Times(1)-3000000)/timeScale), continuum.ts < ((rec.Left.Times(end)+3000000)/timeScale));
                       disp('custom scale for left')
                    else
                       mask = and(continuum.ts > (10000000/timeScale), continuum.ts < (35000000/timeScale));
                    end
                elseif l == 3
                    if ~isempty(rec.Right.Times)
                        mask = continuum.ts > ((rec.Right.Times(1) - 3000000)/timeScale);
                        disp('custom scale for right')
                    else
                        mask = continuum.ts > (20000000/timeScale);
                    end
                end
                z = zeros(1, numel(continuum.activityOn(mask)));
                x = continuum.ts(mask)*timeScale;
                y1 = continuum.activityOff(mask)/obj.AmplitudeScale;
                y2 = continuum.activityOn(mask)/obj.AmplitudeScale;
                fill_between(x, y1, y2, y1 < y2, opts2{:});
                fill_between(x, z, y1, y1 > z, opts1{:});
                %fill_between(x, z, y2, y2 > z, opts2{:});
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