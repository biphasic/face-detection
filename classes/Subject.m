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
                else
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
    end
    
end