enum PlotType {
    absolute,
    relative,
    failPercentage
}

enum AllowedDifferenceToPB {
    absolute,
    relative,
}

enum PlotVisible {
    always,
    never,
    onlyWhenOpenplanetMenu
}


[Setting category="General" name="Max. number checkpoints" description="Maximum number of checkpoints the plugin will handle."]
uint setting_general_maxCheckpointNumberMap = 100;

[Setting category="General" name="Print information to log."]
bool setting_general_enableLogging = false;


[Setting category="Interface" name="Window visible" description="When the bar graph will be shown."]
PlotVisible setting_interface_plotVisible = PlotVisible::onlyWhenOpenplanetMenu;

[Setting category="Interface" name="Graph size" description="Size of the bar graph window."]
vec2 setting_interface_windowSize = vec2(400, 300);

[Setting category="Interface" name="Graph position" description="Position of the bar graph window. Click on the window and drag to resposition."]
vec2 setting_interface_windowPositon = vec2(100, 100);

[Setting category="Interface" name="Window draggable" description="Whether the window is draggable. True --> window is always draggable, False --> window is only draggable when Openplanet menu is visible."]
bool setting_interface_isWindowDraggable = true;

[Setting category="Interface" name="Plot type"]
PlotType setting_interface_plotType = PlotType::absolute;

[Setting category="Interface" name="Showing sum of all fails" description="Visualize fails as sum of all fails"]
bool setting_interface_showSumOfFails = false;

[Setting category="Interface" name="Showing reset fails" description="Showing resets or not. Note, that you can track them without visualizing them."]
bool setting_interface_showResetFail = true;

[Setting category="Interface" name="Showing respawn failse" description="Showing respawns or not. Note, that you can track them without visualizing them."]
bool setting_interface_showRespawnFail = true;

[Setting category="Interface" name="Showing slower than PB fails" description="Showing slower times than PB or not. Note, that you can track them without visualizing them. Fail description: Whether being slower than PB (how much is defined by the following options) counts as fail or not."]
bool setting_interface_showSlowerThanPBFail = true;

[Setting category="Interface" name="Showing legend" description="Activates the legend."]
bool setting_interface_showLegend = true;

[Setting category="Interface" name="Legend position" description="Relative legend position (horizontal and vertical position). Values from 0 to 1."]
vec2 setting_interface_legendPositionRel = vec2(-1, 0);




[Setting category="Fail Tracking" name="Tracking reset fails" description="Tracking resets or not. Note, that you can track them without visualizing them."]
bool setting_failTracking_trackResetFail = true;

[Setting category="Fail Tracking" name="Tracking respawn failse" description="Tracking respawns or not. Note, that you can track them without visualizing them."]
bool setting_failTracking_trackRespawnFail = true;

[Setting category="Fail Tracking" name="Tracking slower than PB fails" description="Tracking slower times than PB or not. Note, that you can track them without visualizing them. Fail description: Whether being slower than PB (how much is defined by the following options) counts as fail or not."]
bool setting_failTracking_trackSlowerThanPBFail = true;

[Setting category="Fail Tracking" name="How allowed time difference is set." description="absolute: absolute time difference in ms. relative: fraction of the time between checkpoints."]
AllowedDifferenceToPB setting_failTracking_allowedValueType = AllowedDifferenceToPB::absolute;

[Setting category="Fail Tracking" name="Absolute time difference value in ms." description="absolute time difference in ms."]
int setting_failTracking_allowedAbsoluteTimeDifference = 1000;

[Setting category="Fail Tracking" name="Relative time difference value." description="fraction of the time between checkpoints."]
float setting_failTracking_allowedRelativeTimeDifference = 0.1;

[Setting category="Fail Tracking" name="Enable multiple respawn fails on same checkpoint" description="If true, every respawn on a particular checkpoint raises fail counter by one. If false, every checkpoint can only raise fail counter by one in one try (until next reset)."]
bool setting_failTracking_isMultipleRespawnFailsSameCheckpointAllowed = false;

[Setting category="Fail Tracking" name="Count fail only when no previous fail was tracked." description="Only count fails when no fail has been previously tracked."]
bool setting_failTracking_onlyCountFailWhenNoFailWasTracked = false;

[Setting category="Fail Tracking" name="Count finish only when no previous fail was tracked." description="Only count finishes when no fail has been previously tracked."]
bool setting_failTracking_onlyCountFinishWhenNoFailWasTracked = false;

[Setting category="Fail Tracking" name="Skip fails at start location" description="Skip adding fails that happens at start location."]
bool setting_failTracking_skipFailWhenNearStart = true;

[Setting category="Fail Tracking" name="Skip fails at 0 velocity" description="Skip adding fails that happen when not moving for x seconds."]
bool setting_failTracking_skipFailWhenStandstill = true;

[Setting category="Fail Tracking" name="Duration at 0 velocity in ms" description="This is the threshold how long you have to stand still. If you create a fail after x seconds, it won't be counted."]
int setting_failTracking_skipFailWhenStandstillDuration = 2000;




[SettingsTab name="Data"]
void RenderSettingsFontTab() {
    RenderFailDataReset();
    RenderPersonalBestDataReset();
}

void RenderFailDataReset(){
    if (UI::Button("Reset fail data on this map.")){
        UI::ShowNotification("Cleared fail statistic for current map", 5000);
        FS::reset_data(true, false);
        IO::Delete(FS::folder + get_mapId() + ".json");
        FS::reset_variablesWhenResetting();
    }
}
void RenderPersonalBestDataReset(){
    if (UI::Button("Reset personal best data on this map.")){
        UI::ShowNotification("Cleared personal best data for current map", 5000);
        FS::reset_data(false, true);
        IO::Delete(FS::folder + get_mapId() + ".json");
        FS::reset_variablesWhenResetting();
    }
}
