namespace FS {
    const float VERY_BIG_NUMBER = 1e10;
    const float VERY_SMALL_NUMBER = -1e10;
    Tolerances tolerances = Tolerances();

    bool _inGame = false;
    uint _currentCP = 0;
    uint _maxCP = 0;
    string _baseFolder = IO::FromDataFolder('');
    string _folder = _baseFolder + 'Fail Stats/';
    
    

    bool get_inGame() property { return _inGame; }
    uint get_currentCP() property { return _currentCP; }
    uint get_maxCP() property { return _maxCP; }
    string get_folder() property { return _folder; }
    uint get_finishes() property { return statistics._finishes; }

    const string appVersion = "1.0";

    uint _preCPIdx = 0;
	uint _preLapStartTime = 0;

    int allowedDifferenceToPersonalBest = 2000;

    bool _freshIngame = true;
    bool _freshOutgame = false;
    bool _skipResetFail = false;

    bool _readFileSuccessfully = false;

    bool _tooManyCheckpoints = false;
    bool get_tooManyCheckpoints() property {return _tooManyCheckpoints;}
    void set_tooManyCheckpoints(bool value) property {
        if (value == true){
            print("Too many checkpoints on this map! Current map has " + maxCP + " checkpoints and the limit is " + setting_general_maxCheckpointNumberMap + "! The plugin will not do anything.");
        }
        _tooManyCheckpoints = value;
    }
    bool initializing = true;

    CustomHistogram histogram = CustomHistogram();
    Race currentRun = Race();
    Race personalBestRun = Race();

    array<float> _data;
    array<float> get_data() property { return _data; }

    FailStats statistics = FailStats();

    PlayerPosition startPosition = PlayerPosition();

    GameState gameState = GameState();

    
    void Update() {
        auto playground = cast<CSmArenaClient>(GetApp().CurrentPlayground);

        if(playground is null
			|| playground.Arena is null
			|| playground.Map is null
			|| playground.GameTerminals.Length <= 0
			//|| playground.GameTerminals[0].UISequence_Current != CGamePlaygroundUIConfig::EUISequence::Playing --> deactivated because UNSURE
			){//|| cast<CSmPlayer>(playground.GameTerminals[0].GUIPlayer) is null) { --> deactivated because otherwise when going from intro to playing, _inGame is set to true
;
			_inGame = false;
            if (!_freshIngame){
                _freshIngame = true;
            }

            if (tooManyCheckpoints){
                tooManyCheckpoints = false;
                return;
            }

            if (_freshOutgame){
                write_json();
                if (setting_general_enableLogging){print('Clearing data...');}
                clear_data();
                _freshOutgame = false;
            }
			return;
		}
        
        if (_freshIngame){
            if (setting_general_enableLogging){print("Reading file...");}
            _readFileSuccessfully = read_json();
            currentRun = Race();
        }
        _freshIngame = false;
        _freshOutgame = true;

        if (!_inGame){
            initialise_map();
            // Setting handledRespawn to true to avoid adding one fail when loading into the map.
            _handledRespawn = true;
            _readFileSuccessfully = false;
        }
        
        if (tooManyCheckpoints){
            return;
        }

        auto state = VehicleState::ViewingPlayerState();
        if (get_currentPlayerRaceTime() < 0 && startPosition.isDefault){
            if (setting_general_enableLogging){print("Updating start position to " + state.Position[0] + ", " + state.Position[1] + ", " + state.Position[2] + "!");}
            startPosition._position = state.Position;
        }

        handle_resetsAndFinishes();
        
        handle_respawns();

        count_checkpoints();
        
        update_gameState();
    }

    

    void reset_data(bool reset_failStats, bool reset_pb){
        if (reset_failStats){
            statistics = FailStats();
            statistics.length = _maxCP+1;
        }
        if (reset_pb){
            personalBestRun = Race();
        }
    }

    void clear_data(){
        statistics = FailStats();
        startPosition = PlayerPosition();
    }

    void initialise_map(){
        auto playground = get_playground();
        MwFastBuffer<CGameScriptMapLandmark@> landmarks = playground.Arena.MapLandmarks;
        if (!_inGame){
            if (!_readFileSuccessfully){
                _maxCP = 0;
                array<int> links = {};
                for(uint i = 0; i < landmarks.Length; i++) {
                    if(landmarks[i].Waypoint !is null && !landmarks[i].Waypoint.IsFinish && !landmarks[i].Waypoint.IsMultiLap) {
                        if(landmarks[i].Tag == "Checkpoint") {
                            _maxCP += 1;
                        } else if(landmarks[i].Tag == "LinkedCheckpoint") {
                            if(links.Find(landmarks[i].Order) < 0) {
                                _maxCP += 1;
                                links.InsertLast(landmarks[i].Order);
                            }
                        }
                    }
                }
                statistics.length = _maxCP+1;
            }

            if (maxCP > setting_general_maxCheckpointNumberMap){
                _tooManyCheckpoints = true;
            }

            if (!personalBestRun.isValidRace){
                personalBestRun = Race();
            }

            
            _inGame = true;
        }


    }

