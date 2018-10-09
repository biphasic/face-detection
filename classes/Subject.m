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
        
        function [] = plotallcorrelations(obj)
            figure
            for r = 1:numel(obj.Recordings)
                if ~isempty(obj.Recordings{r})
                    ax = subplot(1,length(obj.Recordings), r);
                    obj.Recordings{r}.plotcorrelation(ax);
                end
            end            
        end
    end
    
end