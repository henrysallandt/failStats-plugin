class CustomHistogram{
    array<FailStat> data = {};
    FailStat sum = FailStat();
    float finishesVis = 0;

    
    float get_maxData() const property { 
        if (includeFinish){
            return Math::Max(find_maxInArray(array<float>(sum)), finishesVis);
        }
        else {
            return find_maxInArray(array<float>(sum));
        }
    }
    uint get_length() property {
        uint result;
        if (data.Length != 0){
            result = data[0].length;
        } else {
            result = sum.length;
        }
        if (result == 0){
            return result;
        }
        if (includeFinish){
            return result + 1;
        }
        else{
            return result;
        }
    }
    uint get_nFailTypes() const property {return data.Length;}
    
    float get_textSize() const property {return nvg::TextBounds("a")[1];}

    float get_legendHeight() property { return nFailTypes * textSize + (nFailTypes-1) * distanceBetweenTextLines + 2*distanceTextToBackgroundBox;}

    vec2 legendSize = vec2(0,legendHeight);

    vec2 windowSize;

    vec4 backgroundColor = vec4(0,0,0,0.8);

    vec4 histogramColorFinish = vec4(0, 1, 0, 1);

    float get_barWidth() property { return 1.0f/(length); }

    vec2 legendPositionRel = vec2(-1, 0);

    vec2 get_legendPositionAbs() property { return vec2(windowPositon[0]+windowSize[0]*0.5-legendSize[0]*0.5 + legendPositionRel[0]*(windowSize[0] + legendSize[0])*0.5,
                                                        windowPositon[1]+windowSize[1]*0.5-legendSize[1]*0.5 + legendPositionRel[1]*(windowSize[1] + legendSize[1])*0.5);}

    bool get_includeFinish() const property { return  (setting_interface_plotType == PlotType::absolute || setting_interface_plotType == PlotType::relative);}

    vec2 windowPositon = vec2(0,0);

    int distanceTextToBackgroundBox = 10;
    int distanceBetweenTextLines = 6;

    CustomHistogram(){}

    void take_settingsInput(){
        windowSize = setting_interface_windowSize;
        windowPositon = setting_interface_windowPositon;
        legendPositionRel = setting_interface_legendPositionRel;
    }

    void render(){
        handle_windowReposition();
        render_backgroud();
        if (length == 0){
            return;
        }
        render_histogram();
        render_mouseHover();
        handle_legendReposition();
        render_legend();
    }

    void render_histogram(){
        if (maxData == 0){
            return;
        }
        float transformedValuePrevious = 0;
        float transformedValue;
        vec4 color;
        bool breakOut = false;

        if (setting_interface_showSumOfFails){
            data = {sum};
        }

        for (uint cp = 0; cp < length; cp++){
            for (uint failType = 0; failType < nFailTypes; failType++){
                
                if (cp == data[0].length && includeFinish){
                    color = histogramColorFinish;
                    transformedValue = finishesVis/maxData;
                    breakOut = true;
                } else {
                    color = data[failType].color;
                    transformedValue = data[failType][cp]/maxData;
                }
                if (transformedValue == 0){
                    continue;
                }
                nvg::BeginPath();
                nvg::RoundedRect(
                    get_pixelFromNorm(cp*barWidth, true, "x"),
                    get_pixelFromNorm((1-(transformedValue+transformedValuePrevious)), true, "y"),
                    get_pixelFromNorm(barWidth, false, "x"),
                    get_pixelFromNorm((transformedValue), false, "y"),
                    0);
                
                
                nvg::FillColor(color);
                nvg::Fill();
                nvg::ClosePath();
                transformedValuePrevious += transformedValue;
                if (breakOut) {
                    breakOut = false;
                    break;
                }
            }
            transformedValuePrevious = 0;
            
        }

    }

    void render_backgroud(){
        nvg::BeginPath();
        nvg::RoundedRect(
            windowPositon[0],
            windowPositon[1],
            windowSize[0],
            windowSize[1],
            0);
        nvg::FillColor(backgroundColor);
        nvg::Fill();

        //nvg::StrokeColor(BorderColor);
        //nvg::StrokeWidth(BorderWidth);
        //nvg::Stroke();
        nvg::ClosePath();

    }
    
    void render_mouseHover(){
        vec2 mousePositionAbs = UI::GetMousePos();
        vec2 mousePositionNorm = get_mousePositionNorm(mousePositionAbs, windowPositon, windowSize);
        

        if (are_coordinatesInRange(mousePositionNorm, {vec2(0, 1), vec2(0, 1)})){
            uint checkpointNumber = uint(Math::Min(Math::Floor(mousePositionNorm[0]/barWidth), length-1));
            uint checkpointNumberAfter = checkpointNumber + 1;
            vec2 textPositionAbs = mousePositionAbs + vec2(40,0);
        
            string firstText;
            string secondText;
            if (checkpointNumber == 0){
                firstText = "start";
            } else{
                firstText = "checkpoint " + checkpointNumber;
            }
            if ((checkpointNumberAfter == length-1 && includeFinish) || (checkpointNumberAfter == length-1 && !includeFinish)){
                secondText = "finish";
            } else{
                secondText = "checkpoint " + checkpointNumberAfter;
            }

            float multiplicator = 0;
            string plotTypeText = "";
            string formatNumber = "";
            switch (setting_interface_plotType){
                case PlotType::absolute:
                    multiplicator = 1;   plotTypeText = "";  formatNumber = "%g"; break;
                case PlotType::relative:
                    multiplicator = 100; plotTypeText = "%"; formatNumber = "%.1f" ;break;
                case PlotType::failPercentage:
                    multiplicator = 100; plotTypeText = "% of attempts reaching previous checkpoint"; formatNumber = "%.1f" ;break;
            }

            string text;
            float dataNumber;
            array<float> dataNumbers = {};
            if (checkpointNumber == length-1 && includeFinish){
                dataNumber = finishesVis * multiplicator;
                text = Text::Format(formatNumber, dataNumber) + plotTypeText + " finishes.";
            } else{
                string failTexts;
                if (!setting_interface_showSumOfFails){
                    failTexts = "(";
                    for (uint iFailType=0; iFailType<nFailTypes; iFailType++){
                        dataNumbers.InsertLast(data[iFailType][checkpointNumber] * multiplicator);
                        failTexts += data[iFailType]._name + ": " + Text::Format(formatNumber, dataNumbers[dataNumbers.Length-1]);
                        if (iFailType != nFailTypes-1){
                            failTexts += ", ";
                        }
                    }
                    failTexts += ") ";
                }
                else {
                    failTexts = "";
                }
                dataNumber = sum[checkpointNumber] * multiplicator;
                text = Text::Format(formatNumber, dataNumber) + " " + failTexts + plotTypeText + " fail/s between " + firstText + " and " + secondText;
            }


            // draw it
            vec2 textSize = nvg::TextBounds(text);

            nvg::BeginPath();
            nvg::RoundedRect(textPositionAbs, textSize+distanceTextToBackgroundBox*2, 0);
            nvg::FillColor(vec4(0,0,0,0.9));
            nvg::Fill();
            nvg::ClosePath();

            textPositionAbs.y += textSize.y;
            textPositionAbs += vec2(distanceTextToBackgroundBox);
            
            nvg::BeginPath();
            nvg::FillColor(vec4(.9, .9, .9, 1));
            nvg::Text(textPositionAbs, text);
            nvg::Stroke();
            nvg::ClosePath();
        }
    }

    bool followMouseWindow = false;
    vec2 offsetFromWindow = vec2(0,0);
    void handle_windowReposition(){
        if (setting_interface_isWindowDraggable || (!setting_interface_isWindowDraggable && UI::IsOverlayShown())){
            if (!UI::IsMouseClicked() && !UI::IsMouseDown() && !followMouseWindow){
                return;
            }

            if (UI::IsMouseClicked()){
                vec2 mouseClickPositionNorm = get_mousePositionNorm(UI::GetMousePos(), windowPositon, windowSize);
                bool clickedInWindow = are_coordinatesInRange(mouseClickPositionNorm, {vec2(0, 1), vec2(0,1)});
                if (!clickedInWindow){
                    return;
                }   
                offsetFromWindow = UI::GetMousePos() - windowPositon;
                followMouseWindow = true;
            }
            if (followMouseWindow && UI::IsMouseDown()){
                windowPositon = UI::GetMousePos() - offsetFromWindow;
                setting_interface_windowPositon = windowPositon;
                return;
            }
            // mouse was released
            followMouseWindow = false;
        }
    }

    vec2 offsetFromLegend;
    bool followMouseLegend = false;
    void handle_legendReposition(){
        if (setting_interface_isWindowDraggable || (!setting_interface_isWindowDraggable && UI::IsOverlayShown())){
            if (!UI::IsMouseClicked() && !UI::IsMouseDown() && !followMouseLegend){
                return;
            }
            
            if (UI::IsMouseClicked()){
                vec2 mouseClickPositionNorm = get_mousePositionNorm(UI::GetMousePos(), legendPositionAbs, legendSize);
                bool clickedInLegend = are_coordinatesInRange(mouseClickPositionNorm, {vec2(0, 1), vec2(0,1)});
                if (!clickedInLegend){
                    return;
                }   
                offsetFromLegend = UI::GetMousePos() - legendPositionAbs;
                followMouseLegend = true;
            }
            if (followMouseLegend && UI::IsMouseDown()){
                // follow mouse in y direction in limits so it stays next to the bar chart
                vec2 mouseClickPositionNorm = get_mousePositionNorm(UI::GetMousePos() - offsetFromLegend, windowPositon-legendSize, windowSize+legendSize);
                mouseClickPositionNorm = (mouseClickPositionNorm + vec2(-0.5, -0.5)) * 2;
                
                // limit both x and y values to -1 to 1
                legendPositionRel = vec2(Math::Min(Math::Max(mouseClickPositionNorm[0], -1), 1) ,
                                         Math::Min(Math::Max(mouseClickPositionNorm[1], -1), 1));
                
                // check which coordinate needs to be fixed to -1 or 1
                float legendPositionSum = legendPositionRel[0] + legendPositionRel[1];
                float legendPositionDif = legendPositionRel[0] - legendPositionRel[1];
                if ((legendPositionSum >= 0 && legendPositionDif >= 0) || (legendPositionSum <= 0 && legendPositionDif <= 0)){
                    // set x coords to -1 or 1
                    legendPositionRel = vec2(Math::Round((legendPositionRel[0]+1)/2) * 2 - 1 ,
                                             legendPositionRel[1]);
                } else {
                    // set y coords to -1 or 1
                    legendPositionRel = vec2(legendPositionRel[0],
                                             Math::Round((legendPositionRel[1]+1)/2) * 2 - 1);
                }
                setting_interface_legendPositionRel = legendPositionRel;
                return;
            }
            followMouseLegend = false;
        }
    }

    float distanceColorBoxToText = 5;
    void render_legend(){
        if (setting_interface_showSumOfFails || !setting_interface_showLegend){
            return;
        }
        
        string text;
        array<string> texts = {};
        float maxTextLength = 0;
        // loop through types and create texts
        for (uint iType=0; iType<nFailTypes; iType++){
            text = data[iType]._name;
            texts.InsertLast(text);
            maxTextLength = Math::Max(nvg::TextBounds(text)[0], maxTextLength);
        }

        // get legend size from text sizes - add small boxes for colors
        legendSize = vec2(maxTextLength + 2*distanceTextToBackgroundBox + textSize + distanceColorBoxToText, 
                          legendHeight);
        nvg::BeginPath();
        nvg::RoundedRect(
            legendPositionAbs[0],
            legendPositionAbs[1],
            legendSize[0],
            legendSize[1],
            0);
        nvg::FillColor(backgroundColor);
        nvg::Fill();

        // draw texts and color boxes
        for (uint iType=0; iType<nFailTypes; iType++){
            nvg::BeginPath();
            nvg::RoundedRect(
                legendPositionAbs[0] + distanceTextToBackgroundBox,
                legendPositionAbs[1] + distanceTextToBackgroundBox + iType*(textSize+distanceBetweenTextLines),
                textSize,
                textSize,
                0);
            nvg::FillColor(data[iType].color);
            nvg::Fill();

            
            nvg::BeginPath();
            nvg::FillColor(vec4(.9, .9, .9, 1));
            nvg::Text(vec2(
                legendPositionAbs[0] + distanceTextToBackgroundBox + textSize + distanceColorBoxToText,
                legendPositionAbs[1] + distanceTextToBackgroundBox + iType*(textSize+distanceBetweenTextLines) + 0.8*textSize
            ), texts[iType]);
            nvg::Stroke();
            nvg::ClosePath();
        }
    }

    // helpers
    float get_pixelFromNorm(float norm, bool abs, const string direction){
        float height;
        float offset;
        if (direction == "x"){
            height = windowSize[0];
            offset = windowPositon[0];
        }
        else if (direction == "y"){
            height = windowSize[1];
            offset = windowPositon[1];
        }
        else {
            print('Invalid direction.');
            return -1;
        }
        
        float value = norm * height;
        if (abs){
            return value + offset;
        }
        else{
            return value;
        }
    }

    float get_normFromPixel(float pixel, const string direction, vec2 leftUpper, vec2 size){
        float height;
        float offset;
        if (direction == "x"){
            height = size[0];
            offset = leftUpper[0];
        }
        else if (direction == "y"){
            height = size[1];
            offset = leftUpper[1];
        }
        else {
            print('Invalid direction.');
            return -1;
        }
        return Math::InvLerp(offset, offset+height, pixel);
    }

    vec2 get_mousePositionNorm(vec2 mousePositionAbs, vec2 leftUpper, vec2 size){
        return vec2(get_normFromPixel(mousePositionAbs[0], "x", leftUpper, size), 
                    get_normFromPixel(mousePositionAbs[1], "y", leftUpper, size));
    }
}
