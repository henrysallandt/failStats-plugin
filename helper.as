int get_currentGameTime() {
  auto playground = get_playground();
  if (playground is null || playground.Interface is null ||
      playground.Interface.ManialinkScriptHandler is null) {
    return -1;
  }
  return playground.Interface.ManialinkScriptHandler.GameTime;
}

CSmArenaClient @get_playground() {
  CSmArenaClient @playground = cast<CSmArenaClient>(GetApp().CurrentPlayground);
  return playground;
}

CSmPlayer @get_guiPlayer(){
    CSmPlayer @guiPlayer = cast<CSmPlayer>(get_terminal().GUIPlayer);
    return guiPlayer;
}

CGameTerminal @get_terminal(){
  CGameTerminal @terminal = get_playground().GameTerminals[0];
  return terminal;
}

bool is_playerAndPlayground(){
    auto playground = get_playground();
    if (playground !is null && playground.GameTerminals.Length > 0) {
        auto terminal = playground.GameTerminals[0];
        auto gui_player = cast<CSmPlayer>(terminal.GUIPlayer);
        if (gui_player !is null) {
            return true;
        }
    }
    return false;
}

int get_playerStartTime() {
  CSmPlayer @smPlayer = get_player();
  if (smPlayer is null) {
    return -1;
  }
  return smPlayer.StartTime;
}

CSmPlayer @get_player() {
  auto playground = get_playground();
  if (playground is null || playground.GameTerminals.Length != 1) {
    return null;
  }

  return cast<CSmPlayer>(playground.GameTerminals[0].GUIPlayer);
}

int get_currentPlayerRaceTime() {
  return get_currentGameTime() - get_playerStartTime();
}


float find_maxInArray(array<float> inputArray){
    float maximum = FS::VERY_SMALL_NUMBER;
    for (uint i = 0; i < inputArray.Length; i++){
        if (inputArray[i] > maximum){
            maximum = inputArray[i];
        }
    }
    return maximum;
}
float find_minInArray(array<float> inputArray){
    float minimum = FS::VERY_BIG_NUMBER;
    for (uint i = 0; i < inputArray.Length; i++){
        if (inputArray[i] < minimum){
            minimum = inputArray[i];
        }
    }
    return minimum;
}

float sum_overArray(array<float> inputArray){
    float result = 0;
    for (uint i = 0; i < inputArray.Length; i++){
        result += inputArray[i];
    }
    return result;
}

array<float> sum_overArrayTriangle(array<float> inputArray){
    // Calculates for each element in array the sum of the numbers right to it.
    // example input {3, 5, 6, 2, 1}
    // example output {17, 14, 9, 3}
    array<float> result = {};
    float sum = inputArray[inputArray.Length-1];
    for (int i = inputArray.Length-2; i >= 0; i--){
        sum += inputArray[i];
        result.InsertAt(0, sum);
    }
    return result;
}

array<float> sum_multipleArrays(array<FailStat> inputArray){
  uint nArrays = inputArray.Length;
  if (nArrays == 0){
    return {};
  }
  uint length = inputArray[0].length;

  for (uint i = 0; i < inputArray.Length; i++){
    if (inputArray[i].length != length){
      throw("Not all elements of the array have the same length!");
    }
  }
  array<float> result = get_nullArrayOfLength(length);
  for (uint i = 0; i < inputArray.Length; i++){
    for (uint j = 0; j < inputArray[i].length; j++){
      result[j] += inputArray[i][j];
    }
  }
  return result;
}

array<float> sum_twoArrays(array<float> summand1, array<float> summand2){
  if (!(summand1.Length == summand2.Length)){
    throw("Both arrays must have the same length, but they are of length " + summand1.Length + " and " + summand2.Length + "!");
  }
  // check that both arrays have same length
  array<float> result = get_nullArrayOfLength(summand1.Length);
  for (uint i=0; i<summand1.Length; i++){
    result[i] = summand1[i] + summand2[i];
  }
  return result;
}

array<float> divide_twoArrays(array<float> dividend, array<float> divisor){
  if (!(dividend.Length == divisor.Length)){
    throw("Both arrays must have the same length, but they are of length " + dividend.Length + " and " + divisor.Length + "!");
  }
  array<float> quotient = get_nullArrayOfLength(dividend.Length);
  for (uint i=0; i<dividend.Length; i++){
    if (divisor[i] != 0){
      quotient[i] = dividend[i] / divisor[i];
    }
    else{
      quotient[i] = 0;
    }
  }
  return quotient;
}

array<float> get_nullArrayOfLength(uint length){
  array<float> result = {};
  for (uint i = 0; i < length; i++){
    result.InsertLast(0);
  }
  return result;
}



bool are_coordinatesInRange(vec2 normCoordinates, array<vec2> limits){
for (uint i = 0; i < limits.Length; i++){
    if (!(normCoordinates[i] >= limits[i][0]) || !(normCoordinates[i] <= limits[i][1])){
        return false;
    }
}
return true;
}

string get_mapId() {
    if (GetApp().RootMap is null) {
        return "";
    }
    return GetApp().RootMap.IdName;
}


string ArrayToString(array<float> inputArray) {
    string outputString = " ";
    for (uint i = 0; i < inputArray.Length; i++) {
        outputString += inputArray[i] + " ";
    }
    return outputString;
}
string ArrayToString(array<int> inputArray) {
    string outputString = " ";
    for (uint i = 0; i < inputArray.Length; i++) {
        outputString += inputArray[i] + " ";
    }
    return outputString;
}
string ArrayToString(array<bool> inputArray) {
    string outputString = " ";
    for (uint i = 0; i < inputArray.Length; i++) {
        outputString += inputArray[i] + " ";
    }
    return outputString;
}