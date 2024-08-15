void Main() {
}

void Update(float dt){
   //auto state = VehicleState::ViewingPlayerState();
   //print(state.Position);
   FS::Update();
   FS::initializing = false;
}

void Render(){
   FS::Render();
}

void OnSettingsChanged(){
   if (FS::inGame){
      if (FS::maxCP > setting_general_maxCheckpointNumberMap){
         FS::tooManyCheckpoints = true;
      }
      else {
         FS::tooManyCheckpoints = false;
      }
   }
   
}

void OnEnabled(){
   print("a");
}

