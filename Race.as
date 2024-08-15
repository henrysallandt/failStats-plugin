
class Race{
    private array<int> _checkpointTimes = {};
    private int _finishTime = -1;

    array<int> get_checkpointTimes() property {return _checkpointTimes;}
    int get_finishTime() property {return _finishTime;}
    void set_finishTime(int value) property {_finishTime = value;}
    uint get_numberCheckpoints() property {return _checkpointTimes.Length;}
    bool get_isValidRace() property {return (numberCheckpoints == FS::maxCP && finishTime > 0);}

    int timeDifferenceBetweenCheckpoints(uint checkpointNumber) {
        if (checkpointNumber < 0){
            return -1;
        } else if (checkpointNumber == 0){
            return checkpointTimes[checkpointNumber];
        } else if (checkpointNumber == (FS::maxCP)) {
            return finishTime - checkpointTimes[checkpointNumber-1];
        } else {
            return checkpointTimes[checkpointNumber] - checkpointTimes[checkpointNumber-1];
        }
    }

    Race(){_checkpointTimes = {}; _checkpointTimes.Resize(FS::maxCP);}
    Race(array<int> checkpointTimesIn, int finishTimeIn){
        _checkpointTimes = checkpointTimesIn;
        _finishTime = finishTimeIn;
    }

    void add_checkpointTime(int time){ _checkpointTimes.InsertLast(time);}
    void set_checkpointTime(int time, uint checkpointNumber) {_checkpointTimes[checkpointNumber] = time;}

    Json::Value ToJson() {
        Json::Value output = Json::Object();
        if (isValidRace){
            output["finishTime"] = finishTime;
            Json::Value jsonCheckpointTimes = Json::Object();
            for (uint i = 0; i < FS::maxCP; i++){
                jsonCheckpointTimes[""+i] = checkpointTimes[i];
            }
            output["checkpointTimes"] = jsonCheckpointTimes;
        }
        return output;
    }
}
