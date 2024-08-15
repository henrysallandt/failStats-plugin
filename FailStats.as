class FailStats{
    array<FailStat> _data = {FailStat("resets"), FailStat("respawns"), FailStat("tooSlows")};
    FailStat _sum = FailStat("sum");
    float _sumAll = 0;
    uint _finishes = 0;
    float _finishesVis = 0;
    void increment_finishes() {
        if (setting_failTracking_onlyCountFinishWhenNoFailWasTracked && _hasOccuredFail){
            return;
        }
        _finishes += 1;
    }
    uint get_length() property {return _data[0].length;}
    void set_length(uint inLength) property {
        for (uint i=0; i<_data.Length; i++){
            _data[i].length = inLength;
        }
    }
    bool _createdFromReadData = false;
    uint get_nFailTypes() property {return _data.Length;}

    bool _hasOccuredFail = false;

    array<FailStat> get_graphData() property {
        array<FailStat> graphData = {};
        if (setting_interface_showResetFail){
            graphData.InsertLast(_data[0]);
        }
        if (setting_interface_showRespawnFail){
            graphData.InsertLast(_data[1]);
        }
        if (setting_interface_showSlowerThanPBFail){
            graphData.InsertLast(_data[2]);
        }
        _sum = FailStat("sum", sum_multipleArrays(graphData));
        
        FailStat buffer;
        switch( setting_interface_plotType )
        {
        case PlotType::absolute:
            _finishesVis = _finishes;
            break;
        case PlotType::relative:
            _sumAll = sum_overArray(_sum) + _finishes;

            if (_sumAll != 0){
                for (uint iType = 0; iType < graphData.Length; iType++){
                    graphData[iType] = graphData[iType] / _sumAll;
                }
                _finishesVis = _finishes/_sumAll;
                _sum = _sum/_sumAll;
            }
            break;
        case PlotType::failPercentage:
            buffer = _sum;
            buffer._data.InsertLast(_finishes);
            buffer = FailStat("sum", sum_overArrayTriangle(buffer));
            
            for (uint iType = 0; iType < graphData.Length; iType++){
                graphData[iType] = graphData[iType] / buffer;
            }
            _sum = _sum / buffer;
            
            break;

        default:
            
        }

        return graphData;
    }

    void add_fail(uint which, uint where){
        if (setting_failTracking_onlyCountFailWhenNoFailWasTracked && _hasOccuredFail){
            return;
        }
        auto state = VehicleState::ViewingPlayerState();
        if (!FS::startPosition.isDefault && setting_failTracking_skipFailWhenNearStart){
            if (FS::startPosition.is_tolerancedEqual(FS::gameState.currentPosition._position)){
                if (setting_general_enableLogging){print("Skipping adding fail because it happens next to the start.");}
                return;
            }
        }

        if ((FS::gameState.currentGameTime - FS::gameState.standstillStart) > setting_failTracking_skipFailWhenStandstillDuration && FS::gameState.currentVelocityLength < FS::tolerances.standstillVelocityTolerance && setting_failTracking_skipFailWhenStandstill){
            if (setting_general_enableLogging){print("Skipping adding fail because car speed is almost 0 (assumed you were afk).");}
            return;
        }

        switch (which){
            case 0:
                _data[which].add_fail(where);
                if (setting_general_enableLogging){print("Resetting fail: " + ArrayToString(_data[which]._data));}
                break;
            case 1:
                _data[which].add_fail(where);
                if (setting_general_enableLogging){print("Respawning fail: " + ArrayToString(_data[which]._data));}
                break;
            case 2:
                _data[which].add_fail(where);
                if (setting_general_enableLogging){print("Too slow fail: " + ArrayToString(_data[which]._data));}
                break;
            default:
        }
        _hasOccuredFail = true;
    }

    void reset_data(){
        // resetting data, calling resetting functions
        _finishes = 0;
    }
    Json::Value toJson(){
        Json::Value jsonData = Json::Object();
        for (uint iType = 0; iType < nFailTypes; iType++){
            jsonData[_data[iType]._name] = _data[iType].toJson();
        }
        return jsonData;
    }

    FailStats(){}
    FailStats(Json::Value inputJson){
        string name;
        length = inputJson["size"];
        _finishes = inputJson["finishes"];
        for (uint iType = 0; iType < nFailTypes; iType++){
            name = _data[iType]._name;
            if (inputJson.HasKey("statistics")){
                if (inputJson["statistics"].HasKey(name)){
                    _data[iType] = FailStat(name, inputJson["statistics"][name], length);
                }
            }
        }
    }
}

class FailStat{
    array<float> _data;
    array<float> get_data() property {return _data;}
    string _name = "";
    void set_length(uint length) property { _data = get_nullArrayOfLength(length);}
    uint get_length() property { return _data.Length;}
    
    vec4 get_color() const property {
        if (_name == "resets"){
            return vec4(1, 0, 0, 1);
        } else if (_name == "respawns"){
            return vec4(1, 0.5, 0.1, 1);
        } else if (_name == "tooSlows") {
            return vec4(1, 0.9, 0.1, 1);
        } else if (_name == "sum"){
            return vec4(1, 0, 0, 1);
        }
        else {
            return vec4(1,1,1,1);
        }
    }
    // constructors
    FailStat(){}
    FailStat(const string name, uint length){
        _name = name;
        _data = {0};
        for (uint i=0; i<length; i++){
            _data.InsertLast(0);
        }

    }
    FailStat(const string name, array<float> inputData){
        _name = name;
        _data = inputData;
    }
    FailStat(const string name){
        _data = {0};
        _name = name;
    }
    FailStat(const string name, Json::Value inputJson, uint size){
        _name = name;
        length = size;
        for (uint i = 0; i < length; i++){
            if (inputJson.HasKey(""+i)) {
                _data[i] = inputJson[""+i];
            }
        }
    }

    // methods
    void reset_data(){
        _data = get_nullArrayOfLength(length);
    }

    void add_fail(uint where){
        _data[where] += 1;
    }

    void add_finishes(uint finishes){
        _data.InsertLast(finishes);
    }

    Json::Value toJson(){
        Json::Value jsonData = Json::Object();
        for (uint iData = 0; iData < length; iData++){
            jsonData[""+iData] = _data[iData];
        }
        return jsonData;
    }

    float opIndex(uint i){
        return _data[i];
    }

    FailStat opAdd(FailStat summand){
        return FailStat(_name, sum_twoArrays(data,summand.data));
    }

    FailStat opDiv(FailStat divisor){
        return FailStat(_name, divide_twoArrays(data,divisor.data));
    }

    FailStat opDiv(float number){
        array<float> buffer = data;
        for (uint i=0; i<data.Length; i++){
            buffer[i] = data[i]/number;
        }
        return FailStat(_name, buffer);
    }

    array<float> opImplConv() const  { return _data; }

}