    void compare_personalBestCurrentRun(){
        switch (setting_failTracking_allowedValueType){
            case AllowedDifferenceToPB::absolute:
                allowedDifferenceToPersonalBest = setting_failTracking_allowedAbsoluteTimeDifference;
            case AllowedDifferenceToPB::relative:
                allowedDifferenceToPersonalBest = int(Math::Floor(personalBestRun.timeDifferenceBetweenCheckpoints(currentCP) * setting_failTracking_allowedRelativeTimeDifference));
        }
        
        if ((currentRun.     timeDifferenceBetweenCheckpoints(currentCP) - 
             personalBestRun.timeDifferenceBetweenCheckpoints(currentCP)) > allowedDifferenceToPersonalBest){
            statistics.add_fail(2, currentCP);
        }
    }

    bool _handledFinish = false;
    bool _handledRespawn = false;

    void handle_resetsAndFinishes(){
        if (is_playerAndPlayground()){
            auto gui_player = get_guiPlayer();
            auto ui_sequence = get_terminal().UISequence_Current;
            auto post = (cast<CSmScriptPlayer>(gui_player.ScriptAPI)).Post;
                
            // resetting stuff
            if (!_handledRespawn && !_skipResetFail && post == CSmScriptPlayer::EPost::Char && ui_sequence == CGamePlaygroundUIConfig::EUISequence::Playing) {
                _handledRespawn = true;
                
                if (setting_failTracking_trackResetFail){
                    statistics.add_fail(0, currentCP);
                }
                reset_variablesWhenResetting();
            }
            
            else if (!_handledRespawn && _skipResetFail && post == CSmScriptPlayer::EPost::Char && ui_sequence == CGamePlaygroundUIConfig::EUISequence::Playing) {
                _handledRespawn = true;
                // skipping counting fail because pressing improve in menu on map or resetting while menu is not yet open
                reset_variablesWhenResetting();
            }
            if (_handledRespawn && post != CSmScriptPlayer::EPost::Char && ui_sequence == CGamePlaygroundUIConfig::EUISequence::Playing){
                _handledRespawn = false;
            }

            if (ui_sequence != CGamePlaygroundUIConfig::EUISequence::Playing){
                _skipResetFail = true;
            }
            else {
                _skipResetFail = false;
            }
            
            // finish stuff
            if (!_handledFinish && ui_sequence == CGamePlaygroundUIConfig::EUISequence::Finish) {
                
                _handledFinish = true;
                
                currentRun.set_finishTime(get_currentPlayerRaceTime());
                statistics.increment_finishes();
                if (personalBestRun.isValidRace && setting_failTracking_trackSlowerThanPBFail){
                    compare_personalBestCurrentRun();
                }
                if (currentRun.isValidRace){
                    if (currentRun.finishTime < personalBestRun.finishTime || personalBestRun.finishTime == -1){
                        if (setting_general_enableLogging){print("Updating personal best data according to last run.");}
                        personalBestRun = currentRun;
                    }
                }
                write_json();
            } 
            
            if (_handledFinish && ui_sequence != CGamePlaygroundUIConfig::EUISequence::Finish){
                _handledFinish = false;
            }
        }
    }

    void count_checkpoints(){
        auto playground = get_playground();
        auto guiPlayer = get_guiPlayer();
        MwFastBuffer<CGameScriptMapLandmark@> landmarks = playground.Arena.MapLandmarks;
        if (guiPlayer !is null){

            if(_preCPIdx != guiPlayer.CurrentLaunchedRespawnLandmarkIndex){// && landmarks.Length > player.CurrentLaunchedRespawnLandmarkIndex) {
                _preCPIdx = guiPlayer.CurrentLaunchedRespawnLandmarkIndex;
                if (initializing){
                    return;
                }
                // null ==> Start Block
                if(landmarks[_preCPIdx].Waypoint is null || landmarks[_preCPIdx].Waypoint.IsFinish || landmarks[_preCPIdx].Waypoint.IsMultiLap) {
                    _currentCP = 0;
                } else {
                    currentRun.set_checkpointTime(get_currentPlayerRaceTime(), currentCP);
                    if (personalBestRun.isValidRace && setting_failTracking_trackSlowerThanPBFail){
                        compare_personalBestCurrentRun();
                    }
                    
                    _currentCP++;
                    
                }
            }
        }
    }

