classdef FakeOut
    properties
        date
    end
    methods
        function obj = FakeOut(d)
            obj.date = d;
        end
        function v = get(obj, nume)
            if ~isfield(obj.date, nume), error('mock: semnalul %s nu este salvat (To Workspace)', nume); end
            v = obj.date.(nume);
        end
    end
end