    uint flyingRespawns = 0;
    int timeLastRespawn = Time::get_Now();
    array<int> respawnedCheckpoints = {};
    void handle_respawns(){
        if (is_playerAndPlayground()){
            auto gui_player = get_guiPlayer();
            auto script = cast<CSmScriptPlayer>(gui_player.ScriptAPI);
            auto post = script.Post;
            if (script.Score.NbRespawnsRequested > flyingRespawns && post != CSmScriptPlayer::EPost::Char) {
                flyingRespawns += 1;
                if ((Time::get_Now() - timeLastRespawn) > 1000){ // 1000ms is he time the car is frozen when doing a flying respawn
                    timeLastRespawn = Time::get_Now();
                    if (!setting_failTracking_isMultipleRespawnFailsSameCheckpointAllowed && (respawnedCheckpoints.Find(currentCP) < 0) || setting_failTracking_isMultipleRespawnFailsSameCheckpointAllowed
                        && setting_failTracking_trackRespawnFail){
                        statistics.add_fail(1, currentCP);
                        respawnedCheckpoints.InsertLast(currentCP);
                    }
                }
            }
            if (script.Score.NbRespawnsRequested == 0) {
                flyingRespawns = 0;
            }
        }
    }

    void update_gameState(){
        auto state = VehicleState::ViewingPlayerState();
        if (!(state is null)){
            gameState.currentPosition._position = state.Position;
            
            gameState.currentVelocityLength = state.WorldVel.Length();
            gameState.currentGameTime = get_currentPlayerRaceTime();
            if (gameState.currentVelocityLength > tolerances.standstillVelocityTolerance){
                gameState.standstillStart = gameState.currentGameTime;
            }
        }
    }

    void write_json(){
        if (setting_general_enableLogging){print('Saving file...');}
        string currentMap = get_mapId();
        string jsonPath = folder + currentMap + ".json";
        if (!IO::FolderExists(folder)) {
            IO::CreateFolder(folder);
        }

        Json::Value jsonData = Json::Object();

        jsonData["version"] = appVersion;
        jsonData["size"] = statistics.length;
        jsonData["finishes"] = statistics._finishes;
        jsonData["statistics"] = statistics.toJson();

        if (personalBestRun.isValidRace){
            jsonData["personalBest"] = personalBestRun.ToJson();
        }
        
        Json::ToFile(jsonPath, jsonData);
    }

    bool read_json(){
        string currentMap = get_mapId();
        string jsonPath = folder + currentMap + ".json";
        
        if (!IO::FolderExists(folder)) {
            IO::CreateFolder(folder);
        }

        bool firstLoad = !IO::FileExists(jsonPath);

        if (firstLoad) {
            // file doesnt exist, dont load
            return false;
        }

        IO::File f(jsonPath);
        f.Open(IO::FileMode::Read);
        auto content = f.ReadToEnd();
        f.Close();
        Json::Value jsonData;
        if (content == "" || content == "null") {
            jsonData = Json::Object();
        } else {
            jsonData = Json::FromFile(jsonPath);
        }

        if (jsonData.HasKey("version") && jsonData.HasKey("size")) {
            _maxCP = int(jsonData["size"]-1.0f);
            statistics = FailStats(jsonData);
            
            if (jsonData.HasKey("personalBest")){
                array<int> times = {};
                for (uint i = 0; i < maxCP; i++){
                    times.InsertLast(jsonData["personalBest"]["checkpointTimes"][""+i]);
                }
                personalBestRun = Race(times, jsonData["personalBest"]["finishTime"]);
                if (!personalBestRun.isValidRace){
                    personalBestRun = Race();
                }
            }

        }
        else {
            return false;
        }
        // Setting handledRespawn to true to avoid adding one fail when loading into the map.
        _handledRespawn = true;
        return true;
    }

    void Render(){
        if (_inGame &&
            !_tooManyCheckpoints &&
            (setting_interface_plotVisible == PlotVisible::always || 
            (setting_interface_plotVisible == PlotVisible::onlyWhenOpenplanetMenu && UI::IsOverlayShown()))){
            histogram.data = statistics.get_graphData();
            histogram.sum = statistics._sum;
            histogram.take_settingsInput();
            histogram.finishesVis = statistics._finishesVis;
            histogram.render();
        }

        //UI::End();
 
    }


    void reset_variablesWhenResetting(){
        respawnedCheckpoints = {};
        currentRun = Race();
    }

}


// few class definitions for nicer code/better organisation
class PlayerPosition{
    vec3 _position = vec3(FS::VERY_BIG_NUMBER, FS::VERY_BIG_NUMBER, FS::VERY_BIG_NUMBER);
    vec3 get_position() property {return _position;}
    float tolerance = FS::tolerances.positionTolerance;

    bool get_isDefault() property { return vec3(FS::VERY_BIG_NUMBER, FS::VERY_BIG_NUMBER, FS::VERY_BIG_NUMBER) == position; }

    bool is_tolerancedEqual( vec3 comparisonPosition ){
        for (uint i=0; i<3; i++){
            if (Math::Abs(position[i] - comparisonPosition[i]) > tolerance){
                return false;
            }
        }
        return true;
    }
}

class Tolerances{
    float positionTolerance = 3;
    float standstillVelocityTolerance = 0.5;
}

class GameState{
    PlayerPosition currentPosition = PlayerPosition();
    float currentVelocityLength = 0;
    float currentGameTime = 0;
    float standstillStart = 0;
}